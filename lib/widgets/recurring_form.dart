import 'package:flutter/material.dart';

import '../models/recurring_expense.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'date_field.dart';
import 'dialogs.dart';
import 'form_sheet.dart';

Future<void> showRecurringForm(BuildContext context, {RecurringExpense? item}) =>
    showFormSheet(context, RecurringForm(item: item));

class RecurringForm extends StatefulWidget {
  const RecurringForm({super.key, this.item});

  final RecurringExpense? item;

  @override
  State<RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  String? _category;
  late String _payment;
  late String _frequency;
  late DateTime _nextDate;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final r = widget.item;
    _name = TextEditingController(text: r?.name ?? '');
    _amount = TextEditingController(text: r == null ? '' : r.amount.toStringAsFixed(2));
    _category = r?.category ?? 'Bills';
    _payment = r?.paymentMethod ?? 'GCash';
    _frequency = r?.frequency ?? 'Monthly';
    _nextDate = r?.nextDate ?? defaultDateFor(db.selectedMonth);
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final old = widget.item;
    final item = RecurringExpense(
      id: old?.id ?? db.newId(),
      name: _name.text.trim(),
      amount: parseMoney(_amount.text),
      category: _category!,
      paymentMethod: _payment,
      frequency: _frequency,
      nextDate: dateOnly(_nextDate),
    );

    if (old == null) {
      db.addRecurring(item);
    } else {
      db.updateRecurring(item);
    }
    Navigator.pop(context);
    showMessage(messenger, old == null ? 'Recurring expense added.' : 'Recurring expense updated.');
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(context, 'recurring expense');
    if (!ok || !mounted) return;
    db.deleteRecurring(widget.item!.id);
    Navigator.pop(context);
    showMessage(messenger, 'Recurring expense deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormSheetLayout(
        title: _isEdit ? 'Edit recurring expense' : 'Add recurring expense',
        actions: FormActions(
          saveLabel: _isEdit ? 'Save changes' : 'Add recurring',
          onSave: _save,
          onDelete: _isEdit ? _delete : null,
        ),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Internet',
            ),
            validator: (v) => validateRequiredText(v, 'Name'),
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
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: [
                    for (final f in frequencies) DropdownMenuItem(value: f, child: Text(f)),
                  ],
                  onChanged: (v) => setState(() => _frequency = v ?? 'Monthly'),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
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
            onChanged: (v) => setState(() => _payment = v ?? 'Cash'),
          ),
          DateField(
            label: 'Next payment',
            value: _nextDate,
            onChanged: (d) => setState(() => _nextDate = d),
          ),
        ],
      ),
    );
  }
}