import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/sizer/app_sizer.dart';
import '../../enums/app.enum.dart';

class ThinkingSection extends StatefulWidget {
  final RxString thinkingText;
  final RxBool isThinking;

  const ThinkingSection({
    super.key,
    required this.thinkingText,
    required this.isThinking,
  });

  @override
  State<ThinkingSection> createState() => _ThinkingSectionState();
}

class _ThinkingSectionState extends State<ThinkingSection>
    with SingleTickerProviderStateMixin {
  final RxBool _isExpanded = false.obs;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: 1.0.cw(context).clamp(8.0, 12.0),
      vertical: 0.6.ch(context).clamp(4.0, 8.0),
    );

    return Obx(() {
      final isThinking = widget.isThinking.value;
      final isExpanded = _isExpanded.value;
      final thinkingContent = widget.thinkingText.value;

      // Determine button label
      final label = isThinking ? AppStrings.thinking : AppStrings.thinkingPhase;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thinking button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _isExpanded.value = !_isExpanded.value,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: buttonPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated label (pulses when thinking)
                    if (isThinking)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: child,
                          );
                        },
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    SizedBox(width: 0.4.cw(context).clamp(4.0, 8.0)),

                    // Chevron icon (rotates when expanded)
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 1.6.csp(context).clamp(16.0, 22.0),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded thinking content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildThinkingContent(context, theme, thinkingContent),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      );
    });
  }

  Widget _buildThinkingContent(
    BuildContext context,
    ThemeData theme,
    String content,
  ) {
    final contentPadding = 1.2.cw(context).clamp(10.0, 16.0);
    final borderColor = theme.dividerColor;

    return Container(
      margin: EdgeInsets.only(
        top: 0.6.ch(context).clamp(4.0, 8.0),
        left: contentPadding,
      ),
      padding: EdgeInsets.all(contentPadding),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 2)),
      ),
      child:
          content.isEmpty
              ? Obx(() {
                // Show pulsing dots when no content yet
                if (widget.isThinking.value) {
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: Text(
                          '...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              })
              : SelectableText(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
    );
  }
}
