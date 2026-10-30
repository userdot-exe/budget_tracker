import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'ledger_row.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense, this.onTap});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LedgerRow(
      onTap: onTap,
      date: expense.date,
      title: expense.title,
      subtitle: '${expense.category}, ${expense.paymentMethod}',
      dotColor: categoryColor(expense.category),
      amount: '\u2212${plainAmount(expense.amount)}',
      badge: expense.isRecurring
          ? SmallBadge(text: 'Recurring', color: context.colors.accent)
          : null,
    );
  }
}
