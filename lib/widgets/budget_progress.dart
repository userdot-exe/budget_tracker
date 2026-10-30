import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'budget_strip.dart';

Color statusColor(BuildContext context, BudgetStatus status) {
  final c = context.colors;
  return switch (status) {
    BudgetStatus.normal => c.accent,
    BudgetStatus.warning => c.warn,
    BudgetStatus.exceeded => c.danger,
  };
}

/// Thin bar with a tick at 80%, the point where warnings start.
class LimitBar extends StatelessWidget {
  const LimitBar({super.key, required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = (percent / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(color: c.paper, borderRadius: BorderRadius.circular(3)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              height: 6,
              width: box.maxWidth * fill,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            Positioned(
              left: box.maxWidth * 0.8 - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: c.muted.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress row for one category limit (Section 6).
class BudgetProgress extends StatelessWidget {
  const BudgetProgress({super.key, required this.item, this.onTap});

  final CategoryBudget item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final catColor = categoryColor(item.category);
    final barColor = item.status == BudgetStatus.normal ? catColor : statusColor(context, item.status);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryDot(color: catColor, size: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.category,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                Text(
                  item.hasLimit
                      ? '${plainAmount(item.spent)} / ${plainAmount(item.limit)}'
                      : plainAmount(item.spent),
                  style: AppText.mono(12.5, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.hasLimit) ...[
              LimitBar(percent: item.percentUsed, color: barColor),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.status == BudgetStatus.normal ? c.muted : barColor,
                    ),
                  ),
                  const Spacer(),
                  Text(pct(item.percentUsed), style: AppText.mono(11.5, color: c.muted)),
                ],
              ),
            ] else
              Text('No limit set. Tap to add one.', style: TextStyle(fontSize: 12, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

/// Warning line for the dashboard watchlist.
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.status, required this.message});

  final BudgetStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
