import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/sizer/app_sizer.dart';
import '../../../enums/app.enum.dart';
import 'smooth_streaming_text.dart';

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
    with TickerProviderStateMixin {
  final RxBool _isExpanded = false.obs;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // New controller for vertical expansion
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Expand animation setup
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    _isExpanded.value = !_isExpanded.value;
    if (_isExpanded.value) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
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

      final label = isThinking ? AppStrings.thinking : AppStrings.thinkingPhase;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thinking button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpand,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: buttonPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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

          // Expanded thinking content with vertical SizeTransition
          // This avoids the "dragging text" artifact of CrossFade
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0, // Expand from top
            child: _buildThinkingContent(context, theme),
          ),
        ],
      );
    });
  }

  Widget _buildThinkingContent(BuildContext context, ThemeData theme) {
    final contentPadding = 1.2.cw(context).clamp(10.0, 16.0);
    final borderColor = theme.dividerColor;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
      height: 1.5,
      fontStyle: FontStyle.italic,
    );

    return Container(
      margin: EdgeInsets.only(
        top: 0.6.ch(context).clamp(4.0, 8.0),
        left: contentPadding,
      ),
      padding: EdgeInsets.all(contentPadding),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 2)),
      ),
      child: SmoothStreamingText(
        streamingText: widget.thinkingText,
        isStreamingRx: widget.isThinking,
        style: textStyle,
        charDelay: const Duration(milliseconds: 6),
        snapToEndOnStop: true,
      ),
    );
  }
}
