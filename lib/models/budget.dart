import '../utils/firestore_codec.dart';

/// Spending state for a budget or category limit (Section 6).
enum BudgetStatus { normal, warning, exceeded }

/// Below 80% = normal, 80% to 99% = warning, 100% or higher = exceeded.
BudgetStatus budgetStatusFor(double percentUsed) {
  if (percentUsed >= 100) return BudgetStatus.exceeded;
  if (percentUsed >= 80) return BudgetStatus.warning;
  return BudgetStatus.normal;
}

extension BudgetStatusLabel on BudgetStatus {
  String get label => switch (this) {
        BudgetStatus.normal => 'Within range',
        BudgetStatus.warning => 'Approaching limit',
        BudgetStatus.exceeded => 'Limit exceeded',
      };
}

/// Monthly budget, stored per month using a key like "2026-10".
class Budget {
  final String monthKey;
  final double amount;

  const Budget({required this.monthKey, required this.amount});

  factory Budget.fromMap(String monthKey, Map<String, dynamic> map) =>
      Budget(monthKey: monthKey, amount: readDouble(map['amount']));

  Map<String, dynamic> toMap() => {'amount': amount};
}

/// Spending limit for one category, together with how much was spent.
class CategoryBudget {
  final String category;
  final double limit;
  final double spent;

  const CategoryBudget({
    required this.category,
    required this.limit,
    required this.spent,
  });

  bool get hasLimit => limit > 0;

  /// Percentage Used = Category Expenses / Category Budget x 100
  double get percentUsed => hasLimit ? spent / limit * 100 : 0;

  double get remaining => limit - spent;

  BudgetStatus get status => budgetStatusFor(percentUsed);
}
