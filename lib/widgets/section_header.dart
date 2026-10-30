import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Small uppercase heading above a group, with an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 8),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Text(title.toUpperCase(), style: AppText.eyebrow(context.colors.muted)),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
