import 'package:flutter/material.dart';
import 'package:personalchatui/core/sizer/app_sizer.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final bool open;

  const SectionHeader({super.key, required this.text, required this.open});

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.ch(context).clamp(2.0, 4.0)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(
            context,
          ).textTheme.labelLarge?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
