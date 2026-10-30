import 'package:flutter/material.dart';

import '../models/income.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import 'date_field.dart';
import 'dialogs.dart';
import 'form_sheet.dart';

Future<void> showIncomeForm(BuildContext context, {Income? income}) =>
    showFormSheet(context, IncomeForm(income: income));

class IncomeForm extends StatefulWidget {
  const IncomeForm({super.key, this.income});

  final Income? income;

  @override
  State<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  String? _source;
  late DateTime _date;

  bool get _isEdit => widget.income != null;

  @override
  void initState() {
    super.initState();
    final i = widget.income;
    _amount = TextEditingController(text: i == null ? '' : i.amount.toStringAsFixed(2));
    _description = TextEditingController(text: i?.description ?? '');
    _source = i?.source;
    _date = i?.date ?? defaultDateFor(db.selectedMonth);
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final old = widget.income;
    final income = Income(
      id: old?.id ?? db.newId(),
      source: _source!,
      amount: parseMoney(_amount.text),
      date: dateOnly(_date),
      description: _description.text.trim(),
    );

    if (old == null) {
      db.addIncome(income);
    } else {
      db.updateIncome(income);
    }
    Navigator.pop(context);
    showMessage(messenger, old == null ? 'Income added.' : 'Income updated.');
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(context, 'income record');
    if (!ok || !mounted) return;
    db.deleteIncome(widget.income!.id);
    Navigator.pop(context);
    showMessage(messenger, 'Income deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormSheetLayout(
        title: _isEdit ? 'Edit income' : 'Add income',
        actions: FormActions(
          saveLabel: _isEdit ? 'Save changes' : 'Add income',
          onSave: _save,
          onDelete: _isEdit ? _delete : null,
        ),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'Source'),
            hint: const Text('Select a source'),
            items: [
              for (final s in incomeSources) DropdownMenuItem(value: s, child: Text(s)),
            ],
            onChanged: (v) => setState(() => _source = v),
            validator: (v) => validateSelected(v, 'source'),
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