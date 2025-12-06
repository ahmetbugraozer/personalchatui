import 'package:flutter/material.dart';
import 'package:personalchatui/ui/dialogs/elements/dialog_footer.dart';
import 'package:personalchatui/ui/dialogs/elements/dialog_header.dart';
import '../../../core/sizer/app_sizer.dart';

/// Standardized dialog scaffold for consistent layout across all dialogs.
/// Provides: title, optional actions, content area, and close button.
class DialogScaffold extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? titleActions;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double? maxWidth;
  final double? maxHeight;

  /// When true, content is wrapped with IntrinsicHeight instead of Expanded.
  /// Use this for content that should size itself based on its children.
  final bool useIntrinsicHeight;

  const DialogScaffold({
    super.key,
    required this.title,
    required this.content,
    this.titleActions,
    this.showCloseButton = true,
    this.onClose,
    this.maxWidth,
    this.maxHeight,
    this.useIntrinsicHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 4.w.clamp(12, 32),
        vertical: 3.h.clamp(16, 36),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          final effectiveMaxWidth =
              maxWidth ??
              (isNarrow
                  ? constraints.maxWidth
                  : 86.w.clamp(680, 980) as double);

          // Build content widget based on mode
          Widget contentWidget;
          if (useIntrinsicHeight) {
            contentWidget = IntrinsicHeight(child: content);
          } else {
            contentWidget = Expanded(child: content);
          }

          // Build the column
          final columnChildren = <Widget>[
            // Title row
            DialogHeader(title: title, actions: titleActions),
            SizedBox(height: 1.6.h.clamp(10, 22)),
            // Content
            contentWidget,
            // Close button
            if (showCloseButton) ...[
              SizedBox(height: 1.0.h.clamp(6, 14)),
              DialogFooter(onClose: onClose),
            ],
          ];

          // When using intrinsic height, don't constrain maxHeight
          if (useIntrinsicHeight) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              child: Padding(
                padding: EdgeInsets.all(2.h.clamp(12, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: columnChildren,
                ),
              ),
            );
          }

          // Standard mode with maxHeight
          final effectiveMaxHeight =
              maxHeight ??
              (isNarrow
                  ? 78.h.clamp(420, 820) as double
                  : 70.h.clamp(520, 760) as double);

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: effectiveMaxWidth,
              maxHeight: effectiveMaxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(2.h.clamp(12, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: columnChildren,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dynamic height for filter chips and search fields in dialogs.
double dialogInputHeight(BuildContext context) =>
    5.5.ch(context).clamp(40.0, 52.0);

/// Dynamic content padding for search/input fields in dialogs.
EdgeInsets dialogInputPadding(BuildContext context) => EdgeInsets.symmetric(
  horizontal: 1.2.cw(context).clamp(10.0, 16.0),
  vertical: 1.0.ch(context).clamp(8.0, 14.0),
);
