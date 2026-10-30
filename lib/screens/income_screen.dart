import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/budget_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/income_form.dart';
import '../widgets/income_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/tile_group.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  bool _allTime = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final month = db.selectedMonth;
        final list = _allTime ? db.allIncomes : db.incomesFor(month);
        final total = list.fold<double>(0, (sum, i) => sum + i.amount);
        final bySource = [
          for (final s in incomeSources)
            (s, list.where((i) => i.source == s).fold<double>(0, (t, i) => t + i.amount)),
        ].where((e) => e.$2 > 0).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(monthLabel(month))),
                const ButtonSegment(value: true, label: Text('All history')),
              ],
              selected: {_allTime},
              onSelectionChanged: (s) => setState(() => _allTime = s.first),
            ),
            const SizedBox(height: 22),
            Text('RECEIVED', style: AppText.eyebrow(context.colors.muted)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(peso(total), style: AppText.display(40, color: context.colors.accent)),
            ),
            if (bySource.isNotEmpty) ...[
              const SizedBox(height: 14),
              BudgetStrip(
                height: 10,
                total: total,
                segments: [
                  for (var i = 0; i < bySource.length; i++)
                    StripSegment(
                      bySource[i].$1,
                      bySource[i].$2,
                      context.colors.accent.withValues(alpha: (1 - i * 0.18).clamp(0.3, 1.0).toDouble()),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (final e in bySource)
                    Text.rich(TextSpan(
                      style: TextStyle(fontSize: 12.5, color: context.colors.muted),
                      children: [
                        TextSpan(text: '${e.$1} '),
                        TextSpan(text: pesoCompact(e.$2), style: AppText.mono(12.5, color: context.colors.ink)),
                      ],
                    )),
                ],
              ),
            ],
            SectionHeader(
              title: 'Income history',
              trailing: Text('${list.length} record${list.length == 1 ? '' : 's'}',
                  style: AppText.mono(12, color: context.colors.muted)),
            ),
            if (list.isEmpty)
              const Card(
                child: EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'No income recorded yet',
                  message: 'Tap Add income to record your salary, allowance, or other income.',
                ),
              )
            else
              TileGroup(children: [
                for (final i in list)
                  IncomeTile(income: i, onTap: () => showIncomeForm(context, income: i)),
              ]),
          ],
        );
      },
    );
  }
}
