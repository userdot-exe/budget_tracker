import '../utils/firestore_codec.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String description;

  /// Set when this expense was created from a recurring bill,
  /// so recurring payments can be identified separately (Section 11).
  final String? recurringId;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.description = '',
    this.recurringId,
  });

  bool get isRecurring => recurringId != null;

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        title: readString(map['title']),
        amount: readDouble(map['amount']),
        category: readString(map['category'], 'Others'),
        date: readDate(map['date']),
        paymentMethod: readString(map['paymentMethod'], 'Other'),
        description: readString(map['description']),
        recurringId: map['recurringId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'category': category,
        'date': date,
        'paymentMethod': paymentMethod,
        'description': description,
        'recurringId': recurringId,
      };

  Expense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? description,
  }) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      recurringId: recurringId,
    );
  }
}
