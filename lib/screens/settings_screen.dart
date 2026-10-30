import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/dialogs.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _loadSample(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmAction(
      context,
      title: 'Reload sample data?',
      message: 'This replaces everything in Firebase with the September and October 2026 sample records.',
      confirmLabel: 'Reload',
    );
    if (!ok) return;
    db.loadSampleData();
    showMessage(messenger, 'Sample data loaded. Showing October 2026.');
  }

  Future<void> _clearAll(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmAction(
      context,
      title: 'Delete all data?',
      message: 'All income, expenses, budgets, limits, and recurring bills will be removed from Firebase.',
      confirmLabel: 'Delete all',
    );
    if (!ok) return;
    db.clearAll();
    showMessage(messenger, 'All data deleted.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: db,
        builder: (context, _) {
          final muted = Theme.of(context).colorScheme.onSurfaceVariant;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('System')),
                          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                        selected: {db.themeMode},
                        onSelectionChanged: (s) => db.setThemeMode(s.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Your data', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        '${db.allIncomes.length} income records, ${db.allExpenses.length} expenses, '
                        '${db.recurringExpenses.length} recurring bills.\n'
                        'Saved in Cloud Firestore, with a copy on this phone so it works offline.',
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _loadSample(context),
                        child: const Text('Reload sample data'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _clearAll(context),
                        child: const Text('Delete all data'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Personal Budget Tracker\nMP101 Intermediate Laboratory Activity\nVersion 1.0.0',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
