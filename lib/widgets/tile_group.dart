import 'package:flutter/material.dart';

/// Puts list rows inside one card with hairlines between them.
class TileGroup extends StatelessWidget {
  const TileGroup({super.key, required this.children, this.indent = 64});

  final List<Widget> children;

  /// Divider starts after the date column so rows read like a ledger.
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) Divider(height: 1, indent: indent),
          ],
        ],
      ),
    );
  }
}
