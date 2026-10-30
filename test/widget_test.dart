import 'package:flutter_test/flutter_test.dart';

import 'package:budget_tracker/main.dart';

void main() {
  testWidgets('Dashboard loads with sample data', (tester) async {
    await tester.pumpWidget(const BudgetTrackerApp());
    expect(find.text('Dashboard'), findsWidgets);
  });
}
