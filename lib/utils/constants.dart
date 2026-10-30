import 'package:flutter/material.dart';

/// Predefined expense categories (Section 4 of the activity).
const List<String> expenseCategories = [
  'Food',
  'Transportation',
  'Bills',
  'Education',
  'Shopping',
  'Entertainment',
  'Health',
  'Others',
];

/// Suggested income sources (Section 2).
const List<String> incomeSources = [
  'Salary',
  'Allowance',
  'Freelance',
  'Business',
  'Gift',
  'Other',
];

/// Required payment methods (Section 10).
const List<String> paymentMethods = [
  'Cash',
  'GCash',
  'Debit Card',
  'Credit Card',
  'Bank Transfer',
  'Other',
];

/// Frequencies for recurring expenses (Section 11).
const List<String> frequencies = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];

/// Category colors borrowed from Philippine peso bills:
/// ₱20 orange, ₱100 violet, ₱1000 blue, ₱500 yellow, ₱200 green.
const Map<String, Color> categoryColors = {
  'Food': Color(0xFFE2793B),
  'Transportation': Color(0xFF7B5CB8),
  'Bills': Color(0xFF3D6BC4),
  'Education': Color(0xFF24968B),
  'Shopping': Color(0xFFCC4B7C),
  'Entertainment': Color(0xFFD9A21F),
  'Health': Color(0xFF3F9A5E),
  'Others': Color(0xFF8A909C),
};

Color categoryColor(String category) =>
    categoryColors[category] ?? const Color(0xFF8A909C);
