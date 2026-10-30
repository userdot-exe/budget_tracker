const List<String> _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const List<String> _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 17450 -> ₱17,450.00
String peso(double value) {
  final negative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '${negative ? '-' : ''}₱$whole.${parts[1]}';
}

/// 69.8 -> 69.8%
String pct(double value) => '${value.toStringAsFixed(1)}%';

/// October 2026
String monthLabel(DateTime month) =>
    '${_monthsFull[month.month - 1]} ${month.year}';

/// Oct
String shortMonth(DateTime month) => _monthsShort[month.month - 1];

/// Oct 7, 2026
String shortDate(DateTime d) =>
    '${_monthsShort[d.month - 1]} ${d.day}, ${d.year}';

/// 2026-10, used as a key for monthly budgets and savings.
String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

int daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

/// Default date for new records: today if viewing the current month,
/// otherwise the 1st of the month being viewed.
DateTime defaultDateFor(DateTime month) {
  final now = DateTime.now();
  return sameMonth(now, month)
      ? dateOnly(now)
      : DateTime(month.year, month.month, 1);
}

/// Amount without the peso sign, for ledger rows: 1,200.00
String plainAmount(double value) => peso(value).replaceFirst('₱', '');

/// Drops ".00" for whole amounts: ₱25,000
String pesoCompact(double value) {
  final text = peso(value);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

/// 06
String dayNumber(DateTime d) => d.day.toString().padLeft(2, '0');

/// OCT
String monthTag(DateTime d) => shortMonth(d).toUpperCase();
