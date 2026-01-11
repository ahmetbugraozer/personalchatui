import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../enums/app.enum.dart';
import '../../../models/chat_message.dart';
import '../../../controllers/chat_controller.dart';
import 'smooth_streaming_text.dart';
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

    final showThinking = thinkingText != null && isThinking != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model logo
        Padding(
          padding: EdgeInsets.only(bottom: 3.0.ch(context).clamp(12.0, 21.0)),
          child: _buildModelLogo(context, theme, meta.logoUrl, logoSize),
        ),

        // Thinking section
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

  Widget _buildModelLogo(
    BuildContext context,
    ThemeData theme,
    String logoUrl,
    double size,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        logoUrl,
        width: size,
        height: size,
        placeholderBuilder: (_) => _buildLogoPlaceholder(theme, size),
      ),
    );
  }

  Widget _buildLogoPlaceholder(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_outlined,
        size: size * 0.6,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
    final chat = Get.find<ChatController>();

    if (streamingText != null) {
      return SmoothStreamingText(
        key: ValueKey('response_anim_${message.id}'),
        streamingText: streamingText!,
        baseContent: message.content,
        style: textStyle,
        charDelay: const Duration(milliseconds: 6),
        isStreamingRx: chat.isStreaming,
        snapToEndOnStop: false, // Natural finish for response
      );
    }

    if (message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    return SelectableText(message.content, style: textStyle);
  }
}
