import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/sizer/app_sizer.dart';
import '../../controllers/chat_controller.dart';
import '../../enums/app.enum.dart';
import '../widgets/model_grid.dart';
import 'elements/dialog_scaffold.dart';

class SearchChatsDialog extends StatefulWidget {
  const SearchChatsDialog({super.key});

  @override
  State<SearchChatsDialog> createState() => _SearchChatsDialogState();
}

class _SearchChatsDialogState extends State<SearchChatsDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Build grouped items (newest -> oldest) using session updatedAt
  List<Section> _buildSections(ChatController chat) {
    // Prepare list sorted by last activity desc
    final indices = chat.nonEmptySessionIndicesByUpdatedDesc;
    final items =
        indices
            .map(
              (i) => SessionItem(
                index: i,
                title: chat.titleFor(i),
                updatedAt: chat.updatedAtOf(i),
                isFavorite: chat.isFavorite(i),
              ),
            )
            .toList();

    // Filter by search query
    final q = _query.trim().toLowerCase();
    final filtered =
        q.isEmpty
            ? items
            : items.where((e) => e.title.toLowerCase().contains(q)).toList();

    // Separate favorites from regular items
    final favorites = filtered.where((e) => e.isFavorite).toList();
    final regular = filtered.where((e) => !e.isFavorite).toList();

    // Group regular items by date bucket
    final now = DateTime.now();
    String bucketOf(DateTime d) {
      final dt = DateTime(d.year, d.month, d.day);
      final nt = DateTime(now.year, now.month, now.day);
      final diff = nt.difference(dt).inDays;
      if (diff == 0) return AppStrings.today;
      if (diff == 1) return AppStrings.yesterday;
      if (diff <= 7) return AppStrings.last7Days;
      return AppStrings.older;
    }

    final Map<String, List<SessionItem>> groups = {
      AppStrings.favorites: favorites,
      AppStrings.today: [],
      AppStrings.yesterday: [],
      AppStrings.last7Days: [],
      AppStrings.older: [],
    };
    for (final it in regular) {
      groups[bucketOf(it.updatedAt)]!.add(it);
    }

    // Keep only non-empty sections in order (favorites first)
    final order = [
      AppStrings.favorites,
      AppStrings.today,
      AppStrings.yesterday,
      AppStrings.last7Days,
      AppStrings.older,
    ];
    return order
        .where((k) => groups[k]!.isNotEmpty)
        .map((k) => Section(title: k, items: groups[k]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        final maxWidth =
            isNarrow ? constraints.maxWidth : 80.w.clamp(520, 720) as double;
        final maxHeight =
            isNarrow
                ? 75.h.clamp(360, 680) as double
                : 60.h.clamp(420, 600) as double;

        return DialogScaffold(
          title: AppStrings.chats,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          content: Obx(() {
            // Rebuild on chat changes, keep UX responsive
            final sections = _buildSections(chat);
            final rows = <SessionRow>[];
            // First row: New chat
            rows.add(SessionRow.newChat());
            // Then grouped sections
            for (final sec in sections) {
              rows.add(SessionRow.header(sec.title));
              for (final it in sec.items) {
                rows.add(SessionRow.item(it));
              }
            }

            return Column(
              children: [
                // Search bar
                SizedBox(
                  height: dialogInputHeight(context),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppStrings.searchChatsHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      contentPadding: dialogInputPadding(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SizedBox(height: 1.4.h.clamp(10, 20)),

                // Scrollable content: new chat + grouped results
                Expanded(
                  child:
                      rows.length == 1
                          ? Center(
                            child: Text(
                              AppStrings.noResults,
                              style: theme.textTheme.titleLarge,
                            ),
                          )
                          : ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final r = rows[i];
                              Widget? tile;
                              switch (r.type) {
                                case RowType.newChat:
                                  tile = ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.edit_note_rounded,
                                    ),
                                    title: Text(AppStrings.newChat),
                                    onTap: () {
                                      chat.newChat();
                                      Navigator.of(context).pop('new');
                                    },
                                  );
                                  break;
                                case RowType.header:
                                  tile = Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      2.w.clamp(12, 20),
                                      1.2.h.clamp(8, 12),
                                      0,
                                      0.6.h.clamp(4, 8),
                                    ),
                                    child: Text(
                                      r.text!,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .labelMedium
                                                ?.color
                                                ?.withValues(alpha: 0.7),
                                          ),
                                    ),
                                  );
                                  break;
                                case RowType.item:
                                  final item = r.item!;
                                  final isSelected =
                                      item.index == chat.currentIndex;
                                  // Listen to model history; build logo grid
                                  final history =
                                      chat
                                          .modelHistoryRxFor(item.index)
                                          .toList();
                                  tile = ListTile(
                                    dense: true,
                                    leading: Icon(
                                      isSelected
                                          ? Icons.chat_bubble_rounded
                                          : Icons.chat_bubble_outline_rounded,
                                    ),
                                    title: Text(
                                      item.title.isEmpty
                                          ? AppStrings.newChat
                                          : item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: ModelGrid(
                                      // replaced _DialogModelGrid
                                      logoUrls:
                                          history
                                              .map(
                                                (id) =>
                                                    AppModels.meta(id).logoUrl,
                                              )
                                              .toList(),
                                      size: 22, // was 18, slightly larger
                                    ),
                                    onTap: () {
                                      chat.selectSession(item.index);
                                      Navigator.of(context).pop('selected');
                                    },
                                  );
                                  break;
                              }

                              // Add divider below regular items (not after headers or last)
                              final isLast = i == rows.length - 1;
                              final showDivider =
                                  r.type == RowType.item &&
                                  !isLast &&
                                  rows[i + 1].type != RowType.header;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  tile,
                                  if (showDivider)
                                    Divider(
                                      height: 1,
                                      color: theme.dividerColor,
                                    ),
                                ],
                              );
                            },
                          ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
