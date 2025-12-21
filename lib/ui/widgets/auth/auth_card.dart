import 'package:flutter/material.dart';
import '../../../core/sizer/app_sizer.dart';

class AuthCard extends StatelessWidget {
  final String title;
  final Widget child;

  const AuthCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 42.w.clamp(320, 420)),
      child: DecoratedBox(
        // Static shadow layer - won't repaint during size animation
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: RepaintBoundary(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Container(
              padding: EdgeInsets.all(2.4.h.clamp(20, 32)),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.4.h.clamp(18, 28)),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
