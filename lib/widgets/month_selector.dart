import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';

/// Pill in the app bar: ‹ OCT 2026 ›
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final m = db.selectedMonth;
        return Container(
          height: 38,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Arrow(icon: Icons.chevron_left, tooltip: 'Previous month', onTap: () => db.changeMonth(-1)),
              Text(
                '${_months[m.month - 1]} ${m.year}',
                style: AppText.mono(12.5, color: c.ink).copyWith(letterSpacing: 0.8),
              ),
              _Arrow(icon: Icons.chevron_right, tooltip: 'Next month', onTap: () => db.changeMonth(1)),
            ],
          ),
        );
      },
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 20)),
      ),
    );
  }
}
