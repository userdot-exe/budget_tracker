import '../utils/firestore_codec.dart';

enum DueStatus { overdue, dueSoon, upcoming }

class RecurringExpense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String paymentMethod;
  final String frequency;
  final DateTime nextDate;

  const RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.frequency,
    required this.nextDate,
  });

  factory RecurringExpense.fromMap(String id, Map<String, dynamic> map) => RecurringExpense(
        id: id,
        name: readString(map['name']),
        amount: readDouble(map['amount']),
        category: readString(map['category'], 'Bills'),
        paymentMethod: readString(map['paymentMethod'], 'Other'),
        frequency: readString(map['frequency'], 'Monthly'),
        nextDate: readDate(map['nextDate']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'category': category,
        'paymentMethod': paymentMethod,
        'frequency': frequency,
        'nextDate': nextDate,
      };

  /// The due date after the current one is paid.
  DateTime get followingDate {
    switch (frequency) {
      case 'Weekly':
        return DateTime(nextDate.year, nextDate.month, nextDate.day + 7);
      case 'Quarterly':
        return _addMonths(nextDate, 3);
      case 'Yearly':
        return _addMonths(nextDate, 12);
      default:
        return _addMonths(nextDate, 1);
    }
  }

  DueStatus dueStatus(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (nextDate.isBefore(today)) return DueStatus.overdue;
    if (nextDate.difference(today).inDays <= 7) return DueStatus.dueSoon;
    return DueStatus.upcoming;
  }

  RecurringExpense copyWith({
    String? name,
    double? amount,
    String? category,
    String? paymentMethod,
    String? frequency,
    DateTime? nextDate,
  }) {
    return RecurringExpense(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
    );
  }
}

/// Adds months while keeping the day valid (Jan 31 + 1 month = Feb 28).
DateTime _addMonths(DateTime date, int months) {
  final first = DateTime(date.year, date.month + months, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, date.day > lastDay ? lastDay : date.day);
}
