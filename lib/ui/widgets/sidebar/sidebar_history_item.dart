import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../enums/app.enum.dart';
import '../model_grid.dart';

enum _HistoryAction { rename, favorite, delete }

class SidebarHistoryItem extends StatefulWidget {
  final bool open;
  final String label;
  final List<String> logos;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;
  final VoidCallback onToggleFavorite;
  final Future<void> Function() onDelete;

  const SidebarHistoryItem({
    super.key,
    required this.open,
    required this.label,
    required this.logos,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onRename,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  State<SidebarHistoryItem> createState() => _SidebarHistoryItemState();
}

class _SidebarHistoryItemState extends State<SidebarHistoryItem> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.open) {
      Get.snackbar(
        AppStrings.renameChat,
        AppStrings.expandSidebarToRename,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
      );
      return;
    }
    setState(() {
      _editing = true;
      _controller.text = widget.label;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty && value != widget.label) widget.onRename(value);
    _cancel();
  }

  void _cancel() {
    setState(() => _editing = false);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = ModelGrid(
      logoUrls: widget.logos,
      size: widget.open ? 32 : 36,
    );
    final menu = PopupMenuButton<_HistoryAction>(
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      tooltip: AppStrings.deleteChat,
      onSelected: (action) async {
        switch (action) {
          case _HistoryAction.rename:
            _startEditing();
            break;
          case _HistoryAction.favorite:
            widget.onToggleFavorite();
            break;
          case _HistoryAction.delete:
            await widget.onDelete();
            break;
        }
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: _HistoryAction.rename,
              child: Text(AppStrings.renameChat),
            ),
            PopupMenuItem(
              value: _HistoryAction.favorite,
              child: Text(
                widget.isFavorite
                    ? AppStrings.unfavoriteChat
                    : AppStrings.favoriteChat,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: _HistoryAction.delete,
              child: Text(
                AppStrings.deleteChat,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = !widget.open || constraints.maxWidth < 140;

        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                InkWell(
                  onTap: _editing ? null : widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: avatar,
                ),
                menu,
              ],
            ),
          );
        }

        return InkWell(
          onTap: _editing ? null : widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color:
                  widget.isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 8),
                Expanded(
                  child:
                      _editing
                          ? TextField(
                            controller: _controller,
                            focusNode: _focus,
                            onSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(isDense: true),
                          )
                          : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.isFavorite)
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                            ],
                          ),
                ),
                const SizedBox(width: 4),
                if (_editing)
                  Row(
                    children: [
                      IconButton(
                        tooltip: AppStrings.cancel,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _cancel,
                      ),
                      IconButton(
                        tooltip: AppStrings.renameChat,
                        icon: const Icon(Icons.check, size: 18),
                        onPressed: _submit,
                      ),
                    ],
                  )
                else
                  menu,
              ],
            ),
          ),
        );
      },
    );
  }
}
