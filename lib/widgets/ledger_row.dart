import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'budget_strip.dart';

/// Date printed like a bank passbook entry: big day, small month.
class DateStamp extends StatelessWidget {
  const DateStamp({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dayNumber(date), style: AppText.display(18, weight: FontWeight.w600, color: c.ink)),
          const SizedBox(height: 2),
          Text(monthTag(date),
              style: AppText.mono(10.5, color: c.muted).copyWith(letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

/// One row in a list of money movements. Used by income, expense,
/// and recurring tiles so every list reads the same way.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.date,
    required this.title,
    required this.subtitle,
    this.dotColor,
    this.amount,
    this.amountColor,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final Color? dotColor;
  final String? amount;
  final Color? amountColor;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            DateStamp(date: date),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: 6), badge!],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (dotColor != null) ...[
                        CategoryDot(color: dotColor!),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Text(amount ?? '', style: AppText.mono(14, color: amountColor ?? c.ink)),
          ],
        ),
      ),
    );
  }
}

/// Tiny uppercase tag, e.g. RECURRING or DUE SOON.
class SmallBadge extends StatelessWidget {
  const SmallBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppText.mono(9.5, weight: FontWeight.w600, color: color).copyWith(letterSpacing: 0.6),
      ),
    );
  }
}
