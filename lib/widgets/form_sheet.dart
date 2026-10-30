import 'package:flutter/material.dart';

Future<T?> showFormSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => child,
  );
}

/// Shared layout for bottom sheet forms.
class FormSheetLayout extends StatelessWidget {
  const FormSheetLayout({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
  });

  final String title;
  final List<Widget> children;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (final child in children) ...[child, const SizedBox(height: 12)],
            const SizedBox(height: 4),
            actions,
          ],
        ),
      ),
    );
  }
}

class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.saveLabel,
    required this.onSave,
    this.onDelete,
  });

  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onDelete != null)
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        const Spacer(),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 8),
        FilledButton(onPressed: onSave, child: Text(saveLabel)),
      ],
    );
  }
}
