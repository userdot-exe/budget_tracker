// Unit tests for the required formulas. These don't need Firebase,
// so they run with plain `flutter test`.
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_tracker/models/budget.dart';
import 'package:budget_tracker/models/recurring_expense.dart';
import 'package:budget_tracker/models/savings_goal.dart';

void main() {
  group('Category budget (Section 6)', () {
    test('Percentage Used = spent / limit x 100', () {
      const food = CategoryBudget(category: 'Food', limit: 3000, spent: 2500);
      expect(food.percentUsed, closeTo(83.33, 0.01));
    });

    test('below 80% is normal, 80-99% is warning, 100%+ is exceeded', () {
      expect(budgetStatusFor(79.9), BudgetStatus.normal);
      expect(budgetStatusFor(80), BudgetStatus.warning);
      expect(budgetStatusFor(99.9), BudgetStatus.warning);
      expect(budgetStatusFor(100), BudgetStatus.exceeded);
      expect(budgetStatusFor(120), BudgetStatus.exceeded);
    });

    test('Shopping sample is over its limit by 400', () {
      const shopping = CategoryBudget(category: 'Shopping', limit: 2000, spent: 2400);
      expect(shopping.status, BudgetStatus.exceeded);
      expect(shopping.remaining, -400);
    });
  });

  group('Savings goal (Section 7)', () {
    test('Savings Progress = current / target x 100', () {
      const goal = SavingsGoal(monthKey: '2026-10', target: 5000, current: 3500);
      expect(goal.progress, 70);
      expect(goal.isReached, isFalse);
    });

    test('no target means 0% instead of dividing by zero', () {
      const goal = SavingsGoal(monthKey: '2026-10', target: 0, current: 100);
      expect(goal.progress, 0);
    });
  });

  group('Recurring expenses (Section 11)', () {
    RecurringExpense bill(String frequency, DateTime next) => RecurringExpense(
          id: 'x',
          name: 'Internet',
          amount: 1699,
          category: 'Bills',
          paymentMethod: 'GCash',
          frequency: frequency,
          nextDate: next,
        );

    test('monthly moves one month ahead', () {
      expect(bill('Monthly', DateTime(2026, 11, 1)).followingDate, DateTime(2026, 12, 1));
    });

    test('Jan 31 + 1 month lands on Feb 28, not March', () {
      expect(bill('Monthly', DateTime(2027, 1, 31)).followingDate, DateTime(2027, 2, 28));
    });

    test('weekly, quarterly, yearly', () {
      expect(bill('Weekly', DateTime(2026, 10, 18)).followingDate, DateTime(2026, 10, 25));
      expect(bill('Quarterly', DateTime(2026, 11, 1)).followingDate, DateTime(2027, 2, 1));
      expect(bill('Yearly', DateTime(2026, 11, 1)).followingDate, DateTime(2027, 11, 1));
    });
  });

  test('Remaining Budget = Monthly Budget - Total Expenses (sheet sample)', () {
    const budget = 25000.0, expenses = 17450.0;
    expect(budget - expenses, 7550);
    expect((expenses / budget * 100).toStringAsFixed(1), '69.8');
  });
}
