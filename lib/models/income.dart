import '../utils/firestore_codec.dart';

class Income {
  final String id;
  final String source;
  final double amount;
  final DateTime date;
  final String description;

  const Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.date,
    this.description = '',
  });

  /// Firestore document -> Income
  factory Income.fromMap(String id, Map<String, dynamic> map) => Income(
        id: id,
        source: readString(map['source'], 'Other'),
        amount: readDouble(map['amount']),
        date: readDate(map['date']),
        description: readString(map['description']),
      );

  /// Income -> Firestore document (the id is the document name)
  Map<String, dynamic> toMap() => {
        'source': source,
        'amount': amount,
        'date': date,
        'description': description,
      };

  Income copyWith({
    String? source,
    double? amount,
    DateTime? date,
    String? description,
  }) {
    return Income(
      id: id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
