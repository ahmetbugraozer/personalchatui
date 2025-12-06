import 'package:flutter/material.dart';
import '../../enums/app.enum.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final Color? confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = '',
    this.confirmText = '',
    this.confirmColor,
  });

  /// Convenience factory for delete confirmations
  factory ConfirmationDialog.delete({
    Key? key,
    required String title,
    required String content,
  }) {
    return ConfirmationDialog(
      key: key,
      title: title,
      content: content,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.delete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveCancelText =
        cancelText.isEmpty ? AppStrings.cancel : cancelText;
    final effectiveConfirmText =
        confirmText.isEmpty ? AppStrings.continueAction : confirmText;
    final effectiveConfirmColor = confirmColor ?? theme.colorScheme.error;

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(effectiveCancelText),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: effectiveConfirmColor,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(effectiveConfirmText),
        ),
      ],
    );
  }
}
