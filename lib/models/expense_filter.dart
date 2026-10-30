import 'expense.dart';

/// Search and filter options for the expense history (Section 9).
class ExpenseFilter {
  String query = '';
  String category = 'All';
  String paymentMethod = 'All';
  DateTime? from;
  DateTime? to;
  double? minAmount;
  double? maxAmount;

  /// false = only the selected month, true = all history.
  bool allTime = false;

  bool get usesDateRange => from != null || to != null;

  int get activeCount =>
      (category != 'All' ? 1 : 0) +
      (paymentMethod != 'All' ? 1 : 0) +
      (from != null ? 1 : 0) +
      (to != null ? 1 : 0) +
      (minAmount != null ? 1 : 0) +
      (maxAmount != null ? 1 : 0);

  bool get hasAny => query.trim().isNotEmpty || activeCount > 0;

  ExpenseFilter copy() => ExpenseFilter()
    ..query = query
    ..category = category
    ..paymentMethod = paymentMethod
    ..from = from
    ..to = to
    ..minAmount = minAmount
    ..maxAmount = maxAmount
    ..allTime = allTime;

  bool matches(Expense e, DateTime month) {
    // A date range searches all history, otherwise stick to the selected month.
    if (!allTime &&
        !usesDateRange &&
        (e.date.year != month.year || e.date.month != month.month)) {
      return false;
    }

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !e.title.toLowerCase().contains(q) &&
        !e.description.toLowerCase().contains(q)) {
      return false;
    }

    if (category != 'All' && e.category != category) return false;
    if (paymentMethod != 'All' && e.paymentMethod != paymentMethod) return false;

    final day = DateTime(e.date.year, e.date.month, e.date.day);
    final start = from;
    final end = to;
    if (start != null && day.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null && day.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }

    final min = minAmount;
    final max = maxAmount;
    if (min != null && e.amount < min) return false;
    if (max != null && e.amount > max) return false;

    return true;
  }
}
