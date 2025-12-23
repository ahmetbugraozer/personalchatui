import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../enums/app.enum.dart';
import '../../../models/chat_message.dart';
import 'thinking_section.dart';

class ResponseSection extends StatelessWidget {
  final ChatMessage message;
  final int messageIndex;
  final RxString? streamingText;
  final RxString? thinkingText;
  final RxBool? isThinking;
  final String modelId;

  const ResponseSection({
    super.key,
    required this.message,
    required this.messageIndex,
    this.streamingText,
    this.thinkingText,
    this.isThinking,
    required this.modelId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = AppModels.meta(modelId);
    final logoSize = 3.2.ch(context).clamp(28.0, 40.0);
    final contentPadding = 1.2.cw(context).clamp(10.0, 16.0);

    // Check if we should show thinking section
    final showThinking = thinkingText != null && isThinking != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model logo
        Padding(
          padding: EdgeInsets.only(bottom: 3.0.ch(context).clamp(12.0, 21.0)),
          child: SvgPicture.asset(
            meta.logoUrl,
            width: logoSize,
            height: logoSize,
            placeholderBuilder:
                (_) => SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
          ),
        ),

        // Thinking section (only if thinking was enabled)
        if (showThinking)
          Padding(
            padding: EdgeInsets.only(bottom: 0.8.ch(context).clamp(6.0, 12.0)),
            child: ThinkingSection(
              thinkingText: thinkingText!,
              isThinking: isThinking!,
            ),
          ),

        // Response content
        Padding(
          padding: EdgeInsets.only(
            bottom: contentPadding,
            left: contentPadding,
          ),
          child: _buildContent(context, theme),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (streamingText != null) {
      return Obx(() {
        final text = message.content + streamingText!.value;
        if (text.isEmpty) {
          return const SizedBox.shrink();
        }
        return SelectableText(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        );
      });
    }

    if (message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return SelectableText(
      message.content,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
    );
  }
}
