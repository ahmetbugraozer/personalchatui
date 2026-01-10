import 'dart:async';
import 'package:get/get.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../enums/app.enum.dart';

// Simple chat session model kept in this file for convenience.
class ChatSession {
  final String id;
  final RxString title = ''.obs;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // Store all message branches: key = parentId (or "root" for first messages), value = list of branch lists
  // Each branch is a list of messages starting from that point
  final RxMap<String, List<List<ChatMessage>>> branches =
      <String, List<List<ChatMessage>>>{}.obs;

  // Current branch index per fork point
  final RxMap<String, int> currentBranchIndex = <String, int>{}.obs;

  // Timestamps
  final DateTime createdAt;
  DateTime updatedAt;

  // Selected model id per session
  final RxString modelId = AppModels.defaultModelId.obs;

  // Reactive model history (only models actually used in messages)
  final RxList<String> modelHistory = <String>[].obs;

  // Remember "thinking" toggle per session
  final RxBool thinkingEnabled = false.obs;

  ChatSession({String? id, String? initialTitle})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt = DateTime.now(),
      updatedAt = DateTime.now() {
    if (initialTitle != null) title.value = initialTitle;
    // ...no default seeding of modelHistory...
  }
}

// Lightweight reference model for gallery items
class ImageRef {
  final int sessionIndex;
  final int messageIndex;
  final Attachment attachment;
  final DateTime createdAt;
  const ImageRef({
    required this.sessionIndex,
    required this.messageIndex,
    required this.attachment,
    required this.createdAt,
  });
}

class ChatController extends GetxController {
  final RxBool isStreaming = false.obs;

  // Global upload state for UI
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // Signal to clear only attachments in composer (keep prompt)
  final RxInt attachmentClearSignal = 0.obs;

  // Sessions and active index
  final RxList<ChatSession> _sessions = <ChatSession>[].obs;
  final RxInt _current = 0.obs;

  // Expose current messages reactively
  RxList<ChatMessage> get messages => _sessions[_current.value].messages;

  // Sidebar titles (excluding empty sessions)
  List<String> get sessionTitles =>
      _sessions
          .where((s) => s.messages.isNotEmpty)
          .map((s) => s.title.value.isEmpty ? 'Yeni sohbet' : s.title.value)
          .toList();

  // Indices of non-empty sessions in chronological order (oldest -> newest)
  List<int> get nonEmptySessionIndices =>
      List<int>.generate(
        _sessions.length,
        (i) => i,
      ).where((i) => _sessions[i].messages.isNotEmpty).toList();

  // Helper indices sorted by last activity (newest -> oldest)
  List<int> get nonEmptySessionIndicesByUpdatedDesc {
    final indices = nonEmptySessionIndices;
    indices.sort(
      (a, b) => _sessions[b].updatedAt.compareTo(_sessions[a].updatedAt),
    );
    return indices;
  }

  final RxMap<int, String> _customTitles = <int, String>{}.obs;
  final RxSet<int> favoriteSessions = <int>{}.obs;

  // Title helper for a particular session index
  String titleFor(int index) {
    final override = _customTitles[index];
    if (override != null && override.isNotEmpty) return override;
    final s = _sessions[index];
    return s.title.value.isEmpty ? 'Yeni sohbet' : s.title.value;
  }

  // Expose updatedAt for grouping
  DateTime updatedAtOf(int index) => _sessions[index].updatedAt;

  bool get currentSessionEmpty => messages.isEmpty;

  // Sidebar titles (oldest->newest); UI can reverse for newest-first
  List<String> get allSessionTitles =>
      _sessions
          .map((s) => s.title.value.isEmpty ? 'Yeni sohbet' : s.title.value)
          .toList();

  int get sessionCount => _sessions.length;
  int get currentIndex => _current.value;
  RxInt get currentIndexRx => _current;

  // Signal to clear the input composer (textfield + attachments)
  final RxInt composerClearSignal = 0.obs;
  void requestComposerClear() => composerClearSignal.value++;

  final ChatService _service = ChatService();
  StreamSubscription<StreamToken>? _sub;

  // Live stream text for the last assistant message (only updates this RxString during streaming)
  final RxString streamText = ''.obs;

  // Thinking stream text (separate from response)
  final RxString thinkingText = ''.obs;

  // Whether currently in thinking phase
  final RxBool isCurrentlyThinking = false.obs;

  // Model ID used for the current streaming message
  final RxString streamingModelId = ''.obs;

  // Track which message/session is currently being streamed to (for safe commit/cancel)
  String? _streamSessionId;
  int? _streamMsgIndex;

  // Model helpers
  String get currentModelId => _sessions[_current.value].modelId.value;
  void setCurrentModel(String modelId) {
    final session = _sessions[_current.value];
    if (session.modelId.value == modelId) return;
    session.modelId.value = modelId;

    // Reset thinking toggle on any model change in the same chat
    session.thinkingEnabled.value = false;

    // If the newly selected model doesn't support files, ask UI to clear attachments
    final supportsFiles = AppModels.meta(
      modelId,
    ).caps.contains(ModelCapability.fileInputs);
    if (!supportsFiles) {
      attachmentClearSignal.value++;
    }
    // Do not add to history or touch updatedAt here.
  }

  String modelIdFor(int index) => _sessions[index].modelId.value;
  String modelLogoUrlFor(int index) =>
      AppModels.meta(_sessions[index].modelId.value).logoUrl;

  // Expose model history reactively for UI dependency
  RxList<String> modelHistoryRxFor(int index) => _sessions[index].modelHistory;

  // Unique, ordered model ids used in a session (capped)
  List<String> modelHistoryFor(int index, {int max = 4}) {
    final list = _sessions[index].modelHistory;
    final seen = <String>{};
    final uniq = <String>[];
    for (final id in list) {
      if (seen.add(id)) uniq.add(id);
      if (uniq.length >= max) break;
    }
    return uniq;
  }

  // Thinking toggle helpers for current session
  bool get currentThinkingEnabled =>
      _sessions[_current.value].thinkingEnabled.value;
  RxBool get currentThinkingEnabledRx =>
      _sessions[_current.value].thinkingEnabled;
  void setCurrentThinkingEnabled(bool v) =>
      _sessions[_current.value].thinkingEnabled.value = v;
  void toggleCurrentThinking() =>
      setCurrentThinkingEnabled(!currentThinkingEnabled);

  bool isFavorite(int index) => favoriteSessions.contains(index);

  void toggleFavorite(int index) {
    if (favoriteSessions.contains(index)) {
      favoriteSessions.remove(index);
    } else {
      favoriteSessions.add(index);
    }
    favoriteSessions.refresh();
  }

  void renameSession(int index, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      if (_customTitles.remove(index) != null) _customTitles.refresh();
      return;
    }
    _customTitles[index] = trimmed;
    _customTitles.refresh();
  }

  void deleteSession(int index) {
    if (index < 0 || index >= _sessions.length) return;
    _sessions.removeAt(index);
    _reindexSessionMetadata(index);

    if (_sessions.isEmpty) {
      _sessions.add(ChatSession());
      _current.value = 0;
      return;
    }

    final nextIndex =
        currentIndex > index
            ? currentIndex - 1
            : currentIndex.clamp(0, _sessions.length - 1);
    selectSession(nextIndex);
  }

  void _reindexSessionMetadata(int removedIndex) {
    if (_customTitles.isNotEmpty) {
      final mapped = <int, String>{};
      _customTitles.forEach((key, value) {
        if (key == removedIndex) return;
        mapped[key > removedIndex ? key - 1 : key] = value;
      });
      _customTitles
        ..clear()
        ..addAll(mapped);
      _customTitles.refresh();
    }
    if (favoriteSessions.isNotEmpty) {
      final mapped = <int>{};
      for (final idx in favoriteSessions) {
        if (idx == removedIndex) continue;
        mapped.add(idx > removedIndex ? idx - 1 : idx);
      }
      favoriteSessions
        ..clear()
        ..addAll(mapped);
      favoriteSessions.refresh();
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (_sessions.isEmpty) {
      _sessions.add(ChatSession()); // initial empty session
      _current.value = 0;
    }
  }

  // Send a user message and start assistant streaming response in current session
  Future<void> sendMessage(
    String text, {
    List<Attachment> attachments = const [],
    bool thinking = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (isStreaming.value) return;

    final session = _sessions[_current.value];

    // Ensure history records the model used for this message (after user actually sends)
    final usedModelId = session.modelId.value;
    if (session.modelHistory.isEmpty ||
        session.modelHistory.last != usedModelId) {
      session.modelHistory.add(usedModelId);
    }

    // Set session title only on first prompt in this session
    if (session.title.value.isEmpty) {
      session.title.value = _makeTitle(trimmed);
    }

    final userMsg = ChatMessage.user(
      content: trimmed,
      attachments: attachments,
      modelId: usedModelId,
    );
    session.messages.add(userMsg);

    // Assistant placeholder to stream into
    final assistantMsg = ChatMessage.assistant(
      content: '',
      modelId: usedModelId,
    );
    session.messages.add(assistantMsg);

    // Mark last activity
    session.updatedAt = DateTime.now();

    // Move current session to most recent (end of list) so it appears on top in UI
    _moveCurrentToLast();

    isStreaming.value = true;
    final idx = session.messages.length - 1;

    // Prepare live stream state
    streamText.value = '';
    thinkingText.value = '';
    isCurrentlyThinking.value = thinking;
    streamingModelId.value = usedModelId;
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    _sub = _service
        .streamCompletionWithThinking(
          prompt: trimmed,
          attachments: attachments,
          thinking: thinking,
        )
        .listen(
          (token) {
            if (token.isThinking) {
              thinkingText.value = thinkingText.value + token.text;
            } else {
              // Switch from thinking to response
              if (isCurrentlyThinking.value) {
                isCurrentlyThinking.value = false;
              }
              streamText.value = streamText.value + token.text;
            }
          },
          onError: (_) {
            _commitStreamToMessage(session, idx);
            _syncAllActiveBranches(session);
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          onDone: () {
            _commitStreamToMessage(session, idx);
            _syncAllActiveBranches(session);
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          cancelOnError: true,
        );
  }

  void cancelStream() {
    _sub?.cancel();
    _sub = null;
    // Commit partial text if we still have a target (avoid firstWhereOrNull)
    if (_streamSessionId != null && _streamMsgIndex != null) {
      final si = _sessions.indexWhere((s) => s.id == _streamSessionId);
      if (si != -1) {
        _commitStreamToMessage(_sessions[si], _streamMsgIndex!);
      }
    }
    isStreaming.value = false;
    isCurrentlyThinking.value = false;
  }

  void _commitStreamToMessage(ChatSession session, int idx) {
    if (idx < 0 || idx >= session.messages.length) {
      streamText.value = '';
      thinkingText.value = '';
      _streamMsgIndex = null;
      _streamSessionId = null;
      return;
    }
    final current = session.messages[idx];

    // Commit both thinking and response content
    final newContent = streamText.value;
    final newThinking = thinkingText.value;

    // Explicitly preserve existing thinking content if newThinking is empty
    // This ensures we don't accidentally clear it if we pass null to copyWith
    final finalThinking =
        newThinking.isNotEmpty ? newThinking : current.thinkingContent;

    session.messages[idx] = current.copyWith(
      content: current.content + newContent,
      thinkingContent: finalThinking,
    );

    streamText.value = '';
    thinkingText.value = '';
    _streamMsgIndex = null;
    _streamSessionId = null;
    session.updatedAt = DateTime.now();
  }

  // Start a brand new empty session and switch to it
  bool newChat() {
    requestComposerClear(); // clear unsent prompt when starting a new chat
    cancelStream();
    // If current session is empty, keep it (do not create another)
    if (currentSessionEmpty) return false;

    // Try to find an existing empty session and switch to it
    final existingEmptyIndex = _sessions.indexWhere((s) => s.messages.isEmpty);
    if (existingEmptyIndex != -1) {
      _current.value = existingEmptyIndex;
      return true;
    }

    // Otherwise create a single new empty session
    _sessions.add(ChatSession());
    _current.value = _sessions.length - 1;
    return true;
  }

  // Switch to an existing session by index (used by sidebar/search dialog)
  void selectSession(int index) {
    if (index < 0 || index >= _sessions.length) return;
    if (index == _current.value) return;
    requestComposerClear(); // clear unsent prompt on chat switch
    cancelStream(); // ensure no streaming continues in background
    _current.value = index;
  }

  void _moveCurrentToLast() {
    final cur = _current.value;
    if (cur != _sessions.length - 1) {
      final s = _sessions.removeAt(cur);
      _sessions.add(s);
      _current.value = _sessions.length - 1;
    }
  }

  String _makeTitle(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.isEmpty
        ? AppStrings.newChat
        : (t.length > 40 ? '${t.substring(0, 40)}…' : t);
  }

  // Collect all image attachments across sessions, newest first
  List<ImageRef> galleryImages() {
    bool isImageName(String name) {
      final n = name.toLowerCase();
      return n.endsWith('.png') ||
          n.endsWith('.jpg') ||
          n.endsWith('.jpeg') ||
          n.endsWith('.webp') ||
          n.endsWith('.gif');
    }

    final out = <ImageRef>[];
    for (var si = 0; si < _sessions.length; si++) {
      final msgs = _sessions[si].messages;
      for (var mi = 0; mi < msgs.length; mi++) {
        final m = msgs[mi];
        for (final a in m.attachments) {
          if (isImageName(a.name)) {
            // ChatMessage.id is microsecondsSinceEpoch string
            final ts = int.tryParse(m.id) ?? 0;
            out.add(
              ImageRef(
                sessionIndex: si,
                messageIndex: mi,
                attachment: a,
                createdAt: DateTime.fromMicrosecondsSinceEpoch(ts),
              ),
            );
          }
        }
      }
    }
    // Newest first
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  // Get branches at a specific message index (returns null if no branches)
  List<List<ChatMessage>>? getBranchesAt(int messageIndex) {
    final session = _sessions[_current.value];
    if (messageIndex < 0 || messageIndex >= session.messages.length) {
      return null;
    }

    // parentId is the id of the message BEFORE the fork point
    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';

    return session.branches[parentId];
  }

  // Get current branch index at a fork point
  int getCurrentBranchAt(int messageIndex) {
    final session = _sessions[_current.value];
    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';
    return session.currentBranchIndex[parentId] ?? 0;
  }

  // Get total branches at a fork point
  int getTotalBranchesAt(int messageIndex) {
    final session = _sessions[_current.value];
    // Force reactivity
    final _ = session.currentBranchIndex.length;

    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';
    final branches = session.branches[parentId];
    return branches?.length ?? 1;
  }

  // Switch to a different branch at a fork point
  void switchBranch(int messageIndex, int branchIndex) {
    final session = _sessions[_current.value];
    if (messageIndex < 0 || messageIndex >= session.messages.length) return;

    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';
    final branches = session.branches[parentId];

    if (branches == null || branchIndex < 0 || branchIndex >= branches.length) {
      return;
    }

    // Before switching, save the current state of this branch
    // Save ALL messages from this fork point to the end
    // The nested branches are stored separately and will be restored when needed
    final currentBranchIndex = session.currentBranchIndex[parentId] ?? 0;
    if (currentBranchIndex < branches.length) {
      branches[currentBranchIndex] =
          session.messages
              .sublist(messageIndex)
              .map((m) => m.copyWith())
              .toList();
    }

    // Update current branch index
    session.currentBranchIndex[parentId] = branchIndex;

    // Keep messages before the fork point (common ancestors)
    final messagesToKeep = session.messages.sublist(0, messageIndex);

    // Load the selected branch
    final selectedBranch = branches[branchIndex];

    // Clear and rebuild
    session.messages.clear();
    session.messages.addAll(messagesToKeep);
    session.messages.addAll(selectedBranch.map((m) => m.copyWith()).toList());

    // Restore nested branch indices for messages that are now in view
    _restoreNestedBranchIndices(session);

    session.currentBranchIndex.refresh();
    session.branches.refresh();
    session.messages.refresh();
  }

  // Restore branch indices for nested branches whose parent is now in the message list
  void _restoreNestedBranchIndices(ChatSession session) {
    final messageMap = {for (var m in session.messages) m.id: m};

    // Iterate over all fork points (parents that have branches)
    for (final parentId in session.branches.keys) {
      // Check if this parent is currently visible in the message list
      final isRoot = parentId == 'root';
      final isParentVisible = isRoot || messageMap.containsKey(parentId);

      if (isParentVisible) {
        // Try to find the child message immediately following this parent
        ChatMessage? child;
        if (isRoot) {
          if (session.messages.isNotEmpty) {
            child = session.messages.first;
          }
        } else {
          final parentIndex = session.messages.indexWhere(
            (m) => m.id == parentId,
          );
          if (parentIndex != -1 && parentIndex + 1 < session.messages.length) {
            child = session.messages[parentIndex + 1];
          }
        }

        // If we found a child and it belongs to this parent, use its branch index
        // This ensures the UI (< 1/2 >) matches the actual content displayed
        if (child != null && (child.parentId ?? 'root') == parentId) {
          session.currentBranchIndex[parentId] = child.branchIndex;
        } else {
          // If parent is visible but has no child (end of list),
          // ensure we have a default index (0) if none exists.
          session.currentBranchIndex.putIfAbsent(parentId, () => 0);
        }
      }
    }
  }

  // Remove branch indices for branches whose parent is not in current message list
  void _cleanupNestedBranchIndices(
    ChatSession session,
    String switchedParentId,
  ) {
    final messageIds = session.messages.map((m) => m.id).toSet();
    messageIds.add('root'); // root is always valid

    final keysToRemove = <String>[];
    for (final parentId in session.currentBranchIndex.keys) {
      // Don't remove the one we just switched
      if (parentId == switchedParentId) continue;
      // If the parent message is not in current messages, remove this index
      if (!messageIds.contains(parentId)) {
        keysToRemove.add(parentId);
      }
    }
    for (final key in keysToRemove) {
      session.currentBranchIndex.remove(key);
    }
  }

  // Edit and resend a user message, creating a new branch
  Future<void> editAndResend(int messageIndex, String newContent) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return;
    if (isStreaming.value) return;

    final session = _sessions[_current.value];
    if (messageIndex < 0 || messageIndex >= session.messages.length) return;

    final originalMsg = session.messages[messageIndex];
    if (originalMsg.role != ChatRole.user) return;

    // Check if the original assistant response (if exists) had thinking content
    bool originalHadThinking = false;
    if (messageIndex + 1 < session.messages.length) {
      final originalAssistant = session.messages[messageIndex + 1];
      if (originalAssistant.role == ChatRole.assistant) {
        originalHadThinking =
            originalAssistant.thinkingContent != null &&
            originalAssistant.thinkingContent!.isNotEmpty;
      }
    }
    final useThinking = originalHadThinking || session.thinkingEnabled.value;

    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';

    // Get or create branches list for this fork point
    if (!session.branches.containsKey(parentId)) {
      final originalBranch =
          session.messages
              .sublist(messageIndex)
              .map((m) => m.copyWith())
              .toList();
      session.branches[parentId] = [originalBranch];
      session.currentBranchIndex[parentId] = 0;
    } else {
      final currentBranchIndex = session.currentBranchIndex[parentId] ?? 0;
      final branches = session.branches[parentId]!;
      if (currentBranchIndex < branches.length) {
        branches[currentBranchIndex] =
            session.messages
                .sublist(messageIndex)
                .map((m) => m.copyWith())
                .toList();
      }
    }

    final messagesToKeep = session.messages.sublist(0, messageIndex);
    final newBranchIndex = session.branches[parentId]!.length;

    // Use the model from the original message if available, otherwise current session model
    final usedModelId = originalMsg.modelId ?? session.modelId.value;

    final editedUserMsg = ChatMessage.user(
      content: trimmed,
      attachments: originalMsg.attachments,
      parentId: parentId,
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
      modelId: usedModelId,
    );

    final assistantMsg = ChatMessage.assistant(
      content: '',
      parentId: editedUserMsg.id,
      branchIndex:
          0, // Fixed: First response to a new prompt is always branch 0
      totalBranches: 1,
      modelId: usedModelId,
    );

    final newBranch = [editedUserMsg, assistantMsg];
    session.branches[parentId]!.add(newBranch);
    session.currentBranchIndex[parentId] = newBranchIndex;

    session.messages.clear();
    session.messages.addAll(messagesToKeep);
    session.messages.addAll(newBranch);

    // Restore nested branch indices for messages that are now in view
    _restoreNestedBranchIndices(session);

    session.branches.refresh();
    session.currentBranchIndex.refresh();

    session.updatedAt = DateTime.now();
    _moveCurrentToLast();

    if (session.modelHistory.isEmpty ||
        session.modelHistory.last != usedModelId) {
      session.modelHistory.add(usedModelId);
    }

    isStreaming.value = true;
    final idx = session.messages.length - 1;

    streamText.value = '';
    thinkingText.value = '';
    isCurrentlyThinking.value = useThinking;
    streamingModelId.value = usedModelId;
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    _sub = _service
        .streamCompletionWithThinking(
          prompt: trimmed,
          attachments: originalMsg.attachments,
          thinking: useThinking,
        )
        .listen(
          (token) {
            if (token.isThinking) {
              thinkingText.value = thinkingText.value + token.text;
            } else {
              if (isCurrentlyThinking.value) {
                isCurrentlyThinking.value = false;
              }
              streamText.value = streamText.value + token.text;
            }
          },
          onError: (_) {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, messageIndex);
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          onDone: () {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, messageIndex);
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          cancelOnError: true,
        );
  }

  // Sync the current branch after streaming (save all messages from fork point)
  void _syncCurrentBranchAfterStream(
    ChatSession session,
    String parentId,
    int forkIndex,
  ) {
    final branchIndex = session.currentBranchIndex[parentId] ?? 0;
    final branches = session.branches[parentId];
    if (branches == null || branchIndex >= branches.length) return;

    if (forkIndex < session.messages.length) {
      branches[branchIndex] =
          session.messages.sublist(forkIndex).map((m) => m.copyWith()).toList();
      session.branches.refresh();
    }
  }

  // Optimize _syncAllActiveBranches - only call when necessary
  void _syncAllActiveBranches(ChatSession session) {
    if (session.currentBranchIndex.isEmpty) return;

    String? deepestParentId;
    int deepestForkIndex = -1;

    for (final entry in session.currentBranchIndex.entries) {
      final parentId = entry.key;
      final branches = session.branches[parentId];
      if (branches == null) continue;

      int forkIndex = 0;
      if (parentId != 'root') {
        final parentMsgIndex = session.messages.indexWhere(
          (m) => m.id == parentId,
        );
        if (parentMsgIndex == -1) continue;
        forkIndex = parentMsgIndex + 1;
      }

      if (forkIndex > deepestForkIndex) {
        deepestForkIndex = forkIndex;
        deepestParentId = parentId;
      }
    }

    if (deepestParentId != null &&
        deepestForkIndex >= 0 &&
        deepestForkIndex < session.messages.length) {
      final branchIndex = session.currentBranchIndex[deepestParentId] ?? 0;
      final branches = session.branches[deepestParentId];
      if (branches != null && branchIndex < branches.length) {
        branches[branchIndex] =
            session.messages
                .sublist(deepestForkIndex)
                .map((m) => m.copyWith())
                .toList();
        // Only refresh branches, not messages (they're already updated)
        session.branches.refresh();
      }
    }
  }

  // Regenerate assistant response for a user message, creating a new branch
  Future<void> regenerateResponse(int assistantMessageIndex) async {
    if (isStreaming.value) return;

    final session = _sessions[_current.value];
    if (assistantMessageIndex < 1 ||
        assistantMessageIndex >= session.messages.length) {
      return;
    }

    final assistantMsg = session.messages[assistantMessageIndex];
    if (assistantMsg.role != ChatRole.assistant) return;

    // Find the user message before this assistant message
    final userMessageIndex = assistantMessageIndex - 1;
    final userMsg = session.messages[userMessageIndex];
    if (userMsg.role != ChatRole.user) return;

    // Determine if thinking mode should be used:
    // 1. If the original message had thinking content, use thinking mode
    // 2. Or if the session currently has thinking enabled
    final originalHadThinking =
        assistantMsg.thinkingContent != null &&
        assistantMsg.thinkingContent!.isNotEmpty;
    final useThinking = originalHadThinking || session.thinkingEnabled.value;

    // The fork point is at the user message (we are branching the response, not the prompt)
    final parentId = userMsg.id;

    // Get or create branches list for this fork point
    if (!session.branches.containsKey(parentId)) {
      final originalBranch =
          session.messages
              .sublist(assistantMessageIndex)
              .map((m) => m.copyWith())
              .toList();

      // Ensure the first message of the original branch has index 0
      if (originalBranch.isNotEmpty &&
          originalBranch.first.parentId == parentId) {
        originalBranch[0] = originalBranch[0].copyWith(branchIndex: 0);
      }

      session.branches[parentId] = [originalBranch];
      session.currentBranchIndex[parentId] = 0;
    } else {
      final currentBranchIndex = session.currentBranchIndex[parentId] ?? 0;
      final branches = session.branches[parentId]!;
      if (currentBranchIndex < branches.length) {
        branches[currentBranchIndex] =
            session.messages
                .sublist(assistantMessageIndex)
                .map((m) => m.copyWith())
                .toList();
      }
    }

    final messagesToKeep = session.messages.sublist(0, assistantMessageIndex);
    final newBranchIndex = session.branches[parentId]!.length;

    // Use the model that generated the original message, or fallback to current if missing
    final usedModelId = assistantMsg.modelId ?? session.modelId.value;

    // Create only the new assistant message (user message remains common ancestor)
    final newAssistantMsg = ChatMessage.assistant(
      content: '',
      parentId: parentId,
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
      modelId: usedModelId,
      thinkingContent: null,
    );

    final newBranch = [newAssistantMsg];
    session.branches[parentId]!.add(newBranch);
    session.currentBranchIndex[parentId] = newBranchIndex;

    session.messages.clear();
    session.messages.addAll(messagesToKeep);
    session.messages.addAll(newBranch);

    _cleanupNestedBranchIndices(session, parentId);

    session.branches.refresh();
    session.currentBranchIndex.refresh();

    session.updatedAt = DateTime.now();

    // Ensure history records the model used for this message
    if (session.modelHistory.isEmpty ||
        session.modelHistory.last != usedModelId) {
      session.modelHistory.add(usedModelId);
    }

    isStreaming.value = true;
    final idx = session.messages.length - 1;

    streamText.value = '';
    thinkingText.value = '';
    isCurrentlyThinking.value = useThinking;
    streamingModelId.value = usedModelId;
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    _sub = _service
        .streamCompletionWithThinking(
          prompt: userMsg.content,
          attachments: userMsg.attachments,
          thinking: useThinking,
        )
        .listen(
          (token) {
            if (token.isThinking) {
              thinkingText.value = thinkingText.value + token.text;
            } else {
              if (isCurrentlyThinking.value) {
                isCurrentlyThinking.value = false;
              }
              streamText.value = streamText.value + token.text;
            }
          },
          onError: (_) {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(
              session,
              parentId,
              assistantMessageIndex,
            );
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          onDone: () {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(
              session,
              parentId,
              assistantMessageIndex,
            );
            isStreaming.value = false;
            isCurrentlyThinking.value = false;
          },
          cancelOnError: true,
        );
  }
}
