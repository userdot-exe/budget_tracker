import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/budget_progress.dart';
import '../widgets/budget_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_tile.dart';
import '../widgets/income_form.dart';
import '../widgets/recurring_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/tile_group.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNavigate});

  /// Lets "See all" switch to another tab.
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final c = context.colors;
        final month = db.selectedMonth;
        final budget = db.budgetFor(month);
        final spent = db.totalExpenses(month);
        final remaining = db.remainingBudget(month);
        final used = db.budgetUsedPercent(month);
        final savings = db.savingsFor(month);
        final segments = segmentsFromTotals(db.categoryTotals(month));

        final watchlist = db
            .categoryBudgets(month)
            .where((x) => x.hasLimit && x.status != BudgetStatus.normal)
            .toList()
          ..sort((a, b) => b.percentUsed.compareTo(a.percentUsed));
        final recent = db.expensesFor(month).take(4).toList();
        final upcoming = db.recurringExpenses.take(3).toList();
        final over = budget > 0 && remaining < 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            // Remaining budget, the number people open the app for.
            Text(
              over ? 'OVER BUDGET BY' : 'LEFT TO SPEND',
              style: AppText.eyebrow(over ? c.danger : c.muted),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                peso(over ? -remaining : remaining),
                style: AppText.display(46, color: over ? c.danger : c.ink),
              ),
            ),
            const SizedBox(height: 6),
            if (budget > 0)
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 14, color: c.muted),
                  children: [
                    TextSpan(text: peso(spent), style: AppText.mono(13.5, color: c.ink)),
                    const TextSpan(text: ' of '),
                    TextSpan(text: peso(budget), style: AppText.mono(13.5, color: c.ink)),
                    TextSpan(text: ' spent, ${pct(used)}'),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Text('No budget set for ${monthLabel(month)}.',
                      style: TextStyle(fontSize: 14, color: c.muted)),
                  TextButton(onPressed: () => onNavigate(3), child: const Text('Set budget')),
                ],
              ),
            const SizedBox(height: 18),
            BudgetStrip(segments: segments, total: budget),
            if (segments.isNotEmpty) ...[
              const SizedBox(height: 10),
              StripLegend(segments: segments),
            ],
            const SizedBox(height: 22),
            // Same six lines as the dashboard in the activity sheet (Section 1).
            SummaryList(
              title: 'Personal budget',
              subtitle: monthLabel(month),
              rows: [
                SummaryRow('Monthly budget', peso(budget)),
                SummaryRow('Total income', peso(db.totalIncome(month))),
                SummaryRow('Total expenses', peso(spent)),
                SummaryRow('Remaining', peso(remaining)),
                SummaryRow(
                  'Savings',
                  peso(savings.current),
                  note: savings.target > 0 ? 'of ${pesoCompact(savings.target)}' : null,
                ),
                SummaryRow('Budget used', pct(used)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showExpenseForm(context),
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Add expense'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showIncomeForm(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add income'),
                  ),
                ),
              ],
            ),
            if (watchlist.isNotEmpty) ...[
              SectionHeader(
                title: 'Watchlist',
                trailing: TextButton(onPressed: () => onNavigate(3), child: const Text('Limits')),
              ),
              for (final a in watchlist)
                AlertBanner(
                  status: a.status,
                  message: a.status == BudgetStatus.exceeded
                      ? (a.spent > a.limit
                          ? '${a.category} is over its limit by ${peso(a.spent - a.limit)}.'
                          : '${a.category} has reached its ${pesoCompact(a.limit)} limit.')
                      : '${a.category} is at ${pct(a.percentUsed)} of its ${pesoCompact(a.limit)} limit.',
                ),
            ],
            SectionHeader(
              title: 'Bills due',
              trailing: TextButton(onPressed: () => onNavigate(3), child: const Text('Manage')),
            ),
            if (upcoming.isEmpty)
              const Card(
                child: EmptyState(
                  icon: Icons.event_repeat,
                  title: 'No recurring bills',
                  message: 'Add rent, internet, or subscriptions in the Budget tab.',
                ),
              )
            else
              TileGroup(children: [for (final r in upcoming) RecurringTile(item: r)]),
            SectionHeader(
              title: 'Recent',
              trailing: TextButton(onPressed: () => onNavigate(2), child: const Text('See all')),
            ),
            if (recent.isEmpty)
              Card(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses in ${monthLabel(month)}',
                  message: 'Tap Add expense to record your first one.',
                ),
              )
            else
              TileGroup(children: [
                for (final e in recent)
                  ExpenseTile(expense: e, onTap: () => showExpenseForm(context, expense: e)),
              ]),
          ],
        );
      },
    );
  }
}
