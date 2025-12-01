import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/sizer/app_sizer.dart';
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
      final bool openTarget = inDrawer ? true : isOpenRx;

      return LayoutBuilder(
        builder: (context, constraints) {
          final double viewportWidth =
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;

          // Sizer-based dimensions
          final double minExpanded = 220.0;
          final double maxExpanded = 320.0;

          // When in drawer, fill the available width (drawer width).
          // Otherwise use the responsive calculation.
          final double expandedWidth =
              inDrawer
                  ? viewportWidth
                  : (viewportWidth * 0.22).clamp(minExpanded, maxExpanded);

          final double collapsedWidth = 72.0; // Standard collapsed width
          final double targetWidth =
              openTarget ? expandedWidth : collapsedWidth;
          final bool showLabel = inDrawer || (openTarget && targetWidth > 140);

          // Using app_sizer for paddings and spacings
          final double listVerticalPad = 0.8.ch(context).clamp(8.0, 14.0);
          final double sectionHorizontalPad =
              openTarget ? 1.2.cw(context).clamp(10.0, 18.0) : 0.0;
          final double dividerSpacing = 1.6.ch(context).clamp(16.0, 26.0);

          final EdgeInsets sectionPadding = EdgeInsets.symmetric(
            horizontal: sectionHorizontalPad,
          );
          final EdgeInsets listPadding = EdgeInsets.symmetric(
            vertical: listVerticalPad,
          );

          // Header height using sizer
          final double headerHeight = 6.5.ch(context).clamp(56.0, 64.0);
          final double headerPaddingH = 1.2.cw(context).clamp(8.0, 12.0);

          Widget sectionHeader(String text) => Padding(
            padding: sectionPadding,
            child: _SectionHeader(text: text, open: openTarget),
          );

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuart,
            width: targetWidth,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: expandedWidth,
                maxWidth: expandedWidth,
                child: Material(
                  color: theme.cardColor,
                  child: SizedBox(
                    width: expandedWidth,
                    child: Column(
                      children: [
                        Container(
                          height: headerHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: headerPaddingH,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: AppTooltips.toggleSidebar,
                                onPressed: () {
                                  if (inDrawer) {
                                    _closeDrawerIfPossible(context);
                                  } else {
                                    ctrl.toggle();
                                  }
                                },
                                icon: Icon(
                                  openTarget
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
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
                            padding: listPadding,
                            children: [
                              SidebarEntry(
                                icon: Icons.add_comment_rounded,
                                label: AppStrings.newChat,
                                open: openTarget,
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
                                open: openTarget,
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
                              Divider(height: dividerSpacing),
                              sectionHeader(AppStrings.projects),
                              SidebarEntry(
                                icon: Icons.work_outline_rounded,
                                label: AppStrings.projects,
                                open: openTarget,
                                onTap: () {},
                              ),
                              SizedBox(height: listVerticalPad),
                              sectionHeader(AppStrings.library),
                              SidebarEntry(
                                icon: Icons.folder_outlined,
                                label: AppStrings.library,
                                open: openTarget,
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
                              Divider(height: dividerSpacing),

                              sectionHeader(AppStrings.history),
                              Obx(() {
                                final _ = chat.currentIndexRx.value;
                                final indices = chat.nonEmptySessionIndices;
                                if (!openTarget || indices.isEmpty) {
                                  return openTarget
                                      ? Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 1.6
                                              .cw(context)
                                              .clamp(12.0, 16.0),
                                          vertical: 0.8
                                              .ch(context)
                                              .clamp(6.0, 8.0),
                                        ),
                                        child: Text(
                                          AppStrings.noChatsYet,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
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
                                                  (id) =>
                                                      AppModels.meta(
                                                        id,
                                                      ).logoUrl,
                                                )
                                                .toList();
                                        return SidebarHistoryItem(
                                          open: openTarget,
                                          label: label,
                                          logos: logos,
                                          isSelected:
                                              realIndex == chat.currentIndex,
                                          isFavorite: chat.isFavorite(
                                            realIndex,
                                          ),
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
                                              () => chat.toggleFavorite(
                                                realIndex,
                                              ),
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
                              Divider(height: dividerSpacing),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
