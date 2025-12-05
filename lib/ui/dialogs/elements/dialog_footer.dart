import 'package:flutter/material.dart';
import 'package:personalchatui/enums/app.enum.dart';

class DialogFooter extends StatelessWidget {
  final VoidCallback? onClose;

  const DialogFooter({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onClose ?? () => Navigator.of(context).pop(),
          child: Text(AppStrings.close),
        ),
      ],
    );
  }
}
