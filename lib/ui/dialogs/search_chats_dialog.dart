import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import '../../controllers/chat_controller.dart';
import '../../enums/app.enum.dart';
import '../widgets/model_grid.dart';

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
  List<_Section> _buildSections(ChatController chat) {
    // Prepare list sorted by last activity desc
    final indices = chat.nonEmptySessionIndicesByUpdatedDesc;
    final items =
        indices
            .map(
              (i) => _SessionItem(
                index: i,
                title: chat.titleFor(i),
                updatedAt: chat.updatedAtOf(i),
              ),
            )
            .toList();

    // Filter by search query
    final q = _query.trim().toLowerCase();
    final filtered =
        q.isEmpty
            ? items
            : items.where((e) => e.title.toLowerCase().contains(q)).toList();

    // Group by date bucket
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

    final Map<String, List<_SessionItem>> groups = {
      AppStrings.today: [],
      AppStrings.yesterday: [],
      AppStrings.last7Days: [],
      AppStrings.older: [],
    };
    for (final it in filtered) {
      groups[bucketOf(it.updatedAt)]!.add(it);
    }

    // Keep only non-empty sections in order
    final order = [
      AppStrings.today,
      AppStrings.yesterday,
      AppStrings.last7Days,
      AppStrings.older,
    ];
    return order
        .where((k) => groups[k]!.isNotEmpty)
        .map((k) => _Section(title: k, items: groups[k]!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: 4.w.clamp(12, 32),
        vertical: 3.h.clamp(16, 36),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          final maxWidth =
              isNarrow ? constraints.maxWidth : 80.w.clamp(520, 720) as double;
          final maxHeight =
              isNarrow
                  ? 75.h.clamp(360, 680) as double
                  : 60.h.clamp(420, 600) as double;

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.all(2.h.clamp(12, 24)),
              child: Obx(() {
                // Rebuild on chat changes, keep UX responsive
                final sections = _buildSections(chat);
                final rows = <_Row>[];
                // First row: New chat
                rows.add(_Row.newChat());
                // Then grouped sections
                for (final sec in sections) {
                  rows.add(_Row.header(sec.title));
                  for (final it in sec.items) {
                    rows.add(_Row.item(it));
                  }
                }

                return Column(
                  children: [
                    // Search bar (top)
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: AppStrings.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        isDense: true,
                        filled: true,
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
                    SizedBox(height: 1.4.h.clamp(10, 20)),

                    // Scrollable content: new chat + grouped results
                    Expanded(
                      child:
                          rows.length == 1
                              ? Center(
                                child: Text(
                                  AppStrings.noResults,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                              : ListView.builder(
                                itemCount: rows.length,
                                itemBuilder: (context, i) {
                                  final r = rows[i];
                                  Widget? tile;
                                  switch (r.type) {
                                    case _RowType.newChat:
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
                                    case _RowType.header:
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
                                    case _RowType.item:
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
                                              : Icons
                                                  .chat_bubble_outline_rounded,
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
                                                        AppModels.meta(
                                                          id,
                                                        ).logoUrl,
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
                                      r.type == _RowType.item &&
                                      !isLast &&
                                      rows[i + 1].type != _RowType.header;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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

                    SizedBox(height: 1.0.h.clamp(6, 12)),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(AppStrings.close),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

// Local models for dialog grouping
class _SessionItem {
  final int index;
  final String title;
  final DateTime updatedAt;
  _SessionItem({
    required this.index,
    required this.title,
    required this.updatedAt,
  });
}

class _Section {
  final String title;
  final List<_SessionItem> items;
  _Section({required this.title, required this.items});
}

enum _RowType { newChat, header, item }

class _Row {
  final _RowType type;
  final String? text;
  final _SessionItem? item;

  _Row._(this.type, {this.text, this.item});

  factory _Row.newChat() => _Row._(_RowType.newChat);
  factory _Row.header(String t) => _Row._(_RowType.header, text: t);
  factory _Row.item(_SessionItem it) => _Row._(_RowType.item, item: it);
}
