import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart';
import '../../controllers/chat_controller.dart';
import '../../enums/app.enum.dart';
import '../../models/chat_message.dart';
import '../dialogs/select_model_dialog.dart';
import 'content_dropzone.dart';
import 'drop_overlay.dart';

class InputBar extends StatefulWidget {
  const InputBar({super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  final List<Attachment> _attachments = [];
  final Map<String, Timer> _uploadTimers = {};
  late final ChatController _chat;
  Worker? _clearWorker;

  // Listen to attachment-only clear requests (model change)
  Worker? _clearAttachmentsWorker;
  bool _dropping = false;

  @override
  void initState() {
    super.initState();
    _chat = Get.find<ChatController>();
    _controller.addListener(() {
      final v = _controller.text.trim().isNotEmpty;
      if (v != _hasText) setState(() => _hasText = v);
    });
    _clearWorker = ever<int>(_chat.composerClearSignal, (_) {
      if (_controller.text.isNotEmpty || _attachments.isNotEmpty) {
        // Cancel all pending uploads
        for (final t in _uploadTimers.values) {
          t.cancel();
        }
        _uploadTimers.clear();
        _controller.clear();
        _attachments.clear();

        // Reset global upload state
        _chat.isUploading.value = false;
        _chat.uploadProgress.value = 0.0;
        setState(() {
          _hasText = false;
        });
      }
    });

    // Clear only attachments when model doesn't support files (keep prompt)
    _clearAttachmentsWorker = ever<int>(_chat.attachmentClearSignal, (_) {
      if (_attachments.isNotEmpty) {
        for (final t in _uploadTimers.values) {
          t.cancel();
        }
        _uploadTimers.clear();
        _attachments.clear();
        // Hide drop overlay and reset global upload state
        _dropping = false;
        _chat.isUploading.value = false;
        _chat.uploadProgress.value = 0.0;
        setState(() {});
      } else {
        // Still ensure overlay hidden even if no attachments yet
        if (_dropping) setState(() => _dropping = false);
      }
    });
  }

  @override
  void dispose() {
    // Cancel timers
    for (final t in _uploadTimers.values) {
      t.cancel();
    }
    _uploadTimers.clear();
    _clearWorker?.dispose();
    // New
    _clearAttachmentsWorker?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSend() {
    // Block send while attachments are uploading
    if (_attachments.any((a) => a.uploading)) return;
    if (_controller.text.trim().isEmpty) return;
    if (_chat.isStreaming.value) return; // one stream at a time
    FocusScope.of(context).unfocus();

    // Only allow thinking if current model supports reasoning
    final supportsReasoning = AppModels.meta(
      _chat.currentModelId,
    ).caps.contains(ModelCapability.reasoning);
    final thinkingEnabled = _chat.currentThinkingEnabledRx.value;
    _chat.sendMessage(
      _controller.text.trim(),
      attachments: List.of(_attachments),
      thinking: thinkingEnabled && supportsReasoning, // gate by capability
    );

    // Do not keep timers/attachments after sending
    for (final t in _uploadTimers.values) {
      t.cancel();
    }
    _uploadTimers.clear();
    _controller.clear();
    _attachments.clear();
    // Reset global upload state
    _chat.isUploading.value = false;
    _chat.uploadProgress.value = 0.0;
    setState(() {});
  }

  // Aggregate upload progress and publish to controller
  void _updateAggregateUpload() {
    final uploading = _attachments.where((a) => a.uploading).toList();
    if (uploading.isEmpty) {
      _chat.isUploading.value = false;
      _chat.uploadProgress.value = 0.0;
      return;
    }
    final avg =
        uploading.fold<double>(0.0, (s, a) => s + a.progress) /
        uploading.length;
    _chat.isUploading.value = true;
    _chat.uploadProgress.value = avg.clamp(0.0, 1.0);
  }

  // File picker + simulated upload with progress
  Future<void> _addAttachment() async {
    try {
      final files = await openFiles(acceptedTypeGroups: const []); // allow any
      if (files.isEmpty) return;
      for (final x in files) {
        final id = '${DateTime.now().microsecondsSinceEpoch}_${x.name}';
        final att = Attachment(
          id: id,
          name: x.name,

          // On web, XFile.path is not available/useful; keep null
          path: kIsWeb || (x.path.isEmpty) ? null : x.path,
          uploading: true,
          progress: 0.0,
        );
        _attachments.add(att);

        // Mark uploading
        _updateAggregateUpload();
        setState(() {});
        _startSimulatedUpload(att.id);
      }
    } on PlatformException {
      // ignore silently; could show a snackbar if desired
    }
  }

  void _startSimulatedUpload(String id) {
    // 1.2s - 2.4s simulated upload
    const tick = Duration(milliseconds: 120);
    _uploadTimers[id]?.cancel();
    _uploadTimers[id] = Timer.periodic(tick, (t) {
      final idx = _attachments.indexWhere((a) => a.id == id);
      if (idx == -1) {
        t.cancel();
        _uploadTimers.remove(id);
        _updateAggregateUpload();
        return;
      }
      final a = _attachments[idx];
      final next = (a.progress + 0.1).clamp(0.0, 1.0);
      _attachments[idx] = a.copyWith(progress: next, uploading: next < 1.0);

      // Update global aggregate each tick
      _updateAggregateUpload();
      if (next >= 1.0) {
        t.cancel();
        _uploadTimers.remove(id);
        // Hide dropzone overlay when uploads are in progress or done
        if (!_attachments.any((a) => a.uploading)) {
          if (mounted) setState(() => _dropping = false);
        }
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickModel() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => const SelectModelDialog(),
    );
    if (id != null && id.isNotEmpty) {
      _chat.setCurrentModel(id);
      setState(() {}); // refresh local button label
    }
  }

  // Handle dropped file names from DropOverlay
  void _handleDropNames(List<String> names) {
    // Disallow drop if current model doesn't support files
    final supportsFiles = AppModels.meta(
      _chat.currentModelId,
    ).caps.contains(ModelCapability.fileInputs);
    if (!supportsFiles) {
      setState(() => _dropping = false);
      return;
    }
    if (_chat.isStreaming.value) {
      setState(() => _dropping = false);
      return;
    }
    // Close overlay immediately so user can keep typing while upload runs
    setState(() => _dropping = false);
    for (final name in names) {
      final id = '${DateTime.now().microsecondsSinceEpoch}_$name';
      final att = Attachment(
        id: id,
        name: name,
        path: null, // web-safe
        uploading: true,
        progress: 0.0,
      );
      _attachments.add(att);
      _startSimulatedUpload(att.id);
    }
    // Mark uploading after adding all
    _updateAggregateUpload();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  _attachments.asMap().entries.map((e) {
                    final a = e.value;
                    return InputChip(
                      avatar:
                          a.uploading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  value: a.progress == 0 ? null : a.progress,
                                  strokeWidth: 2,
                                ),
                              )
                              : null,
                      label: Text(a.name),
                      onDeleted: () {
                        // Cancel timer if any
                        _uploadTimers[a.id]?.cancel();
                        _uploadTimers.remove(a.id);
                        _attachments.removeAt(e.key);

                        // Update global
                        _updateAggregateUpload();
                        setState(() {});
                      },
                    );
                  }).toList(),
            ),
          ),
        Obx(() {
          final streaming = _chat.isStreaming.value;
          final model = AppModels.meta(_chat.currentModelId);
          // Capability flags for buttons
          final caps = model.caps;
          final supportsReasoning = caps.contains(ModelCapability.reasoning);
          final supportsFiles = caps.contains(ModelCapability.fileInputs);
          final supportsAudio = caps.contains(ModelCapability.audioInputs);
          final fileTooltip =
              supportsFiles
                  ? AppTooltips.attachFile
                  : AppTooltips.notSupportedFile;
          final micTooltip =
              supportsAudio ? AppTooltips.mic : AppTooltips.notSupportedMic;
          final thinkTooltip =
              supportsReasoning
                  ? AppTooltips.supportedThink
                  : AppTooltips.notSupportedThink;

          // Visual state follows effective thinking capability (from controller)
          final thinkingEnabled = _chat.currentThinkingEnabledRx.value;
          final bool isThinkingActive = supportsReasoning && thinkingEnabled;

          // Centralized send availability
          final bool anyUploading = _attachments.any((a) => a.uploading);
          final bool canSend = !streaming && !anyUploading && _hasText;

          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(1.6.h.clamp(12, 18)),
            child: Stack(
              children: [
                // Core composer content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prompt TextField (no border)
                    Focus(
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          final isShift =
                              HardwareKeyboard.instance.isShiftPressed;
                          if (!isShift) {
                            if (canSend) {
                              _onSend();
                              return KeyEventResult.handled; // prevent newline
                            }
                            // If cannot send (uploading), allow newline
                            return KeyEventResult.ignored;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: AppStrings.inputHint,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 0.6.h.clamp(8, 14),
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        onSubmitted: (_) {
                          if (canSend) _onSend();
                        }, // for soft keyboards
                      ),
                    ),
                    SizedBox(height: 1.0.h.clamp(8, 14)),
                    // Tools row (narrow-aware)
                    LayoutBuilder(
                      builder: (ctx, cons) {
                        final bool isNarrow = cons.maxWidth < 700;
                        final double btnMax =
                            isNarrow
                                ? (cons.maxWidth * 0.50).clamp(140.0, 240.0)
                                : 320.0;
                        final double btnPadH = (isNarrow ? 1.0.w : 1.6.w).clamp(
                          8,
                          12,
                        );
                        final double btnPadV = 0.6.h.clamp(4, 8);

                        return Row(
                          children: [
                            // Model selector button (wraps content, capped by maxWidth)
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: btnMax),
                              child: OutlinedButton(
                                onPressed: _pickModel,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: btnPadH,
                                    vertical: btnPadV,
                                  ),
                                  side: BorderSide(color: theme.dividerColor),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Image.asset(
                                        model.logoUrl, // normalized asset path
                                        key: ValueKey(model.logoUrl),
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.auto_awesome,
                                              size: 16,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 0.8.w.clamp(6, 10)),
                                    // Label flexes inside max width, otherwise wraps to content
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Text(
                                        model.name,
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 1.4.w.clamp(10, 18)),
                            // Divider
                            Container(
                              width: 1,
                              height: 24,
                              color: theme.dividerColor,
                            ),
                            SizedBox(width: 1.4.w.clamp(10, 18)),
                            // File Attachment
                            Tooltip(
                              message: fileTooltip,
                              child: IconButton(
                                onPressed:
                                    (streaming || !supportsFiles)
                                        ? null
                                        : _addAttachment,
                                icon: const Icon(Icons.attach_file_rounded),
                              ),
                            ),
                            // Mic
                            Tooltip(
                              message: micTooltip,
                              child: IconButton(
                                onPressed:
                                    (streaming || !supportsAudio)
                                        ? null
                                        : () {},
                                icon: const Icon(Icons.mic_none_rounded),
                              ),
                            ),
                            const Spacer(),
                            if (!streaming) ...[
                              // Think: icon-only in narrow, labeled in wide
                              if (isNarrow)
                                Tooltip(
                                  message: thinkTooltip,
                                  child: FilledButton(
                                    onPressed:
                                        supportsReasoning
                                            ? () =>
                                                _chat
                                                    .toggleCurrentThinking() // New
                                            : null,
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 1.0.w.clamp(8, 14),
                                        vertical: 0.8.h.clamp(8, 12),
                                      ),
                                      // Color reflects only when supported
                                      backgroundColor:
                                          isThinkingActive
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                      foregroundColor:
                                          isThinkingActive
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      minimumSize: const Size(40, 36),
                                    ),
                                    child: const Icon(
                                      Icons.psychology_rounded,
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                Tooltip(
                                  message: thinkTooltip,
                                  child: FilledButton.icon(
                                    onPressed:
                                        supportsReasoning
                                            ? () =>
                                                _chat
                                                    .toggleCurrentThinking() // New
                                            : null,
                                    icon: const Icon(
                                      Icons.psychology_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Mantık yürüt'),
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 1.6.w.clamp(12, 18),
                                        vertical: 0.8.h.clamp(8, 12),
                                      ),
                                      // Color reflects only when supported
                                      backgroundColor:
                                          isThinkingActive
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                      foregroundColor:
                                          isThinkingActive
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(width: 1.0.w.clamp(8, 14)),
                              // Send button in a soft container
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  tooltip: AppTooltips.send,
                                  onPressed: canSend ? _onSend : null,
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color:
                                        canSend
                                            ? theme.colorScheme.primary
                                            : theme.disabledColor,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Streaming: same container, icon-only stop
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  tooltip: AppTooltips.stop,
                                  onPressed: _chat.cancelStream,
                                  icon: Icon(
                                    Icons.stop_circle_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
                // Full-size overlay that captures drag/drop only when files are supported
                if (supportsFiles)
                  Positioned.fill(
                    child: DropOverlay(
                      onHover: () => setState(() => _dropping = true),
                      onLeave: () {
                        // If still uploading keep overlay, otherwise hide
                        if (!_attachments.any((a) => a.uploading)) {
                          setState(() => _dropping = false);
                        }
                      },
                      onDrop: _handleDropNames,
                    ),
                  ),
                // Visual overlay with dashed border and info (only when supported)
                if (supportsFiles && _dropping)
                  Positioned.fill(
                    child: ContentDropzone(
                      uploading: _attachments.any((a) => a.uploading),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
