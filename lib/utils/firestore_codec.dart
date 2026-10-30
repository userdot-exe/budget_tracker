import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore stores dates as Timestamp. This turns them back into DateTime.
DateTime readDate(Object? value) {
  if (value is Timestamp) {
    final d = value.toDate();
    return DateTime(d.year, d.month, d.day);
  }
  if (value is DateTime) return DateTime(value.year, value.month, value.day);
  return DateTime.now();
}

/// Firestore may return whole numbers as int, so convert to double safely.
double readDouble(Object? value) => value is num ? value.toDouble() : 0;

String readString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;
