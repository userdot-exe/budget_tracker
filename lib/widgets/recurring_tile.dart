import 'package:flutter/material.dart';

import '../models/recurring_expense.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'budget_alerts.dart';
import 'ledger_row.dart';
import 'recurring_form.dart';

class RecurringTile extends StatelessWidget {
  const RecurringTile({super.key, required this.item});

  final RecurringExpense item;

  void _pay(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final expense = db.markRecurringPaid(item.id);
    final next = db.recurringById(item.id)!.nextDate;
    showBudgetAlert(
      messenger,
      category: expense.category,
      month: monthOf(expense.date),
      fallback: '${item.name} paid. Next payment ${shortDate(next)}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final due = item.dueStatus(DateTime.now());

    return LedgerRow(
      onTap: () => showRecurringForm(context, item: item),
      date: item.nextDate,
      title: item.name,
      subtitle: '${item.frequency}, ${item.paymentMethod}',
      dotColor: categoryColor(item.category),
      badge: switch (due) {
        DueStatus.overdue => SmallBadge(text: 'Overdue', color: c.danger),
        DueStatus.dueSoon => SmallBadge(text: 'Due soon', color: c.warn),
        DueStatus.upcoming => null,
      },
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(plainAmount(item.amount), style: AppText.mono(14, color: c.ink)),
          TextButton(
            onPressed: () => _pay(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Mark paid', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
