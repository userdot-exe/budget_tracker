/// Section 17: amount must be greater than zero.
String? validateAmount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter an amount.';
  final amount = double.tryParse(text);
  if (amount == null) return 'Enter a valid number.';
  if (amount <= 0) return 'Amount must be greater than zero.';
  return null;
}

/// For values that can be zero, like current savings.
String? validateNonNegative(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter an amount.';
  final amount = double.tryParse(text);
  if (amount == null) return 'Enter a valid number.';
  if (amount < 0) return 'Amount cannot be negative.';
  return null;
}

String? validateRequiredText(String? value, String field) {
  if (value == null || value.trim().isEmpty) return '$field must not be empty.';
  return null;
}

String? validateSelected(String? value, String field) {
  if (value == null || value.isEmpty) return 'Select a $field.';
  return null;
}

/// Rounds to centavos so floating point noise doesn't show up in totals.
double parseMoney(String text) =>
    (double.parse(text.trim()) * 100).roundToDouble() / 100;
