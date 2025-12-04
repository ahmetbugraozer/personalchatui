import 'package:flutter/material.dart';
import '../../enums/app.enum.dart';
import '../dialogs/premium_dialog.dart';

class UserMenuButton extends StatelessWidget {
  final bool openTarget;
  final double avatarSize;
  final double userNameGap;
  final double bottomRowPadH;
  final double bottomRowPadV;

  const UserMenuButton({
    super.key,
    required this.openTarget,
    required this.avatarSize,
    required this.userNameGap,
    required this.bottomRowPadH,
    required this.bottomRowPadV,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<UserMenuAction>(
      tooltip: AppTooltips.userProfile,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case UserMenuAction.upgradePlan:
            showDialog(context: context, builder: (_) => const PremiumDialog());
            break;
          case UserMenuAction.customization:
            // TODO: Open customization
            break;
          case UserMenuAction.settings:
            // TODO: Open settings
            break;
          case UserMenuAction.help:
            // TODO: Open help
            break;
          case UserMenuAction.logout:
            // TODO: Logout
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<UserMenuAction>(
              enabled: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      AppStrings.userName.substring(0, 2).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: userNameGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.userName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@${AppStrings.userName.toLowerCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => const PremiumDialog(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(AppStrings.upgradePlan.split(' ').last),
                  ),
                ],
              ),
            ),

            // User header item (non-selectable visual)
            const PopupMenuDivider(),
            PopupMenuItem(
              value: UserMenuAction.upgradePlan,
              child: Row(
                children: [
                  const Icon(Icons.rocket_launch_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(AppStrings.upgradePlan),
                ],
              ),
            ),
            PopupMenuItem(
              value: UserMenuAction.customization,
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(AppStrings.customization),
                ],
              ),
            ),
            PopupMenuItem(
              value: UserMenuAction.settings,
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, size: 20),
                  const SizedBox(width: 12),
                  Text(AppStrings.settings),
                ],
              ),
            ),
            PopupMenuItem(
              value: UserMenuAction.help,
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(AppStrings.help)),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.iconTheme.color?.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: UserMenuAction.logout,
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.logout,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: bottomRowPadH,
          vertical: bottomRowPadV * 0.5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: avatarSize * 0.6,
                color: theme.colorScheme.primary,
              ),
            ),
            if (openTarget) ...[
              SizedBox(width: userNameGap),
              Flexible(
                child: Text(
                  AppStrings.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
