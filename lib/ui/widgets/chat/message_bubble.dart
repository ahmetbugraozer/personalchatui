import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../controllers/chat_controller.dart';
import '../../../enums/app.enum.dart';
import '../../../models/chat_message.dart';
import 'response_section.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final int messageIndex;
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
  final _isHovered = false.obs;
  final _isEditing = false.obs;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = Get.find<ChatController>();
    final isUser = widget.message.role == ChatRole.user;

    if (isUser) {
      return _buildUserMessage(context, theme, chat);
    } else {
      return _buildAssistantMessage(context, theme, chat);
    }
  }

  Widget _buildUserMessage(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    final bubblePad = EdgeInsets.symmetric(
      horizontal: 1.6.cw(context).clamp(12.0, 20.0),
      vertical: 1.0.ch(context).clamp(8.0, 14.0),
    );
    final bubbleRadius = 1.8.cw(context).clamp(12.0, 18.0);

    // Fixed height for actions to prevent layout shift
    final actionsHeight = 2.4.ch(context).clamp(32.0, 40.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.ch(context).clamp(8.0, 16.0)),
      child: MouseRegion(
        onEnter: (_) => _isHovered.value = true,
        onExit: (_) => _isHovered.value = false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // User bubble
            Container(
              padding: bubblePad,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(bubbleRadius),
              ),
              child: Obx(() {
                if (_isEditing.value) {
                  return _buildEditField(context, theme, chat);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attachments
                    if (widget.message.attachments.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: 0.6.ch(context).clamp(4.0, 8.0),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              widget.message.attachments
                                  .map(
                                    (a) => Chip(
                                      label: Text(
                                        a.name,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      avatar: const Icon(
                                        Icons.attach_file_rounded,
                                        size: 14,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    SelectableText(
                      widget.message.content,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                );
              }),
            ),
            // Actions below the bubble - fixed height container
            SizedBox(
              height: actionsHeight,
              child: Obx(() {
                final showActions = _isHovered.value && !_isEditing.value;
                return AnimatedOpacity(
                  opacity: showActions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child:
                      showActions
                          ? Align(
                            alignment: Alignment.centerRight,
                            child: _buildUserActions(context, theme, chat),
                          )
                          : const SizedBox.shrink(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    final isLast = widget.messageIndex == chat.messages.length - 1;
    final isStreaming = chat.isStreaming.value && isLast;

    // Determine which model generated this response
    final modelId =
        widget.message.modelId ??
        (chat.streamingModelId.value.isNotEmpty
            ? chat.streamingModelId.value
            : chat.currentModelId);

    // Check if thinking mode was used for this message
    final hasThinkingContent =
        widget.message.thinkingContent != null &&
        widget.message.thinkingContent!.isNotEmpty;
    final isCurrentlyThinking = isStreaming && chat.isCurrentlyThinking.value;
    final hasStreamingThinking =
        isStreaming && chat.thinkingText.value.isNotEmpty;

    // Only show thinking section if there's actual thinking content
    final showThinking =
        hasThinkingContent || isCurrentlyThinking || hasStreamingThinking;

    // Fixed height for actions to prevent layout shift
    final actionsHeight = 2.4.ch(context).clamp(32.0, 40.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.6.ch(context).clamp(12.0, 20.0)),
      child: MouseRegion(
        onEnter: (_) => _isHovered.value = true,
        onExit: (_) => _isHovered.value = false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Response content
            ResponseSection(
              message: widget.message,
              messageIndex: widget.messageIndex,
              streamingText: isStreaming ? widget.streamingText : null,
              thinkingText:
                  showThinking
                      ? (isStreaming
                          ? chat.thinkingText
                          : RxString(widget.message.thinkingContent ?? ''))
                      : null,
              isThinking:
                  showThinking
                      ? (isStreaming ? chat.isCurrentlyThinking : false.obs)
                      : null,
              modelId: modelId,
            ),

            // Actions row - fixed height container to prevent layout shift
            SizedBox(
              height: actionsHeight,
              child: Obx(() {
                final showActions = _isHovered.value && !isStreaming;
                return AnimatedOpacity(
                  opacity: showActions ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child:
                      showActions
                          ? _buildAssistantActions(context, theme, chat)
                          : const SizedBox.shrink(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActions(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    final iconSize = 1.4.csp(context).clamp(16.0, 20.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Branch navigation
        _buildBranchNav(context, theme, chat),
        // Edit button
        IconButton(
          tooltip: AppTooltips.editMessage,
          icon: Icon(Icons.edit_outlined, size: iconSize),
          onPressed: () {
            _editController.text = widget.message.content;
            _isEditing.value = true;
          },
          visualDensity: VisualDensity.compact,
        ),
        // Copy button
        IconButton(
          tooltip: AppTooltips.copyMessage,
          icon: Icon(Icons.copy_rounded, size: iconSize),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            Get.snackbar(
              AppStrings.copyTitle,
              AppStrings.copiedToClipboard,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
            );
          },
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildAssistantActions(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    final iconSize = 1.4.csp(context).clamp(16.0, 20.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Branch navigation (Moved to start for assistant messages)
        _buildBranchNav(context, theme, chat),
        // Copy button
        IconButton(
          tooltip: AppTooltips.copyMessage,
          icon: Icon(Icons.copy_rounded, size: iconSize),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            Get.snackbar(
              AppStrings.copyTitle,
              AppStrings.copiedToClipboard,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
            );
          },
          visualDensity: VisualDensity.compact,
        ),
        // Like button
        IconButton(
          tooltip: AppTooltips.likeMessage,
          icon: Icon(Icons.thumb_up_outlined, size: iconSize),
          onPressed: () {
            // TODO: Implement like
          },
          visualDensity: VisualDensity.compact,
        ),
        // Dislike button
        IconButton(
          tooltip: AppTooltips.dislikeMessage,
          icon: Icon(Icons.thumb_down_outlined, size: iconSize),
          onPressed: () {
            // TODO: Implement dislike
          },
          visualDensity: VisualDensity.compact,
        ),
        // Regenerate button
        IconButton(
          tooltip: AppTooltips.regenerateMessage,
          icon: Icon(Icons.refresh_rounded, size: iconSize),
          onPressed: () => chat.regenerateResponse(widget.messageIndex),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildBranchNav(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    return Obx(() {
      final total = chat.getTotalBranchesAt(widget.messageIndex);
      if (total <= 1) return const SizedBox.shrink();

      final current = chat.getCurrentBranchAt(widget.messageIndex);
      final textStyle = theme.textTheme.bodySmall;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 18),
            onPressed:
                current > 0
                    ? () => chat.switchBranch(widget.messageIndex, current - 1)
                    : null,
            visualDensity: VisualDensity.compact,
          ),
          Text('${current + 1}/$total', style: textStyle),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
            onPressed:
                current < total - 1
                    ? () => chat.switchBranch(widget.messageIndex, current + 1)
                    : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    });
  }

  Widget _buildEditField(
    BuildContext context,
    ThemeData theme,
    ChatController chat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _editController,
          maxLines: null,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.inputHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 0.8.ch(context).clamp(6.0, 10.0)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _isEditing.value = false,
              child: Text(AppStrings.cancel),
            ),
            SizedBox(width: 0.8.cw(context).clamp(6.0, 10.0)),
            FilledButton(
              onPressed: () {
                final newText = _editController.text.trim();
                if (newText.isNotEmpty && newText != widget.message.content) {
                  chat.editAndResend(widget.messageIndex, newText);
                }
                _isEditing.value = false;
              },
              child: Text(AppStrings.continueAction),
            ),
          ],
        ),
      ],
    );
  }
}
