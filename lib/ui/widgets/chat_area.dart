import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
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
  bool _scrollScheduled = false;

  @override
  void initState() {
    super.initState();
    _chat = Get.find<ChatController>();

    void bindMessagesWorker() {
      _messagesWorker?.dispose();
      _messagesWorker = ever<List<ChatMessage>>(_chat.messages, (list) {
        _scrollToBottom();
        if (list.isEmpty) {
          _resetAndStartPlaceholder();
        } else {
          _stopPlaceholder();
        }
      });
    }

    bindMessagesWorker();

    ever<int>(_chat.currentIndexRx, (_) {
      bindMessagesWorker();
      _scrollToBottom();
      if (_chat.messages.isEmpty) {
        _resetAndStartPlaceholder();
      } else {
        _stopPlaceholder();
      }
    });

    ever<bool>(_chat.isStreaming, (_) => _scrollToBottom());

    // Start initial placeholder typing if empty
    if (_chat.messages.isEmpty) {
      _resetAndStartPlaceholder();
    }
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _stopPlaceholder();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Schedule to the next frame, but avoid stacking multiple schedules.
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted) return;
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent + 120;
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
    _placeholderTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
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
      top: false, // top padding is handled by HomePage
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
                child: LayoutBuilder(
                  builder: (context, c) {
                    // Stable paddings derived from available width (do not depend on theme)
                    double hp(double ratio, double min, double max) {
                      final v = c.maxWidth * ratio;
                      return v.clamp(min, max);
                    }

                    final placeholderPad = hp(0.02, 16, 32);
                    final listHPad = hp(0.03, 12, 36);
                    final hPad =
                        listHPad; // same horizontal padding as list/input
                    return Obx(() {
                      final items = _chat.messages;
                      if (items.isEmpty) {
                        // Centered placeholder + input (ChatGPT-like)
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(placeholderPad),
                              child: Text(
                                _placeholderShown.isEmpty
                                    ? ' '
                                    : _placeholderShown,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            SizedBox(height: 2.0.h.clamp(12, 28)),
                            // Input centered under the placeholder
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.maxContentWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const InputBar(),
                                    // Global upload progress under input
                                    Obx(() {
                                      final uploading = _chat.isUploading.value;
                                      if (!uploading) {
                                        return const SizedBox.shrink();
                                      }
                                      final progress =
                                          _chat.uploadProgress.value;
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
                              ),
                            ),
                          ],
                        );
                      }
                      // Messages list + (bottom input rendered below)
                      return ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.symmetric(
                          horizontal: listHPad,
                          vertical: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder:
                            (context, index) =>
                                MessageBubble(message: items[index]),
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
                      2.2.h.clamp(10, 24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const InputBar(),
                        // Global upload progress under input
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
      ),
    );
  }
}
