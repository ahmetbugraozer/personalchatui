import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/chat_message.dart';
import '../../enums/app.enum.dart'; // New

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  // Live text override for streaming (only provided for the last assistant bubble)
  final RxString? streamingText;

  const MessageBubble({super.key, required this.message, this.streamingText});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final theme = Theme.of(context);
    final bg =
        isUser
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.cardColor;
    final fg =
        isUser
            ? theme.colorScheme.onPrimaryContainer
            : theme.textTheme.bodyMedium?.color;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                if (message.attachments.isNotEmpty && isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          message.attachments
                              .map(
                                (a) => Chip(
                                  label: Text(a.name),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                if (streamingText != null)
                  // Only this bubble rebuilds on each token
                  Obx(() {
                    final live = streamingText!.value;
                    final showThinking =
                        !isUser &&
                        message.content.trim() == AppStrings.thinking &&
                        live.isEmpty;
                    if (showThinking) {
                      return _ThinkingPulse(
                        text: AppStrings.thinking,
                        color:
                            theme.textTheme.bodyMedium?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            Colors.grey,
                      );
                    }
                    return Text(live.isEmpty ? '' : live);
                  })
                else
                  // Static bubble
                  Builder(
                    builder: (_) {
                      final isThinking =
                          !isUser &&
                          message.content.trim() == AppStrings.thinking;
                      if (isThinking) {
                        return _ThinkingPulse(
                          text: AppStrings.thinking,
                          color:
                              theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.6,
                              ) ??
                              Colors.grey,
                        );
                      }
                      return Text(message.content);
                    },
                  ),
              ],
            ),
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
