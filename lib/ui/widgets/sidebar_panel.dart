import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:personalchatui/ui/widgets/section_header.dart';
import '../../core/sizer/app_sizer.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/sidebar_controller.dart';
import '../../enums/app.enum.dart';
import '../dialogs/search_chats_dialog.dart';
import '../dialogs/library_dialog.dart';
import '../dialogs/confirmation_dialog.dart';
import 'sidebar/sidebar_entry.dart';
import 'sidebar/sidebar_history_item.dart';
import 'user_menu_button.dart';

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
      builder:
          (_) => ConfirmationDialog.delete(
            title: AppStrings.deleteChatConfirmTitle,
            content: AppStrings.deleteChatDescription(label),
          ),
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

          final double expandedWidth =
              inDrawer
                  ? viewportWidth
                  : (viewportWidth * 0.22).clamp(minExpanded, maxExpanded);

          final double collapsedWidth = 72.0;
          final double targetWidth =
              openTarget ? expandedWidth : collapsedWidth;
          final bool showLabel = inDrawer || (openTarget && targetWidth > 140);

          // Using app_sizer for paddings and spacings
          final double sectionHorizontalPad =
              openTarget ? 1.2.cw(context).clamp(10.0, 18.0) : 0.0;
          final double dividerSpacing = 1.6.ch(context).clamp(16.0, 26.0);
          final double itemSpacing = 0.6.ch(context).clamp(4.0, 8.0);

          final EdgeInsets sectionPadding = EdgeInsets.symmetric(
            horizontal: sectionHorizontalPad,
          );

          // Header height using sizer
          final double headerHeight = 6.5.ch(context).clamp(56.0, 64.0);
          final double headerPaddingH = 1.2.cw(context).clamp(8.0, 12.0);

          // Bottom user row sizing
          final double bottomRowHeight = 6.5.ch(context).clamp(48.0, 60.0);
          final double bottomRowPadH = 1.0.cw(context).clamp(8.0, 12.0);
          final double bottomRowPadV = 0.6.ch(context).clamp(6.0, 10.0);
          final double avatarSize = 2.8.ch(context).clamp(24.0, 32.0);
          final double userNameGap = 0.6.cw(context).clamp(6.0, 10.0);
          final double bottomItemGap = 0.8.cw(context).clamp(6.0, 10.0);

          Widget sectionHeader(String text) => Padding(
            padding: sectionPadding,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SectionHeader(text: text, open: openTarget),
            ),
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
                        // ===== FIXED TOP SECTION =====
                        // Header row
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

                        // Fixed items: New Chat, Search
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: itemSpacing),
                          child: Column(
                            children: [
                              Obx(() {
                                // Check if current session is empty (new chat active)
                                final isNewChatActive =
                                    chat.currentSessionEmpty;
                                return SidebarEntry(
                                  icon: Icons.add_comment_outlined,
                                  selectedIcon: Icons.add_comment_rounded,
                                  label: AppStrings.newChat,
                                  open: openTarget,
                                  isSelected: isNewChatActive,
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
                                );
                              }),
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
                            ],
                          ),
                        ),

                        Divider(height: dividerSpacing),

                        SidebarEntry(
                          icon: Icons.work_outline_rounded,
                          label: AppStrings.projects,
                          open: openTarget,
                          onTap: () {},
                        ),

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

                        Expanded(
                          child: Obx(() {
                            final _ = chat.currentIndexRx.value;
                            final indices = chat.nonEmptySessionIndices;

                            // Separate favorites and non-favorites
                            final favoriteIndices =
                                indices
                                    .where((i) => chat.isFavorite(i))
                                    .toList()
                                    .reversed
                                    .toList();
                            final regularIndices =
                                indices
                                    .where((i) => !chat.isFavorite(i))
                                    .toList()
                                    .reversed
                                    .toList();

                            if (!openTarget || indices.isEmpty) {
                              return openTarget
                                  ? Align(
                                    alignment: Alignment.topLeft,
                                    child: Padding(
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
                                        style: theme.textTheme.labelLarge,
                                      ),
                                    ),
                                  )
                                  : const SizedBox.shrink();
                            }

                            return ListView(
                              padding: EdgeInsets.symmetric(
                                vertical: itemSpacing,
                              ),
                              children: [
                                // Favorites section (only if there are favorites)
                                if (favoriteIndices.isNotEmpty) ...[
                                  sectionHeader(AppStrings.favorites),
                                  ...favoriteIndices.map((realIndex) {
                                    final label = chat.titleFor(realIndex);
                                    final logos =
                                        chat
                                            .modelHistoryRxFor(realIndex)
                                            .map(
                                              (id) =>
                                                  AppModels.meta(id).logoUrl,
                                            )
                                            .toList();
                                    return SidebarHistoryItem(
                                      open: openTarget,
                                      label: label,
                                      logos: logos,
                                      isSelected:
                                          realIndex == chat.currentIndex,
                                      isFavorite: true,
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
                                  }),
                                ],
                                // History section (only if there are non-favorite chats)
                                if (regularIndices.isNotEmpty) ...[
                                  sectionHeader(AppStrings.history),
                                  ...regularIndices.map((realIndex) {
                                    final label = chat.titleFor(realIndex);
                                    final logos =
                                        chat
                                            .modelHistoryRxFor(realIndex)
                                            .map(
                                              (id) =>
                                                  AppModels.meta(id).logoUrl,
                                            )
                                            .toList();
                                    return SidebarHistoryItem(
                                      open: openTarget,
                                      label: label,
                                      logos: logos,
                                      isSelected:
                                          realIndex == chat.currentIndex,
                                      isFavorite: false,
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
                                  }),
                                ],
                              ],
                            );
                          }),
                        ),

                        const Divider(height: 1),
                        Container(
                          height: bottomRowHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: bottomRowPadH,
                            vertical: bottomRowPadV,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: UserMenuButton(
                                  openTarget: openTarget,
                                  avatarSize: avatarSize,
                                  userNameGap: userNameGap,
                                  bottomRowPadH: bottomRowPadH,
                                  bottomRowPadV: bottomRowPadV,
                                ),
                              ),
                              SizedBox(width: bottomItemGap),
                              // Settings button
                              Tooltip(
                                message: AppTooltips.settings,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      // Open settings
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        bottomRowPadV * 0.8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.settings_outlined,
                                        size: avatarSize * 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
