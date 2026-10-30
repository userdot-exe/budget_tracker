import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/database_service.dart';
import '../utils/formatters.dart';
import 'dialogs.dart';

const _danger = Color(0xFFC0402E);
const _warn = Color(0xFFB7800A);

/// After saving an expense, warns the user if a limit is near or exceeded
/// (Section 18). Otherwise shows the normal success message.
void showBudgetAlert(
  ScaffoldMessengerState messenger, {
  required String category,
  required DateTime month,
  required String fallback,
}) {
  final item = db.categoryBudget(category, month);
  final monthlyBudget = db.budgetFor(month);

  if (item.hasLimit && item.status == BudgetStatus.exceeded) {
    showMessage(
      messenger,
      item.spent > item.limit
          ? '$category exceeded its ${peso(item.limit)} limit by ${peso(item.spent - item.limit)}.'
          : '$category has reached its ${peso(item.limit)} limit.',
      color: _danger,
    );
  } else if (monthlyBudget > 0 && db.budgetUsedPercent(month) >= 100) {
    showMessage(
      messenger,
      db.remainingBudget(month) < 0
          ? 'Monthly budget exceeded by ${peso(-db.remainingBudget(month))}.'
          : 'You have used your whole monthly budget.',
      color: _danger,
    );
  } else if (item.hasLimit && item.status == BudgetStatus.warning) {
    showMessage(messenger, '$category is at ${pct(item.percentUsed)} of its limit.', color: _warn);
  } else {
    showMessage(messenger, fallback);
  }
}
