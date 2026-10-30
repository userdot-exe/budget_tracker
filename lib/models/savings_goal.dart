import '../utils/firestore_codec.dart';

class SavingsGoal {
  final String monthKey;
  final double target;
  final double current;

  const SavingsGoal({
    required this.monthKey,
    required this.target,
    required this.current,
  });

  /// The document name is the month key, e.g. "2026-10".
  factory SavingsGoal.fromMap(String monthKey, Map<String, dynamic> map) => SavingsGoal(
        monthKey: monthKey,
        target: readDouble(map['target']),
        current: readDouble(map['current']),
      );

  Map<String, dynamic> toMap() => {'target': target, 'current': current};

  /// Savings Progress = Current Savings / Savings Target x 100
  double get progress => target > 0 ? current / target * 100 : 0;

  bool get isReached => target > 0 && current >= target;
}
