import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/expense_filter.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Shortcut used by screens and widgets.
final DatabaseService db = DatabaseService.instance;

/// Holds all app data, saves it to Cloud Firestore, and does the
/// financial calculations.
///
/// How it works:
/// - Firestore keeps a copy of the data on the phone (offline persistence),
///   so the app still works without internet and keeps data after a restart.
/// - Live listeners copy each collection into the lists below, so every
///   screen reads from memory and redraws when data changes.
/// - Every write updates the lists right away (so the screen changes
///   instantly), then saves to Firestore. Offline, Firestore queues the write
///   and uploads it once the phone is back online.
///
/// Firestore layout:
///   incomes/{id}          source, amount, date, description
///   expenses/{id}         title, amount, category, date, paymentMethod, description, recurringId
///   recurring/{id}        name, amount, category, paymentMethod, frequency, nextDate
///   budgets/{2026-10}     amount
///   savings/{2026-10}     target, current
///   categoryLimits/{Food} limit
///   settings/app          themeMode, seeded
class DatabaseService extends ChangeNotifier {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  late final FirebaseFirestore _fs;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final List<Income> _incomes = [];
  final List<Expense> _expenses = [];
  final Map<String, double> _budgets = {}; // "2026-10" -> 25000
  final Map<String, double> _categoryLimits = {}; // "Food" -> 3000
  final Map<String, SavingsGoal> _savings = {}; // "2026-10" -> goal
  final List<RecurringExpense> _recurring = [];

  DateTime _selectedMonth = monthOf(DateTime.now());
  ThemeMode _themeMode = ThemeMode.system;

  /// Goes up whenever data is reset, so forms know to reload their fields.
  int revision = 0;

  /// Message shown at the top of the app when Firebase refuses a change.
  String? syncError;

  CollectionReference<Map<String, dynamic>> get _incomesRef => _fs.collection('incomes');
  CollectionReference<Map<String, dynamic>> get _expensesRef => _fs.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _recurringRef => _fs.collection('recurring');
  CollectionReference<Map<String, dynamic>> get _budgetsRef => _fs.collection('budgets');
  CollectionReference<Map<String, dynamic>> get _savingsRef => _fs.collection('savings');
  CollectionReference<Map<String, dynamic>> get _limitsRef => _fs.collection('categoryLimits');
  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _fs.collection('settings').doc('app');

  /// Firestore makes the id on the phone, so this works offline too.
  String newId() => _fs.collection('incomes').doc().id;

  // ---------------------------------------------------------------------------
  // Startup
  // ---------------------------------------------------------------------------

  /// Called once in main() after Firebase.initializeApp().
  Future<void> init() async {
    _fs = FirebaseFirestore.instance;

    // Keep a full copy on the phone so the app works offline (Section 13).
    _fs.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // First launch ever: upload the sample data once.
    try {
      // Don't let a slow or missing connection keep the app stuck on a
      // blank screen. After 5 seconds, carry on with what's on the phone.
      final settings = await _settingsRef.get().timeout(const Duration(seconds: 5));
      if (!settings.exists) {
        _uploadSample(replaceExisting: false);
      } else {
        _themeMode = _parseTheme(settings.data()?['themeMode']);
      }
    } catch (e) {
      // Offline on the very first launch. Start empty; nothing to load yet.
      debugPrint('Settings check skipped: $e');
    }

    await _startListening();
  }

  /// Copies each Firestore collection into memory and keeps it updated.
  /// Waits for the first result of each, so screens don't flash empty.
  Future<void> _startListening() async {
    final firstLoads = <Future<void>>[];

    void watch<T>(
      Stream<T> stream,
      void Function(T snapshot) apply,
    ) {
      final first = Completer<void>();
      firstLoads.add(first.future);
      _subscriptions.add(stream.listen(
        (snapshot) {
          apply(snapshot);
          notifyListeners();
          if (!first.isCompleted) first.complete();
        },
        onError: (Object e) {
          _reportError(e);
          if (!first.isCompleted) first.complete();
        },
      ));
    }

    watch(_incomesRef.snapshots(), (s) {
      _incomes
        ..clear()
        ..addAll(s.docs.map((d) => Income.fromMap(d.id, d.data())));
    });
    watch(_expensesRef.snapshots(), (s) {
      _expenses
        ..clear()
        ..addAll(s.docs.map((d) => Expense.fromMap(d.id, d.data())));
    });
    watch(_recurringRef.snapshots(), (s) {
      _recurring
        ..clear()
        ..addAll(s.docs.map((d) => RecurringExpense.fromMap(d.id, d.data())));
    });
    watch(_budgetsRef.snapshots(), (s) {
      _budgets
        ..clear()
        ..addAll({for (final d in s.docs) d.id: Budget.fromMap(d.id, d.data()).amount});
    });
    watch(_savingsRef.snapshots(), (s) {
      _savings
        ..clear()
        ..addAll({for (final d in s.docs) d.id: SavingsGoal.fromMap(d.id, d.data())});
    });
    watch(_limitsRef.snapshots(), (s) {
      _categoryLimits
        ..clear()
        ..addAll({
          for (final d in s.docs)
            if (d.data()['limit'] is num) d.id: (d.data()['limit'] as num).toDouble(),
        });
    });
    watch(_settingsRef.snapshots(), (s) {
      if (s.exists) _themeMode = _parseTheme(s.data()?['themeMode']);
    });

    await Future.wait(firstLoads).timeout(const Duration(seconds: 6), onTimeout: () => []);
  }

  /// Saves in the background. Offline, Firestore queues it, so we never
  /// wait for the server here, otherwise the app would freeze offline.
  void _save(Future<void> write) {
    unawaited(write.then((_) {
      if (syncError != null) {
        syncError = null;
        notifyListeners();
      }
    }, onError: _reportError));
  }

  void _reportError(Object error) {
    debugPrint('Firestore error: $error');
    syncError = error is FirebaseException && error.code == 'permission-denied'
        ? 'Firebase refused the change. Check that your Firestore rules allow reads and writes (test mode lasts 30 days).'
        : 'Could not sync with Firebase. Your changes are kept on this phone.';
    notifyListeners();
  }

  void dismissSyncError() {
    syncError = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // App state
  // ---------------------------------------------------------------------------

  DateTime get selectedMonth => _selectedMonth;
  ThemeMode get themeMode => _themeMode;

  void changeMonth(int delta) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _save(_settingsRef.set({'themeMode': mode.name}, SetOptions(merge: true)));
  }

  ThemeMode _parseTheme(Object? value) => ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.system,
      );

  // ---------------------------------------------------------------------------
  // Income CRUD
  // ---------------------------------------------------------------------------

  List<Income> get allIncomes =>
      List.of(_incomes)..sort((a, b) => b.date.compareTo(a.date));

  List<Income> incomesFor(DateTime month) =>
      allIncomes.where((i) => sameMonth(i.date, month)).toList();

  void addIncome(Income income) {
    _incomes.add(income);
    notifyListeners();
    _save(_incomesRef.doc(income.id).set(income.toMap()));
  }

  void updateIncome(Income income) {
    final index = _incomes.indexWhere((i) => i.id == income.id);
    if (index == -1) return;
    _incomes[index] = income;
    notifyListeners();
    _save(_incomesRef.doc(income.id).set(income.toMap()));
  }

  void deleteIncome(String id) {
    _incomes.removeWhere((i) => i.id == id);
    notifyListeners();
    _save(_incomesRef.doc(id).delete());
  }

  // ---------------------------------------------------------------------------
  // Expense CRUD
  // ---------------------------------------------------------------------------

  List<Expense> get allExpenses =>
      List.of(_expenses)..sort((a, b) => b.date.compareTo(a.date));

  List<Expense> expensesFor(DateTime month) =>
      allExpenses.where((e) => sameMonth(e.date, month)).toList();

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
    _save(_expensesRef.doc(expense.id).set(expense.toMap()));
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    notifyListeners();
    _save(_expensesRef.doc(expense.id).set(expense.toMap()));
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
    _save(_expensesRef.doc(id).delete());
  }

  /// Search and filtering (Section 9).
  List<Expense> filterExpenses(ExpenseFilter filter, DateTime month) =>
      allExpenses.where((e) => filter.matches(e, month)).toList();

  // ---------------------------------------------------------------------------
  // Monthly budget
  // ---------------------------------------------------------------------------

  double budgetFor(DateTime month) => _budgets[monthKey(month)] ?? 0;

  void setBudget(DateTime month, double amount) {
    final key = monthKey(month);
    _budgets[key] = amount;
    notifyListeners();
    _save(_budgetsRef.doc(key).set(Budget(monthKey: key, amount: amount).toMap()));
  }

  // ---------------------------------------------------------------------------
  // Category limits
  // ---------------------------------------------------------------------------

  double limitFor(String category) => _categoryLimits[category] ?? 0;

  void setCategoryLimit(String category, double limit) {
    _categoryLimits[category] = limit;
    notifyListeners();
    _save(_limitsRef.doc(category).set({'limit': limit}));
  }

  void removeCategoryLimit(String category) {
    _categoryLimits.remove(category);
    notifyListeners();
    _save(_limitsRef.doc(category).delete());
  }

  List<CategoryBudget> categoryBudgets(DateTime month) {
    final totals = categoryTotals(month);
    return [
      for (final c in expenseCategories)
        CategoryBudget(category: c, limit: limitFor(c), spent: totals[c] ?? 0),
    ];
  }

  CategoryBudget categoryBudget(String category, DateTime month) =>
      categoryBudgets(month).firstWhere((c) => c.category == category);

  // ---------------------------------------------------------------------------
  // Savings goal
  // ---------------------------------------------------------------------------

  SavingsGoal savingsFor(DateTime month) =>
      _savings[monthKey(month)] ??
      SavingsGoal(monthKey: monthKey(month), target: 0, current: 0);

  void setSavings(DateTime month, double target, double current) {
    final key = monthKey(month);
    final goal = SavingsGoal(monthKey: key, target: target, current: current);
    _savings[key] = goal;
    notifyListeners();
    _save(_savingsRef.doc(key).set(goal.toMap()));
  }

  // ---------------------------------------------------------------------------
  // Recurring expenses
  // ---------------------------------------------------------------------------

  List<RecurringExpense> get recurringExpenses =>
      List.of(_recurring)..sort((a, b) => a.nextDate.compareTo(b.nextDate));

  RecurringExpense? recurringById(String id) {
    for (final r in _recurring) {
      if (r.id == id) return r;
    }
    return null;
  }

  void addRecurring(RecurringExpense item) {
    _recurring.add(item);
    notifyListeners();
    _save(_recurringRef.doc(item.id).set(item.toMap()));
  }

  void updateRecurring(RecurringExpense item) {
    final index = _recurring.indexWhere((r) => r.id == item.id);
    if (index == -1) return;
    _recurring[index] = item;
    notifyListeners();
    _save(_recurringRef.doc(item.id).set(item.toMap()));
  }

  void deleteRecurring(String id) {
    _recurring.removeWhere((r) => r.id == id);
    notifyListeners();
    _save(_recurringRef.doc(id).delete());
  }

  /// Records the payment as an expense and moves the due date forward.
  /// Both changes are saved together in one batch.
  Expense markRecurringPaid(String id) {
    final index = _recurring.indexWhere((r) => r.id == id);
    final item = _recurring[index];
    final expense = Expense(
      id: newId(),
      title: item.name,
      amount: item.amount,
      category: item.category,
      date: item.nextDate,
      paymentMethod: item.paymentMethod,
      description: '${item.frequency} recurring payment',
      recurringId: item.id,
    );
    final updated = item.copyWith(nextDate: item.followingDate);

    _expenses.add(expense);
    _recurring[index] = updated;
    notifyListeners();

    final batch = _fs.batch()
      ..set(_expensesRef.doc(expense.id), expense.toMap())
      ..set(_recurringRef.doc(updated.id), updated.toMap());
    _save(batch.commit());
    return expense;
  }

  // ---------------------------------------------------------------------------
  // Calculations (Sections 1, 5, 6, 7, 8, 19)
  // ---------------------------------------------------------------------------

  double totalIncome(DateTime month) =>
      incomesFor(month).fold<double>(0, (total, i) => total + i.amount);

  double totalExpenses(DateTime month) =>
      expensesFor(month).fold<double>(0, (total, e) => total + e.amount);

  /// Remaining Budget = Monthly Budget - Total Expenses
  double remainingBudget(DateTime month) =>
      budgetFor(month) - totalExpenses(month);

  /// Budget Used = Total Expenses / Monthly Budget x 100
  double budgetUsedPercent(DateTime month) {
    final budget = budgetFor(month);
    return budget > 0 ? totalExpenses(month) / budget * 100 : 0;
  }

  /// Remaining Balance = Total Income - Total Expenses
  double remainingBalance(DateTime month) =>
      totalIncome(month) - totalExpenses(month);

  Map<String, double> categoryTotals(DateTime month) {
    final totals = {for (final c in expenseCategories) c: 0.0};
    for (final e in expensesFor(month)) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  MapEntry<String, double>? highestCategory(DateTime month) {
    final entries = categoryTotals(month).entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.isEmpty ? null : entries.first;
  }

  /// Days so far for the current month, full month for past/future months.
  int daysCounted(DateTime month) {
    final now = DateTime.now();
    return sameMonth(now, month) ? now.day : daysInMonth(month);
  }

  /// Average Daily Spending = Total Expenses / Days
  double averageDailySpending(DateTime month) =>
      totalExpenses(month) / daysCounted(month);

  /// Savings Rate = Savings / Total Income x 100
  double savingsRate(DateTime month) {
    final income = totalIncome(month);
    return income > 0 ? savingsFor(month).current / income * 100 : 0;
  }

  /// Monthly comparison: positive means spending went up.
  double expenseDifference(DateTime month) {
    final previous = DateTime(month.year, month.month - 1);
    return totalExpenses(month) - totalExpenses(previous);
  }

  // ---------------------------------------------------------------------------
  // Sample data / reset
  // ---------------------------------------------------------------------------

  /// The sample records are in October 2026, so jump there after reloading.
  /// Otherwise the user could be looking at an empty month and think
  /// nothing was restored.
  static final DateTime sampleMonth = DateTime(2026, 10);

  /// Replaces everything with the September and October 2026 sample records.
  void loadSampleData() {
    _uploadSample(replaceExisting: true);
    _selectedMonth = sampleMonth;
    revision++;
    notifyListeners();
  }

  /// Deletes every record. Settings (theme) are kept.
  void clearAll() {
    final ops = _deleteEverythingOps();
    _incomes.clear();
    _expenses.clear();
    _budgets.clear();
    _categoryLimits.clear();
    _savings.clear();
    _recurring.clear();
    revision++;
    notifyListeners();
    _commit(ops);
  }

  void _uploadSample({required bool replaceExisting}) {
    final data = _buildSample();
    final ops = <void Function(WriteBatch)>[
      if (replaceExisting) ..._deleteEverythingOps(),
      for (final i in data.incomes) (b) => b.set(_incomesRef.doc(i.id), i.toMap()),
      for (final e in data.expenses) (b) => b.set(_expensesRef.doc(e.id), e.toMap()),
      for (final r in data.recurring) (b) => b.set(_recurringRef.doc(r.id), r.toMap()),
      for (final entry in data.budgets.entries)
        (b) => b.set(_budgetsRef.doc(entry.key), {'amount': entry.value}),
      for (final entry in data.savings.entries)
        (b) => b.set(_savingsRef.doc(entry.key), entry.value.toMap()),
      for (final entry in data.limits.entries)
        (b) => b.set(_limitsRef.doc(entry.key), {'limit': entry.value}),
      // Marks the sample as uploaded so it isn't added again on next launch.
      (b) => b.set(_settingsRef, {'seeded': true}, SetOptions(merge: true)),
    ];

    // Show the sample on screen right away.
    _incomes
      ..clear()
      ..addAll(data.incomes);
    _expenses
      ..clear()
      ..addAll(data.expenses);
    _recurring
      ..clear()
      ..addAll(data.recurring);
    _budgets
      ..clear()
      ..addAll(data.budgets);
    _savings
      ..clear()
      ..addAll(data.savings);
    _categoryLimits
      ..clear()
      ..addAll(data.limits);
    notifyListeners();

    _commit(ops);
  }

  /// Delete operations for every document currently loaded.
  List<void Function(WriteBatch)> _deleteEverythingOps() => [
        for (final i in _incomes) (b) => b.delete(_incomesRef.doc(i.id)),
        for (final e in _expenses) (b) => b.delete(_expensesRef.doc(e.id)),
        for (final r in _recurring) (b) => b.delete(_recurringRef.doc(r.id)),
        for (final k in _budgets.keys) (b) => b.delete(_budgetsRef.doc(k)),
        for (final k in _savings.keys) (b) => b.delete(_savingsRef.doc(k)),
        for (final k in _categoryLimits.keys) (b) => b.delete(_limitsRef.doc(k)),
      ];

  /// Firestore allows 500 changes per batch, so split big jobs.
  void _commit(List<void Function(WriteBatch)> ops) {
    const perBatch = 450;
    for (var start = 0; start < ops.length; start += perBatch) {
      final batch = _fs.batch();
      for (final op in ops.skip(start).take(perBatch)) {
        op(batch);
      }
      _save(batch.commit());
    }
  }

  _SampleData _buildSample() {
    final incomes = [
        Income(id: newId(), source: 'Salary', amount: 20000, date: DateTime(2026, 10, 1), description: 'Part-time pay'),
        Income(id: newId(), source: 'Allowance', amount: 5000, date: DateTime(2026, 10, 2), description: 'Monthly allowance'),
        Income(id: newId(), source: 'Salary', amount: 20000, date: DateTime(2026, 9, 1), description: 'Part-time pay'),
        Income(id: newId(), source: 'Allowance', amount: 4000, date: DateTime(2026, 9, 2), description: 'Monthly allowance'),
    ];

    Expense e(String title, double amount, String category, DateTime date,
            String payment,
            [String description = '', String? recurringId]) =>
        Expense(
          id: newId(),
          title: title,
          amount: amount,
          category: category,
          date: date,
          paymentMethod: payment,
          description: description,
          recurringId: recurringId,
        );

    final expenses = [
        // October 2026, total ₱17,450
        e('Rent', 6000, 'Bills', DateTime(2026, 10, 5), 'Bank Transfer', 'Boarding house', 'r-rent'),
        e('Internet', 1699, 'Bills', DateTime(2026, 10, 1), 'GCash', 'Fiber plan', 'r-internet'),
        e('Electricity', 1301, 'Bills', DateTime(2026, 10, 3), 'GCash', 'Davao Light bill'),
        e('Groceries', 1650, 'Food', DateTime(2026, 10, 4), 'Cash', 'Weekly groceries'),
        e('Lunch with classmates', 850, 'Food', DateTime(2026, 10, 6), 'GCash'),
        e('Jeepney and taxi fare', 1200, 'Transportation', DateTime(2026, 10, 6), 'Cash', 'School commute'),
        e('Movie night', 850, 'Entertainment', DateTime(2026, 10, 3), 'GCash'),
        e('Clinical shoes', 2400, 'Shopping', DateTime(2026, 10, 2), 'Debit Card', 'For duty'),
        e('Review books', 1000, 'Education', DateTime(2026, 10, 5), 'Cash', 'Pharmacology reviewer'),
        e('Vitamins', 500, 'Health', DateTime(2026, 10, 4), 'Cash'),
        // September 2026, total ₱15,200
        e('Rent', 6000, 'Bills', DateTime(2026, 9, 5), 'Bank Transfer', '', 'r-rent'),
        e('Internet', 1699, 'Bills', DateTime(2026, 9, 1), 'GCash', '', 'r-internet'),
        e('Electricity', 1351, 'Bills', DateTime(2026, 9, 3), 'GCash'),
        e('Groceries', 2800, 'Food', DateTime(2026, 9, 10), 'Cash'),
        e('Commute', 1100, 'Transportation', DateTime(2026, 9, 12), 'Cash'),
        e('School supplies', 1200, 'Shopping', DateTime(2026, 9, 8), 'Debit Card'),
        e('Concert ticket', 650, 'Entertainment', DateTime(2026, 9, 20), 'GCash'),
        e('Check-up', 400, 'Health', DateTime(2026, 9, 15), 'Cash'),
    ];

    const budgets = {'2026-10': 25000.0, '2026-09': 25000.0};

    const savings = {
        '2026-10': SavingsGoal(monthKey: '2026-10', target: 5000, current: 3500),
        '2026-09': SavingsGoal(monthKey: '2026-09', target: 5000, current: 4000),
    };

    const limits = {
        'Food': 3000.0,
        'Transportation': 2000.0,
        'Bills': 9500.0,
        'Education': 1500.0,
        'Shopping': 2000.0,
        'Entertainment': 1000.0,
        'Health': 1000.0,
        'Others': 1000.0,
    };

    final recurring = [
        RecurringExpense(id: 'r-internet', name: 'Internet', amount: 1699, category: 'Bills', paymentMethod: 'GCash', frequency: 'Monthly', nextDate: DateTime(2026, 11, 1)),
        RecurringExpense(id: 'r-rent', name: 'Rent', amount: 6000, category: 'Bills', paymentMethod: 'Bank Transfer', frequency: 'Monthly', nextDate: DateTime(2026, 11, 5)),
        RecurringExpense(id: 'r-spotify', name: 'Spotify', amount: 149, category: 'Entertainment', paymentMethod: 'Debit Card', frequency: 'Monthly', nextDate: DateTime(2026, 10, 18)),
        RecurringExpense(id: 'r-phone', name: 'Phone plan', amount: 599, category: 'Bills', paymentMethod: 'GCash', frequency: 'Monthly', nextDate: DateTime(2026, 10, 25)),
      ];

    return _SampleData(incomes, expenses, budgets, savings, limits, recurring);
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}

class _SampleData {
  const _SampleData(
    this.incomes,
    this.expenses,
    this.budgets,
    this.savings,
    this.limits,
    this.recurring,
  );

  final List<Income> incomes;
  final List<Expense> expenses;
  final Map<String, double> budgets;
  final Map<String, SavingsGoal> savings;
  final Map<String, double> limits;
  final List<RecurringExpense> recurring;
}