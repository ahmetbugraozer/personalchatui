import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/chat_message.dart';
import '../../enums/app.enum.dart';
import '../../controllers/chat_controller.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final int messageIndex;
  // Live text override for streaming (only provided for the last assistant bubble)
  final RxString? streamingText;

  const MessageBubble({
    super.key,
    required this.message,
    required this.messageIndex,
    this.streamingText,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // Use ValueNotifier for hover to avoid full widget rebuild
  final _hovering = ValueNotifier<bool>(false);
  bool _editing = false;
  bool _liked = false;
  bool _disliked = false;
  final _editController = TextEditingController();
  final _editFocus = FocusNode();

  @override
  void dispose() {
    _hovering.dispose();
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _editController.text = widget.message.content;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocus.requestFocus();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
    });
    _editFocus.unfocus();
  }

  void _submitEdit() {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == widget.message.content) {
      _cancelEdit();
      return;
    }

    final chat = Get.find<ChatController>();
    chat.editAndResend(widget.messageIndex, newContent);

    setState(() {
      _editing = false;
    });
    _editFocus.unfocus();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    Get.snackbar(
      AppStrings.copyMessage,
      AppStrings.copiedToClipboard,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      if (_liked) _disliked = false;
    });
  }

  void _toggleDislike() {
    setState(() {
      _disliked = !_disliked;
      if (_disliked) _liked = false;
    });
  }

  void _regenerate() {
    final chat = Get.find<ChatController>();
    // Pass the assistant message index for regeneration
    chat.regenerateResponse(widget.messageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == ChatRole.user;
    final theme = Theme.of(context);
    final chat = Get.find<ChatController>();
    final bg =
        isUser
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.cardColor;
    final fg =
        isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.textTheme.bodyMedium?.color;

    return MouseRegion(
      onEnter: (_) => _hovering.value = true,
      onExit: (_) => _hovering.value = false,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    margin: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: isUser ? 40 : 8,
                      right: isUser ? 8 : 40,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyLarge!.copyWith(color: fg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message.attachments.isNotEmpty && isUser)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    widget.message.attachments
                                        .map(
                                          (a) => Chip(
                                            label: Text(a.name),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          if (_editing)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _editController,
                                  focusNode: _editFocus,
                                  minLines: 1,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submitEdit(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: AppStrings.cancel,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: _cancelEdit,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: AppStrings.editMessage,
                                      icon: Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: _submitEdit,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else if (widget.streamingText != null)
                            Obx(() {
                              final live = widget.streamingText!.value;
                              final showThinking =
                                  !isUser &&
                                  widget.message.content.trim() ==
                                      AppStrings.thinking &&
                                  live.isEmpty;
                              if (showThinking) {
                                return _ThinkingPulse(
                                  text: AppStrings.thinking,
                                  color:
                                      theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.6) ??
                                      Colors.grey,
                                );
                              }
                              return Text(live.isEmpty ? '' : live);
                            })
                          else
                            Builder(
                              builder: (_) {
                                final isThinking =
                                    !isUser &&
                                    widget.message.content.trim() ==
                                        AppStrings.thinking;
                                if (isThinking) {
                                  return _ThinkingPulse(
                                    text: AppStrings.thinking,
                                    color:
                                        theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.6) ??
                                        Colors.grey,
                                  );
                                }
                                return Text(widget.message.content);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Use ValueListenableBuilder for hover actions
                  if (isUser && !_editing)
                    ValueListenableBuilder<bool>(
                      valueListenable: _hovering,
                      builder: (context, hovering, _) {
                        if (!hovering) return const SizedBox.shrink();
                        return Positioned(
                          bottom: -6,
                          right: 8,
                          child: _ActionBar(
                            theme: theme,
                            children: [
                              _ActionButton(
                                tooltip: AppTooltips.editMessage,
                                icon: Icons.edit_outlined,
                                onTap: _startEdit,
                              ),
                              _ActionButton(
                                tooltip: AppTooltips.copyMessage,
                                icon: Icons.copy_outlined,
                                onTap: _copyToClipboard,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (!isUser && widget.streamingText == null)
                    ValueListenableBuilder<bool>(
                      valueListenable: _hovering,
                      builder: (context, hovering, _) {
                        if (!hovering) return const SizedBox.shrink();
                        return Positioned(
                          bottom: -6,
                          left: 8,
                          child: _ActionBar(
                            theme: theme,
                            children: [
                              _ActionButton(
                                tooltip: AppTooltips.likeMessage,
                                icon:
                                    _liked
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                onTap: _toggleLike,
                                isActive: _liked,
                              ),
                              _ActionButton(
                                tooltip: AppTooltips.dislikeMessage,
                                icon:
                                    _disliked
                                        ? Icons.thumb_down
                                        : Icons.thumb_down_outlined,
                                onTap: _toggleDislike,
                                isActive: _disliked,
                              ),
                              _ActionButton(
                                tooltip: AppTooltips.copyMessage,
                                icon: Icons.copy_outlined,
                                onTap: _copyToClipboard,
                              ),
                              _ActionButton(
                                tooltip: AppTooltips.regenerateMessage,
                                icon: Icons.refresh_rounded,
                                onTap: _regenerate,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              // Branch navigator - show below user message if branches exist
              if (isUser)
                Obx(() {
                  // Force reactivity by accessing the session's branch data
                  final _ = chat.messages.length; // triggers on message changes
                  final totalBranches = chat.getTotalBranchesAt(
                    widget.messageIndex,
                  );
                  if (totalBranches <= 1) return const SizedBox.shrink();

                  final currentBranch = chat.getCurrentBranchAt(
                    widget.messageIndex,
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      right: isUser ? 8 : 0,
                      left: isUser ? 0 : 8,
                      bottom: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Previous branch button
                        InkWell(
                          onTap:
                              currentBranch > 0
                                  ? () {
                                    chat.switchBranch(
                                      widget.messageIndex,
                                      currentBranch - 1,
                                    );
                                  }
                                  : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color:
                                  currentBranch > 0
                                      ? theme.iconTheme.color
                                      : theme.disabledColor,
                            ),
                          ),
                        ),
                        // Branch indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${currentBranch + 1}/$totalBranches',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        // Next branch button
                        InkWell(
                          onTap:
                              currentBranch < totalBranches - 1
                                  ? () {
                                    chat.switchBranch(
                                      widget.messageIndex,
                                      currentBranch + 1,
                                    );
                                  }
                                  : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color:
                                  currentBranch < totalBranches - 1
                                      ? theme.iconTheme.color
                                      : theme.disabledColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable action bar container
class _ActionBar extends StatelessWidget {
  final ThemeData theme;
  final List<Widget> children;

  const _ActionBar({required this.theme, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              children.expand((w) => [w, const SizedBox(width: 2)]).toList()
                ..removeLast(),
        ),
      ),
    );
  }
}

// Reusable action button
class _ActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? theme.colorScheme.primary : theme.iconTheme.color,
          ),
        ),
      ),
    );
  }
}

// Pulsing opacity for "thinking"
class _ThinkingPulse extends StatefulWidget {
  final String text;
  final Color color;
  const _ThinkingPulse({required this.text, required this.color});

  @override
  State<_ThinkingPulse> createState() => _ThinkingPulseState();
}

class _ThinkingPulseState extends State<_ThinkingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Text(
        widget.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.color,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
