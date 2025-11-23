import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/sidebar_controller.dart';
import '../../enums/app.enum.dart';
import '../dialogs/search_chats_dialog.dart';
import '../dialogs/library_dialog.dart';
import '../dialogs/delete_chat_dialog.dart';
import 'sidebar/sidebar_entry.dart';
import 'sidebar/sidebar_history_item.dart';

class SidebarPanel extends StatelessWidget {
  // Indicate this panel is rendered inside the Drawer
  final bool inDrawer;
  const SidebarPanel({super.key, this.inDrawer = false});

  void _closeDrawerIfPossible(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ChatController chat,
    int index,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteChatDialog(title: label),
    );
    if (confirmed == true) chat.deleteSession(index);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SidebarController>();
    final chat = Get.find<ChatController>();

    BuildContext exampleContext = context;

    return Obx(() {
      final theme = Theme.of(context);
      final bool isOpenRx = ctrl.isOpen.value;
      final bool open = inDrawer ? true : isOpenRx;

      return LayoutBuilder(
        builder: (context, constraints) {
          final double viewportWidth =
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;
          final double expandedWidth = (viewportWidth * 0.22).clamp(
            220.0,
            320.0,
          );
          final double width = open ? expandedWidth : 72.0;

          final bool showLabel = open && width > 140;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            width: width,
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
                              _closeDrawerIfPossible(context);
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
                        SidebarEntry(
                          icon: Icons.add_comment_rounded,
                          label: AppStrings.newChat,
                          open: open,
                          onTap: () {
                            final started = chat.newChat();
                            if (inDrawer) {
                              _closeDrawerIfPossible(context);
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
                        SidebarEntry(
                          icon: Icons.search_rounded,
                          label: AppStrings.searchChatsHint,
                          open: open,
                          onTap: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => const SearchChatsDialog(),
                            );
                            if (inDrawer && result != null) {
                              _closeDrawerIfPossible(
                                exampleContext.mounted
                                    ? exampleContext
                                    : context,
                              );
                            }
                          },
                        ),
                        const Divider(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: open ? 12 : 0,
                          ),
                          child: _SectionHeader(
                            text: AppStrings.history,
                            open: open,
                          ),
                        ),
                        Obx(() {
                          final _ = chat.currentIndexRx.value;
                          final indices = chat.nonEmptySessionIndices;
                          if (indices.isEmpty) {
                            return open
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    AppStrings.noChatsYet,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                )
                                : const SizedBox.shrink();
                          }
                          return Column(
                            children:
                                indices.reversed.map((realIndex) {
                                  final label = chat.titleFor(realIndex);
                                  final logos =
                                      chat
                                          .modelHistoryRxFor(realIndex)
                                          .map(
                                            (id) => AppModels.meta(id).logoUrl,
                                          )
                                          .toList();
                                  return SidebarHistoryItem(
                                    open: open,
                                    label: label,
                                    logos: logos,
                                    isSelected: realIndex == chat.currentIndex,
                                    isFavorite: chat.isFavorite(realIndex),
                                    onTap: () {
                                      chat.selectSession(realIndex);
                                      if (inDrawer) {
                                        _closeDrawerIfPossible(context);
                                      }
                                    },
                                    onRename:
                                        (value) => chat.renameSession(
                                          realIndex,
                                          value,
                                        ),
                                    onToggleFavorite:
                                        () => chat.toggleFavorite(realIndex),
                                    onDelete:
                                        () => _confirmDelete(
                                          context,
                                          chat,
                                          realIndex,
                                          label,
                                        ),
                                  );
                                }).toList(),
                          );
                        }),
                        const Divider(height: 24),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: open ? 12 : 0,
                          ),
                          child: _SectionHeader(
                            text: AppStrings.projects,
                            open: open,
                          ),
                        ),
                        SidebarEntry(
                          icon: Icons.work_outline_rounded,
                          label: AppStrings.projects,
                          open: open,
                          onTap: () {},
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: open ? 12 : 0,
                          ),
                          child: _SectionHeader(
                            text: AppStrings.library,
                            open: open,
                          ),
                        ),
                        SidebarEntry(
                          icon: Icons.folder_outlined,
                          label: AppStrings.library,
                          open: open,
                          onTap: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (_) => const LibraryDialog(),
                            );
                            if (inDrawer && result != null) {
                              _closeDrawerIfPossible(
                                exampleContext.mounted
                                    ? exampleContext
                                    : context,
                              );
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
        },
      );
    });
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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(
            context,
          ).textTheme.labelLarge?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
