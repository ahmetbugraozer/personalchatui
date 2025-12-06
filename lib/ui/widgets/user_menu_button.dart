import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../enums/app.enum.dart';
import '../dialogs/confirmation_dialog.dart';
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

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => ConfirmationDialog(
            title: AppStrings.logoutConfirmTitle,
            content: AppStrings.logoutConfirmContent,
            confirmText: AppStrings.logout,
          ),
    );

    if (confirmed == true) {
      // Show loading overlay
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: false,
      );

      // Simulate logout delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Navigate to auth page
      Get.offAllNamed(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<UserMenuAction>(
      tooltip: AppTooltips.userProfile,
      offset: const Offset(0, -180),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: UserMenuAction.upgradePlan,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.stars_rounded),
                title: Text(AppStrings.upgradePlan),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppStrings.currentPlan,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: UserMenuAction.customization,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.palette_outlined),
                title: Text(AppStrings.customization),
              ),
            ),
            PopupMenuItem(
              value: UserMenuAction.settings,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_outlined),
                title: Text(AppStrings.settings),
              ),
            ),
            PopupMenuItem(
              value: UserMenuAction.help,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(AppStrings.help),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: UserMenuAction.logout,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.logout_rounded,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  AppStrings.logout,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ],
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
            _handleLogout(context);
            break;
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: bottomRowPadH,
          vertical: bottomRowPadV,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.15,
              ),
              child: Icon(
                Icons.person_rounded,
                size: avatarSize * 0.6,
                color: theme.colorScheme.primary,
              ),
            ),
            if (openTarget) ...[
              SizedBox(width: userNameGap),
              Expanded(
                child: Text(
                  AppStrings.userName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.iconTheme.color?.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
