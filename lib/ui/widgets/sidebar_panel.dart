import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/sidebar_controller.dart';
import '../../enums/app.enum.dart';
import '../dialogs/search_chats_dialog.dart';
import 'model_grid.dart';
import '../dialogs/library_dialog.dart'; // + add import

class SidebarPanel extends StatelessWidget {
  // Indicate this panel is rendered inside the Drawer
  final bool inDrawer;
  const SidebarPanel({super.key, this.inDrawer = false});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SidebarController>();
    final chat = Get.find<ChatController>();

    return Obx(() {
      final theme = Theme.of(context);

      // Force Obx to depend on a reactive even when inDrawer is true
      final bool isOpenRx = ctrl.isOpen.value;

      // Then compute the effective state
      final bool open = inDrawer ? true : isOpenRx;
      final double width = open ? 22.w.clamp(220, 320) : 72;

      // Only show the label after width grows enough to avoid overflow during animation
      final bool showLabel = open && width.toDouble() > 140;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        width: width.toDouble(),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(right: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppTooltips.toggleSidebar,
                      onPressed: () {
                        if (inDrawer) {
                          Navigator.of(context).pop(); // close Drawer
                        } else {
                          ctrl.toggle(); // collapse/expand in wide layout
                        }
                      },
                      icon: Icon(
                        open ? Icons.chevron_left : Icons.chevron_right,
                      ),
                    ),
                    if (showLabel)
                      Expanded(
                        child: Text(
                          AppStrings.chats,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _SidebarItem(
                      icon: Icons.add_comment_rounded,
                      label: AppStrings.newChat,
                      open: open,
                      onTap: () {
                        final started = chat.newChat();
                        if (inDrawer) {
                          Navigator.of(
                            context,
                          ).pop(); // close drawer in narrow mode
                        }
                        if (started) {
                          Get.snackbar(
                            AppStrings.newChat,
                            AppStrings.newChatCleared,
                            snackPosition: SnackPosition.TOP,
                            margin: const EdgeInsets.all(12),
                          );
                        }
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.search_rounded,
                      label: AppStrings.searchChats,
                      open: open,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final result = await showDialog(
                          context: context,
                          builder: (_) => const SearchChatsDialog(),
                        );
                        // Close drawer only if action taken in dialog
                        if (inDrawer && result != null) {
                          navigator.pop();
                        }
                      },
                    ),
                    const Divider(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0),
                      child: _SectionHeader(
                        text: AppStrings.history,
                        open: open,
                      ),
                    ),
                    Obx(() {
                      // Also react to currentIndex changes for selection highlight
                      final _ = chat.currentIndexRx.value;
                      final indices =
                          chat.nonEmptySessionIndices; // oldest -> newest
                      final count = indices.length;
                      if (count == 0) {
                        return open
                            ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                AppStrings.noChatsYet,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                            : const SizedBox.shrink();
                      }
                      return Column(
                        children: List.generate(count, (i) {
                          final realIndex =
                              indices[count - 1 - i]; // newest -> oldest
                          final label = chat.titleFor(realIndex);
                          final isSelected = realIndex == chat.currentIndex;

                          // Listen to model history reactively and pass to grid
                          final history =
                              chat.modelHistoryRxFor(realIndex).toList();
                          return _SidebarItem(
                            icon:
                                isSelected
                                    ? Icons.chat_bubble_rounded
                                    : Icons.chat_bubble_outline_rounded,
                            label: label,
                            open: open,
                            trailing: ModelGrid(
                              logoUrls:
                                  history
                                      .map((id) => AppModels.meta(id).logoUrl)
                                      .toList(),
                              size: history.length > 1 ? 32 : 20,
                            ),
                            onTap: () {
                              chat.selectSession(realIndex);
                              if (inDrawer) {
                                Navigator.of(context).pop();
                              }
                            },
                          );
                        }),
                      );
                    }),
                    const Divider(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0),
                      child: _SectionHeader(
                        text: AppStrings.projects,
                        open: open,
                      ),
                    ),
                    _SidebarItem(
                      icon: Icons.work_outline_rounded,
                      label: AppStrings.projects,
                      open: open,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: open ? 12 : 0),
                      child: _SectionHeader(
                        text: AppStrings.library,
                        open: open,
                      ),
                    ),
                    _SidebarItem(
                      icon: Icons.folder_outlined,
                      label: AppStrings.library,
                      open: open,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final result = await showDialog(
                          context: context,
                          builder: (_) => const LibraryDialog(),
                        );
                        // Close drawer only if action taken in dialog (e.g., "Sohbette aç")
                        if (inDrawer && result != null) {
                          navigator.pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool open;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.open,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 40,
                alignment: Alignment.center,
                child: Icon(icon, size: 22),
              ),
              if (open)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: theme.dividerColor,
                          width: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 6),
                          // Make trailing responsive to tight widths to avoid overflow
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: trailing!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool open;

  const _SectionHeader({required this.text, required this.open});

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(
            context,
          ).textTheme.labelMedium?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
