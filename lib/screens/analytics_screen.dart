import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/budget_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Widget _pair(Widget a, Widget b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final c = context.colors;
        final month = db.selectedMonth;
        final previous = DateTime(month.year, month.month - 1);

        final totalExp = db.totalExpenses(month);
        final prevExp = db.totalExpenses(previous);
        final balance = db.remainingBalance(month);
        final highest = db.highestCategory(month);
        final days = db.daysCounted(month);
        final diff = db.expenseDifference(month);
        final diffPct = prevExp > 0 ? diff / prevExp * 100 : 0.0;
        final segments = segmentsFromTotals(db.categoryTotals(month));

        final lastSix = [for (var i = 5; i >= 0; i--) DateTime(month.year, month.month - i)];
        final sixTotals = [for (final m in lastSix) db.totalExpenses(m)];
        final maxTotal = sixTotals.fold<double>(1, (a, b) => b > a ? b : a);

        final trendColor = diff > 0 ? c.danger : (diff < 0 ? c.accent : c.muted);
        final trendText = diff > 0
            ? 'Up ${peso(diff)}${prevExp > 0 ? ' (+${pct(diffPct)})' : ''} from ${shortMonth(previous)}'
            : diff < 0
                ? 'Down ${peso(-diff)} (${pct(diffPct)}) from ${shortMonth(previous)}'
                : 'Same as ${shortMonth(previous)}';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            _pair(
              StatCard(label: 'Income', value: peso(db.totalIncome(month)), caption: 'SUM OF INCOME'),
              StatCard(label: 'Expenses', value: peso(totalExp), caption: 'SUM OF EXPENSES'),
            ),
            _pair(
              StatCard(
                label: 'Balance',
                value: peso(balance),
                caption: 'INCOME - EXPENSES',
                valueColor: balance < 0 ? c.danger : null,
              ),
              StatCard(
                label: 'Top category',
                value: highest?.key ?? 'None',
                caption: highest == null ? 'NO EXPENSES YET' : plainAmount(highest.value),
              ),
            ),
            _pair(
              StatCard(
                label: 'Daily average',
                value: peso(db.averageDailySpending(month)),
                caption: 'EXPENSES / $days DAY${days == 1 ? '' : 'S'}',
              ),
              StatCard(
                label: 'Savings rate',
                value: pct(db.savingsRate(month)),
                caption: 'SAVINGS / INCOME x 100',
              ),
            ),

            // Where the money went
            const SectionHeader(title: 'Where it went'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: segments.isEmpty
                    ? const EmptyState(
                        icon: Icons.donut_large_outlined,
                        title: 'Nothing to break down yet',
                        message: 'Add expenses to see where your money goes.',
                      )
                    : Column(
                        children: [
                          BudgetStrip(segments: segments, total: totalExp, height: 14),
                          const SizedBox(height: 8),
                          for (final s in segments)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                children: [
                                  CategoryDot(color: s.color, size: 8),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(s.label)),
                                  Text(plainAmount(s.value), style: AppText.mono(13, color: c.ink)),
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      pct(s.value / totalExp * 100),
                                      textAlign: TextAlign.right,
                                      style: AppText.mono(12, weight: FontWeight.w400, color: c.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            // Monthly comparison (Section 19)
            const SectionHeader(title: 'Month to month'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trendText,
                        style: AppText.display(17, weight: FontWeight.w600, color: trendColor)),
                    const SizedBox(height: 4),
                    Text(
                      '${monthLabel(previous)}: ${peso(prevExp)}\n${monthLabel(month)}: ${peso(totalExp)}',
                      style: AppText.mono(12, weight: FontWeight.w400, color: c.muted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('DIFFERENCE', style: AppText.eyebrow(c.muted)),
                        const SizedBox(width: 10),
                        Text(
                          '${diff > 0 ? '+' : ''}${peso(diff)}',
                          style: AppText.mono(14, weight: FontWeight.w600, color: trendColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < lastSix.length; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (sixTotals[i] > 0)
                                      Text(
                                        sixTotals[i] >= 1000
                                            // Round in whole hundreds first so 17,450 shows 17.5k, not 17.4k.
                                            ? '${((sixTotals[i] / 100).round() / 10).toStringAsFixed(1)}k'
                                            : sixTotals[i].toStringAsFixed(0),
                                        style: AppText.mono(9.5, weight: FontWeight.w400, color: c.muted),
                                      ),
                                    const SizedBox(height: 4),
                                    Tooltip(
                                      message: '${monthLabel(lastSix[i])}: ${peso(sixTotals[i])}',
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeOutCubic,
                                        height: 3 + 92 * sixTotals[i] / maxTotal,
                                        decoration: BoxDecoration(
                                          color: i == lastSix.length - 1 ? c.ink : c.hatch,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      monthTag(lastSix[i]),
                                      style: AppText.mono(10,
                                          color: i == lastSix.length - 1 ? c.ink : c.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
