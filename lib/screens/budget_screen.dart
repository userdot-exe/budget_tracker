import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/budget_progress.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/recurring_form.dart';
import '../widgets/recurring_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/tile_group.dart';

/// Monthly budget, savings goal, category limits, and recurring expenses.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetKey = GlobalKey<FormState>();
  final _savingsKey = GlobalKey<FormState>();
  final _budget = TextEditingController();
  final _target = TextEditingController();
  final _current = TextEditingController();

  String? _syncedMonth;
  int _syncedRevision = -1;

  @override
  void initState() {
    super.initState();
    _syncFields();
    db.addListener(_syncFields);
  }

  @override
  void dispose() {
    db.removeListener(_syncFields);
    _budget.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  /// Refills the text fields when the month changes or data is reset.
  void _syncFields() {
    final month = db.selectedMonth;
    final key = monthKey(month);
    if (key == _syncedMonth && db.revision == _syncedRevision) return;
    _syncedMonth = key;
    _syncedRevision = db.revision;

    final budget = db.budgetFor(month);
    final savings = db.savingsFor(month);
    _budget.text = budget > 0 ? budget.toStringAsFixed(2) : '';
    _target.text = savings.target > 0 ? savings.target.toStringAsFixed(2) : '';
    _current.text = savings.target > 0 || savings.current > 0
        ? savings.current.toStringAsFixed(2)
        : '';
  }

  void _saveBudget() {
    if (!_budgetKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final month = db.selectedMonth;
    db.setBudget(month, parseMoney(_budget.text));
    showMessage(ScaffoldMessenger.of(context), 'Budget saved for ${monthLabel(month)}.');
  }

  void _saveSavings() {
    if (!_savingsKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    db.setSavings(db.selectedMonth, parseMoney(_target.text), parseMoney(_current.text));
    showMessage(ScaffoldMessenger.of(context), 'Savings goal saved.');
  }

  Future<void> _editLimit(String category) async {
    final current = db.limitFor(category);
    final controller =
        TextEditingController(text: current > 0 ? current.toStringAsFixed(2) : '');
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$category limit'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly spending limit',
                  prefixText: '₱',
                ),
                validator: validateAmount,
              ),
              const SizedBox(height: 10),
              Text(
                'Below 80% is normal, 80% to 99% is a warning, and 100% or more means the limit is exceeded.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          if (current > 0)
            TextButton(onPressed: () => Navigator.pop(ctx, 'remove'), child: const Text('Remove')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, 'save');
            },
            child: const Text('Save limit'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      db.setCategoryLimit(category, parseMoney(controller.text));
      showMessage(messenger, '$category limit saved.');
    } else if (result == 'remove') {
      db.removeCategoryLimit(category);
      showMessage(messenger, '$category limit removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final month = db.selectedMonth;
        final budget = db.budgetFor(month);
        final spent = db.totalExpenses(month);
        final savings = db.savingsFor(month);
        final recurring = db.recurringExpenses;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            // Monthly budget (Section 5)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _budgetKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Monthly budget', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _budget,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Budget amount',
                          prefixText: '₱',
                        ),
                        validator: validateAmount,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _saveBudget, child: const Text('Save budget')),
                      const SizedBox(height: 10),
                      Text(
                        'REMAINING = BUDGET - EXPENSES',
                        style: AppText.eyebrow(muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${plainAmount(budget)} - ${plainAmount(spent)} = ${peso(budget - spent)}',
                        style: AppText.mono(13, color: budget - spent < 0 ? context.colors.danger : null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Savings goal (Section 7)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _savingsKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Savings goal', style: Theme.of(context).textTheme.titleMedium),
                          ),
                          Text(pct(savings.progress), style: AppText.mono(13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (savings.progress / 100).clamp(0.0, 1.0).toDouble(),
                          minHeight: 6,
                          color: context.colors.accent,
                          backgroundColor: context.colors.paper,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${peso(savings.current)} saved of ${peso(savings.target)}'
                        '${savings.isReached ? '. Goal reached.' : ''}',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _target,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Target',
                                prefixText: '₱',
                              ),
                              validator: validateAmount,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _current,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Current savings',
                                prefixText: '₱',
                              ),
                              validator: validateNonNegative,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: _saveSavings, child: const Text('Save savings goal')),
                    ],
                  ),
                ),
              ),
            ),

            // Category limits (Section 6)
            SectionHeader(
              title: 'Category limits',
              trailing: Text('Tick marks the 80% warning line',
                  style: TextStyle(fontSize: 12, color: muted)),
            ),
            TileGroup(indent: 16, children: [
              for (final item in db.categoryBudgets(month))
                BudgetProgress(item: item, onTap: () => _editLimit(item.category)),
            ]),

            // Recurring expenses (Section 11)
            SectionHeader(
              title: 'Recurring expenses',
              trailing: TextButton.icon(
                onPressed: () => showRecurringForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ),
            if (recurring.isEmpty)
              const Card(
                child: EmptyState(
                  icon: Icons.event_repeat,
                  title: 'No recurring expenses',
                  message: 'Add bills like rent, internet, or subscriptions.',
                ),
              )
            else
              TileGroup(children: [for (final r in recurring) RecurringTile(item: r)]),
          ],
        );
      },
    );
  }
}
