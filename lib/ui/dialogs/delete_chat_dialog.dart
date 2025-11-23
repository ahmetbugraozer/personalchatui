import 'package:flutter/material.dart';
import '../../enums/app.enum.dart';

class DeleteChatDialog extends StatelessWidget {
  final String title;
  const DeleteChatDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(AppStrings.deleteChatConfirmTitle),
      content: Text(AppStrings.deleteChatDescription(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.delete),
        ),
      ],
    );
  }
}
