import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A unified smoother streaming text widget that reveals characters with animation.
/// Combines logic for both thinking (snap to end) and response (continuous stream) animations.
class SmoothStreamingText extends StatefulWidget {
  final RxString streamingText;
  final String baseContent;
  final TextStyle? style;
  final Duration charDelay;
  final RxBool? isStreamingRx;

  /// If true, immediately shows full content when isStreamingRx becomes false (used for thinking).
  /// If false, finishes animating remaining characters naturally (used for response).
  final bool snapToEndOnStop;

  const SmoothStreamingText({
    super.key,
    required this.streamingText,
    this.baseContent = '',
    this.style,
    this.charDelay = const Duration(milliseconds: 8),
    this.isStreamingRx,
    this.snapToEndOnStop = false,
  });

  @override
  State<SmoothStreamingText> createState() => _SmoothStreamingTextState();
}

class _SmoothStreamingTextState extends State<SmoothStreamingText>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  String _visibleText = '';
  Timer? _animationTimer;
  Worker? _streamWorker;
  Worker? _streamingStateWorker;

  // Track completion state mostly for snapToEnd behavior
  bool _hasCompleted = false;
  String _completedContent = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    _cursorAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    _cursorController.repeat(reverse: true);

    _initWorkers();

    // Initial state check
    final isStreaming = widget.isStreamingRx?.value ?? false;
    final initialContent = widget.baseContent + widget.streamingText.value;

    // If starting in a stopped state with output, show it immediately
    if (!isStreaming && widget.snapToEndOnStop && initialContent.isNotEmpty) {
      _visibleText = initialContent;
      _hasCompleted = true;
      _completedContent = initialContent;
    } else {
      _visibleText = widget.baseContent;
      _ensureAnimating();
    }
  }

  @override
  void didUpdateWidget(SmoothStreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the Rx references changed, (re)bind the workers
    if (widget.streamingText != oldWidget.streamingText ||
        widget.isStreamingRx != oldWidget.isStreamingRx) {
      _initWorkers();
      _ensureAnimating();
    }
  }

  void _initWorkers() {
    _streamWorker?.dispose();
    _streamingStateWorker?.dispose();

    // Watch stream updates
    _streamWorker = ever(widget.streamingText, (_) {
      if (!_hasCompleted) {
        _ensureAnimating();
      }
    });

    // Watch active state
    if (widget.isStreamingRx != null) {
      _streamingStateWorker = ever(widget.isStreamingRx!, (isActive) {
        if (!isActive) {
          if (widget.snapToEndOnStop) {
            // Thinking mode: stop immediately and show all
            if (!_hasCompleted) {
              _onSnapCompleted();
            }
          } else {
            // Response mode: just ensure we keep animating until caught up
            _ensureAnimating();
          }
        } else {
          // Reactivated (e.g. regeneration)
          if (widget.snapToEndOnStop) {
            _hasCompleted = false;
          }
          _ensureAnimating();
        }
      });
    }
  }

  void _onSnapCompleted() {
    _hasCompleted = true;
    _animationTimer?.cancel();
    _animationTimer = null;

    _completedContent = widget.baseContent + widget.streamingText.value;

    if (mounted && _visibleText != _completedContent) {
      setState(() {
        _visibleText = _completedContent;
      });
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _streamWorker?.dispose();
    _streamingStateWorker?.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  String get _currentTarget {
    if (_hasCompleted) return _completedContent;
    return widget.baseContent + widget.streamingText.value;
  }

  void _ensureAnimating() {
    if (_hasCompleted) return;
    if (_animationTimer != null && _animationTimer!.isActive) return;

    _animationTimer = Timer.periodic(widget.charDelay, (timer) {
      if (!mounted || _hasCompleted) {
        timer.cancel();
        return;
      }

      final target = _currentTarget;
      final isStreaming = widget.isStreamingRx?.value ?? false;

      if (_visibleText.length < target.length) {
        // Calculate dynamic chunk size for catch-up
        final remaining = target.length - _visibleText.length;
        // If we are way behind, speed up significantly
        final charsToAdd =
            remaining > 20 ? 4 : (remaining > 10 ? 3 : (remaining > 3 ? 2 : 1));
        final newLength = (_visibleText.length + charsToAdd).clamp(
          0,
          target.length,
        );

        setState(() {
          _visibleText = target.substring(0, newLength);
        });
      } else if (!isStreaming) {
        // If not streaming and caught up, we are done
        timer.cancel();
        _animationTimer = null;
        if (widget.snapToEndOnStop) {
          _hasCompleted = true;
          _completedContent = target;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
    final textStyle = widget.style ?? defaultStyle;

    // Static render if completed (optimization)
    if (_hasCompleted && widget.snapToEndOnStop) {
      if (_visibleText.isEmpty) return const SizedBox.shrink();
      return SelectableText(_visibleText, style: textStyle);
    }

    return Obx(() {
      final _ = widget.streamingText.value;
      final isActivelyStreaming = widget.isStreamingRx?.value ?? false;
      final target = _currentTarget;

      final showCursor =
          isActivelyStreaming || _visibleText.length < target.length;

      if (_visibleText.isEmpty && target.isEmpty) {
        if (!isActivelyStreaming) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _cursorAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _cursorAnimation.value,
              child: Container(
                width: 2.5,
                height: (textStyle?.fontSize ?? 16) * 1.3,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SelectableText(_visibleText, style: textStyle)),
          if (showCursor)
            AnimatedBuilder(
              animation: _cursorAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _cursorAnimation.value,
                  child: Container(
                    width: 2.5,
                    height: (textStyle?.fontSize ?? 16) * 1.3,
                    margin: const EdgeInsets.only(left: 1, top: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      );
    });
  }
}
