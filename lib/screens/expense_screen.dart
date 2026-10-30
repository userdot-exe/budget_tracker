import 'package:flutter/material.dart';

import '../models/expense_filter.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_form.dart';
import '../widgets/expense_tile.dart';
import '../widgets/form_sheet.dart';
import '../widgets/tile_group.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  ExpenseFilter _filter = ExpenseFilter();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() => _filter = ExpenseFilter()..allTime = _filter.allTime);
  }

  Future<void> _openFilters() async {
    final result = await showFormSheet<ExpenseFilter>(
      context,
      _FilterSheet(initial: _filter.copy()),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final month = db.selectedMonth;
        final results = db.filterExpenses(_filter, month);
        final total = results.fold<double>(0, (sum, e) => sum + e.amount);
        final searchesAll = _filter.allTime || _filter.usesDateRange;
        final scopeEmpty =
            searchesAll ? db.allExpenses.isEmpty : db.expensesFor(month).isEmpty;
        final count = _filter.activeCount;

        Widget body;
        if (scopeEmpty) {
          body = Card(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: searchesAll ? 'No expenses yet' : 'No expenses in ${monthLabel(month)}',
              message: 'Tap Add expense to record what you spent.',
            ),
          );
        } else if (results.isEmpty) {
          body = Card(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching expenses',
              message: 'Try a different word or clear your filters.',
              action: OutlinedButton(onPressed: _clearFilters, child: const Text('Clear filters')),
            ),
          );
        } else {
          body = TileGroup(children: [
            for (final e in results)
              ExpenseTile(expense: e, onTap: () => showExpenseForm(context, expense: e)),
          ]);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(monthLabel(month))),
                const ButtonSegment(value: true, label: Text('All history')),
              ],
              selected: {_filter.allTime},
              onSelectionChanged: (s) => setState(() {
                _filter.allTime = s.first;
                if (!s.first) {
                  _filter.from = null;
                  _filter.to = null;
                }
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      fillColor: context.colors.surface,
                      hintText: 'Search title or description',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                                            suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() => _filter.query = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _filter.query = v),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      fixedSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    tooltip: 'Filters',
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in ['All', ...expenseCategories])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _filter.category == c,
                        onSelected: (_) => setState(() => _filter.category = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.length} expense${results.length == 1 ? '' : 's'}  ·  ${peso(total)}',
                    style: AppText.mono(12, color: context.colors.muted),
                  ),
                ),
                if (_filter.hasAny)
                  TextButton(onPressed: _clearFilters, child: const Text('Clear filters')),
              ],
            ),
            const SizedBox(height: 4),
            body,
          ],
        );
      },
    );
  }
}

/// Payment method, date range, and amount range filters.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final ExpenseFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final ExpenseFilter _f = widget.initial;
  late final _min = TextEditingController(text: _f.minAmount?.toStringAsFixed(2) ?? '');
  late final _max = TextEditingController(text: _f.maxAmount?.toStringAsFixed(2) ?? '');

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _f.paymentMethod = 'All';
      _f.from = null;
      _f.to = null;
      _min.clear();
      _max.clear();
    });
  }

  void _apply() {
    _f.minAmount = double.tryParse(_min.text.trim());
    _f.maxAmount = double.tryParse(_max.text.trim());

    // Swap if the user picked them backwards.
    final from = _f.from;
    final to = _f.to;
    if (from != null && to != null && from.isAfter(to)) {
      _f.from = to;
      _f.to = from;
    }
    final min = _f.minAmount;
    final max = _f.maxAmount;
    if (min != null && max != null && min > max) {
      _f.minAmount = max;
      _f.maxAmount = min;
    }
    Navigator.pop(context, _f);
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetLayout(
      title: 'Filter expenses',
      actions: Row(
        children: [
          TextButton(onPressed: _reset, child: const Text('Reset')),
          const Spacer(),
          FilledButton(onPressed: _apply, child: const Text('Apply filters')),
        ],
      ),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('pm-${_f.paymentMethod}'),
          initialValue: _f.paymentMethod,
          decoration: const InputDecoration(labelText: 'Payment method'),
          items: [
            const DropdownMenuItem(value: 'All', child: Text('Any method')),
            for (final p in paymentMethods) DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) => setState(() => _f.paymentMethod = v ?? 'All'),
        ),
        Row(
          children: [
            Expanded(
              child: DateField(
                label: 'From date',
                value: _f.from,
                onChanged: (d) => setState(() => _f.from = d),
                onClear: () => setState(() => _f.from = null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DateField(
                label: 'To date',
                value: _f.to,
                onChanged: (d) => setState(() => _f.to = d),
                onClear: () => setState(() => _f.to = null),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _min,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Min amount',
                  prefixText: '₱',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _max,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max amount',
                  prefixText: '₱',
                ),
              ),
            ),
          ],
        ),
        Text('Date filters search all history.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}