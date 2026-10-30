import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'budget_alerts.dart';
import 'date_field.dart';
import 'dialogs.dart';
import 'form_sheet.dart';

Future<void> showExpenseForm(BuildContext context, {Expense? expense}) =>
    showFormSheet(context, ExpenseForm(expense: expense));

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _description;
  String? _category;
  String? _payment;
  late DateTime _date;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _title = TextEditingController(text: e?.title ?? '');
    _amount = TextEditingController(text: e == null ? '' : e.amount.toStringAsFixed(2));
    _description = TextEditingController(text: e?.description ?? '');
    _category = e?.category;
    _payment = e?.paymentMethod ?? 'Cash';
    _date = e?.date ?? defaultDateFor(db.selectedMonth);
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    // Invalid data must not be saved (Section 17).
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final old = widget.expense;
    final expense = Expense(
      id: old?.id ?? db.newId(),
      title: _title.text.trim(),
      amount: parseMoney(_amount.text),
      category: _category!,
      date: dateOnly(_date),
      paymentMethod: _payment!,
      description: _description.text.trim(),
      recurringId: old?.recurringId,
    );

    if (old == null) {
      db.addExpense(expense);
    } else {
      db.updateExpense(expense);
    }
    Navigator.pop(context);

    showBudgetAlert(
      messenger,
      category: expense.category,
      month: monthOf(expense.date),
      fallback: old == null ? 'Expense added.' : 'Expense updated.',
    );
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(context, 'expense');
    if (!ok || !mounted) return;
    db.deleteExpense(widget.expense!.id);
    Navigator.pop(context);
    showMessage(messenger, 'Expense deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormSheetLayout(
        title: _isEdit ? 'Edit expense' : 'Add expense',
        actions: FormActions(
          saveLabel: _isEdit ? 'Save changes' : 'Add expense',
          onSave: _save,
          onDelete: _isEdit ? _delete : null,
        ),
        children: [
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Groceries',
            ),
            validator: (v) => validateRequiredText(v, 'Expense title'),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₱',
                  ),
                  validator: validateAmount,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DateField(
                  label: 'Date',
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            hint: const Text('Select a category'),
            items: [
              for (final c in expenseCategories) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => validateSelected(v, 'category'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _payment,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: [
              for (final p in paymentMethods) DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => setState(() => _payment = v),
            validator: (v) => validateSelected(v, 'payment method'),
          ),
          TextFormField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
          ),
        ],
      ),
    );
  }
}