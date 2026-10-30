import 'package:flutter/material.dart';

import '../models/income.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'ledger_row.dart';

class IncomeTile extends StatelessWidget {
  const IncomeTile({super.key, required this.income, this.onTap});

  final Income income;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LedgerRow(
      onTap: onTap,
      date: income.date,
      title: income.source,
      subtitle: income.description.isEmpty ? 'Income' : income.description,
      dotColor: c.accent,
      amount: '+${plainAmount(income.amount)}',
      amountColor: c.accent,
    );
  }
}
