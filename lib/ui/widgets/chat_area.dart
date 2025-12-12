import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/sizer/app_sizer.dart';
import 'dart:async';

import '../../controllers/chat_controller.dart';
import '../../enums/app.enum.dart';
import '../../models/chat_message.dart';
import 'input_bar.dart';
import 'message_bubble.dart';

class ChatArea extends StatefulWidget {
  final double maxContentWidth;

  const ChatArea({super.key, this.maxContentWidth = 1100});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final _scroll = ScrollController();
  late final ChatController _chat;
  String _placeholder = AppStrings.randomHomePlaceholder();
  String _placeholderShown = '';
  Timer? _placeholderTimer;
  Worker? _messagesWorker;
  Worker? _sessionWorker;
  Worker? _streamWorker;
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _chat = Get.find<ChatController>();

    void bindMessagesWorker() {
      _messagesWorker?.dispose();
      _messagesWorker = ever<List<ChatMessage>>(_chat.messages, (list) {
        _scrollToBottom(); // animate only on list changes
        if (list.isEmpty) {
          _resetAndStartPlaceholder();
        } else {
          _stopPlaceholder();
        }
      });
    }

    bindMessagesWorker();

    _sessionWorker = ever<int>(_chat.currentIndexRx, (_) {
      if (!mounted) return;
      bindMessagesWorker();
      _scrollToBottom();
      if (_chat.messages.isEmpty) {
        _resetAndStartPlaceholder();
      } else {
        _stopPlaceholder();
      }
    });

    _streamWorker = ever<String>(_chat.streamText, (_) {
      if (!mounted) return;
      _scrollToBottom(duringStream: true);
    });

    // Start initial placeholder typing if empty
    if (_chat.messages.isEmpty) {
      _resetAndStartPlaceholder();
    }
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _sessionWorker?.dispose();
    _streamWorker?.dispose();
    _stopPlaceholder();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool duringStream = false}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      final target = max + 120;

      if (duringStream) {
        // Keep the bottom sticky during rapid updates without janky re-animations
        // Only jump if we are close to the bottom already.
        final nearBottom = (max - _scroll.position.pixels) < 200;
        if (nearBottom) {
          _scroll.jumpTo(max);
        }
        return;
      }

      // Animate only on structural changes
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _resetAndStartPlaceholder() {
    _stopPlaceholder();
    setState(() {
      _placeholder = AppStrings.randomHomePlaceholder();
      _placeholderShown = '';
    });
    // Slightly slower ticking to reduce rebuild pressure
    _placeholderTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (!mounted) return;
      if (_placeholderShown.length >= _placeholder.length) {
        _stopPlaceholder();
        return;
      }
      setState(() {
        _placeholderShown = _placeholder.substring(
          0,
          _placeholderShown.length + 1,
        );
      });
    });
  }

  void _stopPlaceholder() {
    _placeholderTimer?.cancel();
    _placeholderTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if screen is very short - need at least ~250px for minimal UI
          final isVeryShort = constraints.maxHeight < 250;
          final isExtremelyShort = constraints.maxHeight < 150;

          // For extremely short screens, show only the input bar in a scroll view
          if (isExtremelyShort) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.03,
                  vertical: 8,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                  child: const InputBar(),
                ),
              ),
            );
          }

          // Normal layout with Column
          return Column(
            children: [
              // Title - hide when very short
              if (!isVeryShort)
                Obx(() {
                  final isEmpty = _chat.messages.isEmpty;
                  final title =
                      isEmpty
                          ? AppStrings.appTitle
                          : _chat.titleFor(_chat.currentIndex);
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 0.8.ch(context).clamp(6.0, 12.0),
                      bottom: 0.6.ch(context).clamp(4.0, 10.0),
                    ),
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.maxContentWidth,
                    ),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        double hp(double ratio, double min, double max) {
                          final v = c.maxWidth * ratio;
                          return v.clamp(min, max);
                        }

                        final placeholderPad = hp(0.02, 16, 32);
                        final listHPad = hp(0.03, 12, 36);
                        final hPad = listHPad;

                        return Obx(() {
                          final items = _chat.messages;
                          if (items.isEmpty) {
                            // Empty state - always scrollable
                            return SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isVeryShort ? 4 : 0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isVeryShort)
                                      Padding(
                                        padding: EdgeInsets.all(placeholderPad),
                                        child: Text(
                                          _placeholderShown.isEmpty
                                              ? ' '
                                              : _placeholderShown,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontSize: 36,
                                                color: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ),
                                    SizedBox(
                                      height:
                                          isVeryShort ? 4 : 2.0.h.clamp(12, 28),
                                    ),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: widget.maxContentWidth,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: hPad,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const InputBar(),
                                            Obx(() {
                                              final uploading =
                                                  _chat.isUploading.value;
                                              if (!uploading) {
                                                return const SizedBox.shrink();
                                              }
                                              final progress =
                                                  _chat.uploadProgress.value;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: LinearProgressIndicator(
                                                  value:
                                                      progress > 0 &&
                                                              progress < 1
                                                          ? progress
                                                          : null,
                                                  minHeight: 4,
                                                  backgroundColor:
                                                      theme.dividerColor,
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          // Messages list
                          return ListView.builder(
                            controller: _scroll,
                            padding: EdgeInsets.symmetric(
                              horizontal: listHPad,
                              vertical: 16,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final msg = items[index];
                              final isLast = index == items.length - 1;
                              final isAssistant =
                                  msg.role == ChatRole.assistant;
                              final useStream =
                                  isLast &&
                                  _chat.isStreaming.value &&
                                  isAssistant;
                              return MessageBubble(
                                message: msg,
                                messageIndex: index,
                                streamingText:
                                    useStream ? _chat.streamText : null,
                              );
                            },
                          );
                        });
                      },
                    ),
                  ),
                ),
              ),
              // Bottom input only when there are messages
              Obx(() {
                final hasMessages = _chat.messages.isNotEmpty;
                if (!hasMessages) return const SizedBox.shrink();
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      double hp(double ratio, double min, double max) {
                        final v = c.maxWidth * ratio;
                        return v.clamp(min, max);
                      }

                      final hPad = hp(0.03, 12, 36);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          hPad,
                          0,
                          hPad,
                          isVeryShort ? 2 : 2.2.h.clamp(10, 24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const InputBar(),
                            Obx(() {
                              final uploading = _chat.isUploading.value;
                              if (!uploading) return const SizedBox.shrink();
                              final progress = _chat.uploadProgress.value;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(
                                  value:
                                      progress > 0 && progress < 1
                                          ? progress
                                          : null,
                                  minHeight: 4,
                                  backgroundColor: theme.dividerColor,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
