import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_selector/file_selector.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/sizer/app_sizer.dart';
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

  // GetX Workers - use late final for proper initialization
  late final Worker _clearWorker;
  late final Worker _clearAttachmentsWorker;

  bool _dropping = false;

  @override
  void initState() {
    super.initState();
    _chat = Get.find<ChatController>();
    _controller.addListener(_onTextChanged);

    // Initialize workers
    _clearWorker = ever<int>(_chat.composerClearSignal, _onComposerClear);
    _clearAttachmentsWorker = ever<int>(
      _chat.attachmentClearSignal,
      _onAttachmentClear,
    );
  }

  void _onTextChanged() {
    final v = _controller.text.trim().isNotEmpty;
    if (v != _hasText) setState(() => _hasText = v);
  }

  void _onComposerClear(int _) {
    if (_controller.text.isNotEmpty || _attachments.isNotEmpty) {
      _cancelAllUploads();
      _controller.clear();
      _attachments.clear();
      _chat.isUploading.value = false;
      _chat.uploadProgress.value = 0.0;
      setState(() => _hasText = false);
    }
  }

  void _onAttachmentClear(int _) {
    if (_attachments.isNotEmpty) {
      _cancelAllUploads();
      _attachments.clear();
      _dropping = false;
      _chat.isUploading.value = false;
      _chat.uploadProgress.value = 0.0;
      setState(() {});
    } else {
      if (_dropping) setState(() => _dropping = false);
    }
  }

  void _cancelAllUploads() {
    for (final t in _uploadTimers.values) {
      t.cancel();
    }
    _uploadTimers.clear();
  }

  @override
  void dispose() {
    _cancelAllUploads();
    _clearWorker.dispose();
    _clearAttachmentsWorker.dispose();
    _controller.removeListener(_onTextChanged);
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
    _cancelAllUploads();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Sizer-based dimensions
        final containerPadding = 1.6.ch(context).clamp(12.0, 18.0);
        final textFieldVPad = 0.6.ch(context).clamp(8.0, 14.0);
        final blockSpacing = 1.0.ch(context).clamp(8.0, 14.0);
        final modelLabelGap = 0.8.cw(context).clamp(6.0, 10.0);
        final dividerGap = 1.4.cw(context).clamp(10.0, 18.0);
        final thinkGap = 1.0.cw(context).clamp(8.0, 14.0);
        final thinkPadVert = 0.8.ch(context).clamp(8.0, 12.0);
        final thinkPadNarrow = 1.0.cw(context).clamp(8.0, 14.0);
        final thinkPadWide = 1.6.cw(context).clamp(12.0, 18.0);

        final double chipSpacing = 0.6.cw(context).clamp(4.0, 6.0);
        final double chipRunSpacing = 0.6.ch(context).clamp(4.0, 6.0);
        final double chipBottomPad = 0.8.ch(context).clamp(6.0, 8.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Add this to prevent expansion
          children: [
            if (_attachments.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: chipBottomPad),
                child: Wrap(
                  spacing: chipSpacing,
                  runSpacing: chipRunSpacing,
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
                                      value:
                                          a.progress == 0 ? null : a.progress,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : null,
                          label: Text(a.name),
                          onDeleted: () {
                            _uploadTimers[a.id]?.cancel();
                            _uploadTimers.remove(a.id);
                            _attachments.removeAt(e.key);
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
              final caps = model.caps;
              final supportsReasoning = caps.contains(
                ModelCapability.reasoning,
              );
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

              final thinkingEnabled = _chat.currentThinkingEnabledRx.value;
              final bool isThinkingActive =
                  supportsReasoning && thinkingEnabled;

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
                padding: EdgeInsets.all(containerPadding),
                child: Stack(
                  children: [
                    // Core composer content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prompt TextField - make it flexible
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: Focus(
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.enter) {
                                final isShift =
                                    HardwareKeyboard.instance.isShiftPressed;
                                if (!isShift) {
                                  if (canSend) {
                                    _onSend();
                                    return KeyEventResult.handled;
                                  }
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
                                  vertical: textFieldVPad,
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
                        ),
                        SizedBox(height: blockSpacing),
                        // Tools row - wrap in SingleChildScrollView for very narrow/short screens
                        LayoutBuilder(
                          builder: (ctx, cons) {
                            final bool isNarrow = cons.maxWidth < 700;
                            final bool isVeryNarrow = cons.maxWidth < 400;

                            final double fixedItemsWidth = 200.0;
                            final double safeWidth = (cons.maxWidth -
                                    fixedItemsWidth)
                                .clamp(0.0, 320.0);

                            final double desired =
                                isNarrow
                                    ? (cons.maxWidth * 0.50).clamp(100.0, 240.0)
                                    : 320.0;

                            final double btnMax =
                                desired > safeWidth ? safeWidth : desired;

                            final double btnPadH =
                                isNarrow
                                    ? 1.0.cw(context).clamp(8.0, 10.0)
                                    : 1.6.cw(context).clamp(10.0, 12.0);

                            final double btnPadV = 0.6
                                .ch(context)
                                .clamp(4.0, 8.0);

                            // For very narrow screens, use a more compact layout
                            if (isVeryNarrow) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildToolsRow(
                                  theme: theme,
                                  streaming: streaming,
                                  model: model,
                                  supportsReasoning: supportsReasoning,
                                  supportsFiles: supportsFiles,
                                  supportsAudio: supportsAudio,
                                  fileTooltip: fileTooltip,
                                  micTooltip: micTooltip,
                                  thinkTooltip: thinkTooltip,
                                  isThinkingActive: isThinkingActive,
                                  canSend: canSend,
                                  isNarrow: true,
                                  btnMax: btnMax,
                                  btnPadH: btnPadH,
                                  btnPadV: btnPadV,
                                  modelLabelGap: modelLabelGap,
                                  dividerGap: dividerGap,
                                  thinkGap: thinkGap,
                                  thinkPadVert: thinkPadVert,
                                  thinkPadNarrow: thinkPadNarrow,
                                  thinkPadWide: thinkPadWide,
                                ),
                              );
                            }

                            return _buildToolsRow(
                              theme: theme,
                              streaming: streaming,
                              model: model,
                              supportsReasoning: supportsReasoning,
                              supportsFiles: supportsFiles,
                              supportsAudio: supportsAudio,
                              fileTooltip: fileTooltip,
                              micTooltip: micTooltip,
                              thinkTooltip: thinkTooltip,
                              isThinkingActive: isThinkingActive,
                              canSend: canSend,
                              isNarrow: isNarrow,
                              btnMax: btnMax,
                              btnPadH: btnPadH,
                              btnPadV: btnPadV,
                              modelLabelGap: modelLabelGap,
                              dividerGap: dividerGap,
                              thinkGap: thinkGap,
                              thinkPadVert: thinkPadVert,
                              thinkPadNarrow: thinkPadNarrow,
                              thinkPadWide: thinkPadWide,
                            );
                          },
                        ),
                      ],
                    ),
                    // Drop overlay
                    if (supportsFiles)
                      Positioned.fill(
                        child: DropOverlay(
                          onHover: () => setState(() => _dropping = true),
                          onLeave: () {
                            if (!_attachments.any((a) => a.uploading)) {
                              setState(() => _dropping = false);
                            }
                          },
                          onDrop: _handleDropNames,
                        ),
                      ),
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
      },
    );
  }

  Widget _buildToolsRow({
    required ThemeData theme,
    required bool streaming,
    required ModelMeta model,
    required bool supportsReasoning,
    required bool supportsFiles,
    required bool supportsAudio,
    required String fileTooltip,
    required String micTooltip,
    required String thinkTooltip,
    required bool isThinkingActive,
    required bool canSend,
    required bool isNarrow,
    required double btnMax,
    required double btnPadH,
    required double btnPadV,
    required double modelLabelGap,
    required double dividerGap,
    required double thinkGap,
    required double thinkPadVert,
    required double thinkPadNarrow,
    required double thinkPadWide,
  }) {
    return Row(
      children: [
        // Model selector button
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
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: SvgPicture.asset(
                      model.logoUrl,
                      key: ValueKey(model.logoUrl),
                      fit: BoxFit.contain,
                      placeholderBuilder:
                          (_) => const Icon(Icons.auto_awesome, size: 16),
                    ),
                  ),
                ),
                SizedBox(width: modelLabelGap),
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
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
        SizedBox(width: dividerGap),
        // Divider
        Container(width: 1, height: 24, color: theme.dividerColor),
        SizedBox(width: dividerGap),
        // File Attachment
        Tooltip(
          message: fileTooltip,
          child: IconButton(
            onPressed: (streaming || !supportsFiles) ? null : _addAttachment,
            icon: const Icon(Icons.attach_file_rounded),
          ),
        ),
        // Mic
        Tooltip(
          message: micTooltip,
          child: IconButton(
            onPressed: (streaming || !supportsAudio) ? null : () {},
            icon: const Icon(Icons.mic_none_rounded),
          ),
        ),
        const Spacer(),
        if (!streaming) ...[
          // Think button
          if (isNarrow)
            Tooltip(
              message: thinkTooltip,
              child: FilledButton(
                onPressed:
                    supportsReasoning ? _chat.toggleCurrentThinking : null,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: thinkPadNarrow,
                    vertical: thinkPadVert,
                  ),
                  backgroundColor:
                      isThinkingActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                  foregroundColor:
                      isThinkingActive
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(40, 36),
                ),
                child: const Icon(Icons.psychology_rounded, size: 18),
              ),
            )
          else
            Tooltip(
              message: thinkTooltip,
              child: FilledButton.icon(
                onPressed:
                    supportsReasoning ? _chat.toggleCurrentThinking : null,
                icon: const Icon(Icons.psychology_rounded, size: 18),
                label: const Text(AppStrings.reasoningText),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: thinkPadWide,
                    vertical: thinkPadVert,
                  ),
                  backgroundColor:
                      isThinkingActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
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
          SizedBox(width: thinkGap),
          // Send button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: AppTooltips.send,
              onPressed: canSend ? _onSend : null,
              icon: Icon(
                Icons.send_rounded,
                color:
                    canSend ? theme.colorScheme.primary : theme.disabledColor,
              ),
            ),
          ),
        ] else ...[
          // Stop button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
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
  }
}
