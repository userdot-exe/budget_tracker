import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class SummaryRow {
  final String label;
  final String value;
  final String? note;

  const SummaryRow(this.label, this.value, {this.note});
}

/// Side-by-side figures in one card, separated by thin rules.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.rows});

  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: c.line),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].label.toUpperCase(), style: AppText.eyebrow(c.muted)),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(rows[i].value, style: AppText.mono(15.5, color: c.ink)),
                      ),
                      if (rows[i].note != null) ...[
                        const SizedBox(height: 2),
                        Text(rows[i].note!, style: TextStyle(fontSize: 11.5, color: c.muted)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Labeled lines in one card, matching the dashboard in the activity sheet.
class SummaryList extends StatelessWidget {
  const SummaryList({super.key, required this.title, required this.subtitle, required this.rows});

  final String title;
  final String subtitle;
  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Column(
          children: [
            Row(
              children: [
                Text(title.toUpperCase(), style: AppText.eyebrow(c.ink)),
                const Spacer(),
                Text(subtitle, style: AppText.mono(11.5, weight: FontWeight.w400, color: c.muted)),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Expanded(child: Text(rows[i].label, style: const TextStyle(fontSize: 15))),
                    if (rows[i].note != null) ...[
                      Text(rows[i].note!, style: TextStyle(fontSize: 12, color: c.muted)),
                      const SizedBox(width: 8),
                    ],
                    Text(rows[i].value, style: AppText.mono(14.5, color: c.ink)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One figure with its formula underneath (Analytics).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppText.eyebrow(c.muted)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: AppText.display(21, weight: FontWeight.w600, color: valueColor ?? c.ink)),
            ),
            const Spacer(),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(caption,
                  maxLines: 1, style: AppText.mono(10.5, weight: FontWeight.w400, color: c.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
