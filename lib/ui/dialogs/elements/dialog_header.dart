import 'package:flutter/material.dart';

class DialogHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const DialogHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
