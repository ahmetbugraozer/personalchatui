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
  StreamSubscription<String>? _sub;

  // Live stream text for the last assistant message (only updates this RxString during streaming)
  final RxString streamText = ''.obs;

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
    );
    session.messages.add(userMsg);

    // Assistant placeholder to stream into (show 'düşünüyor' if reasoning mode)
    final assistantMsg = ChatMessage.assistant(
      content: thinking ? AppStrings.thinking : '',
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
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    // Optional pre-stream "thinking" pause
    if (thinking) {
      await Future.delayed(const Duration(milliseconds: 1800));

      // If canceled during the delay, clear placeholder and exit
      if (!isStreaming.value) {
        final current = session.messages[idx];
        session.messages[idx] = current.copyWith(content: '');
        return;
      }

      // Replace placeholder with empty before starting the real stream
      final current = session.messages[idx];
      session.messages[idx] = current.copyWith(content: '');
    }

    _sub = _service
        .streamCompletion(prompt: trimmed, attachments: attachments)
        .listen(
          (token) {
            // Append to live stream only (do not touch the messages list)
            streamText.value = streamText.value + token;
          },
          onError: (_) {
            // Commit whatever we have and stop
            _commitStreamToMessage(session, idx);
            _syncAllActiveBranches(session);
            isStreaming.value = false;
          },
          onDone: () {
            // Final commit in a single list update
            _commitStreamToMessage(session, idx);
            _syncAllActiveBranches(session);
            isStreaming.value = false;
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
  }

  void _commitStreamToMessage(ChatSession session, int idx) {
    if (idx < 0 || idx >= session.messages.length) {
      streamText.value = '';
      _streamMsgIndex = null;
      _streamSessionId = null;
      return;
    }
    final current = session.messages[idx];
    if (streamText.value.isEmpty && current.content == AppStrings.thinking) {
      // If we never started streaming, clear the placeholder
      session.messages[idx] = current.copyWith(content: '');
    } else if (streamText.value.isNotEmpty) {
      session.messages[idx] = current.copyWith(
        content: current.content + streamText.value,
      );
    }
    streamText.value = '';
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
    final messageIds = session.messages.map((m) => m.id).toSet();
    messageIds.add('root');

    // For each branch, if its parent is in current messages and we don't have
    // a currentBranchIndex for it, set it to 0 (the original branch)
    for (final parentId in session.branches.keys) {
      if (messageIds.contains(parentId)) {
        // Parent is visible, ensure we have an index (default to 0 if missing)
        session.currentBranchIndex.putIfAbsent(parentId, () => 0);
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

    final parentId =
        messageIndex > 0 ? session.messages[messageIndex - 1].id : 'root';

    // Get or create branches list for this fork point
    if (!session.branches.containsKey(parentId)) {
      // First time branching: save the original branch (ALL messages from messageIndex)
      final originalBranch =
          session.messages
              .sublist(messageIndex)
              .map((m) => m.copyWith())
              .toList();
      session.branches[parentId] = [originalBranch];
      session.currentBranchIndex[parentId] = 0;
    } else {
      // Save current branch state before creating new one (ALL remaining messages)
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

    // Messages to keep: everything BEFORE messageIndex (common ancestors)
    final messagesToKeep = session.messages.sublist(0, messageIndex);

    // Create new user message for the new branch
    final newBranchIndex = session.branches[parentId]!.length;
    final editedUserMsg = ChatMessage.user(
      content: trimmed,
      attachments: originalMsg.attachments,
      parentId: parentId,
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
    );

    // Create assistant placeholder
    final assistantMsg = ChatMessage.assistant(
      content: '',
      parentId: editedUserMsg.id,
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
    );

    // New branch contains only the edited user message and assistant placeholder
    final newBranch = [editedUserMsg, assistantMsg];
    session.branches[parentId]!.add(newBranch);

    // Update current branch index to the new branch
    session.currentBranchIndex[parentId] = newBranchIndex;

    // Rebuild messages list: ancestors + new branch
    session.messages.clear();
    session.messages.addAll(messagesToKeep);
    session.messages.addAll(newBranch);

    // Clean up nested branch indices that are no longer valid
    _cleanupNestedBranchIndices(session, parentId);

    session.branches.refresh();
    session.currentBranchIndex.refresh();

    session.updatedAt = DateTime.now();
    _moveCurrentToLast();

    // Ensure model history is updated
    final usedModelId = session.modelId.value;
    if (session.modelHistory.isEmpty ||
        session.modelHistory.last != usedModelId) {
      session.modelHistory.add(usedModelId);
    }

    isStreaming.value = true;
    final idx = session.messages.length - 1;

    streamText.value = '';
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    _sub = _service
        .streamCompletion(prompt: trimmed, attachments: originalMsg.attachments)
        .listen(
          (token) {
            streamText.value = streamText.value + token;
          },
          onError: (_) {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, messageIndex);
            isStreaming.value = false;
          },
          onDone: () {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, messageIndex);
            isStreaming.value = false;
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

    // The fork point is at the user message position (same as editAndResend)
    final parentId =
        userMessageIndex > 0
            ? session.messages[userMessageIndex - 1].id
            : 'root';

    // Get or create branches list for this fork point
    if (!session.branches.containsKey(parentId)) {
      // First time branching: save the original branch (ALL messages from userMessageIndex)
      final originalBranch =
          session.messages
              .sublist(userMessageIndex)
              .map((m) => m.copyWith())
              .toList();
      session.branches[parentId] = [originalBranch];
      session.currentBranchIndex[parentId] = 0;
    } else {
      // Save current branch state before creating new one
      final currentBranchIndex = session.currentBranchIndex[parentId] ?? 0;
      final branches = session.branches[parentId]!;
      if (currentBranchIndex < branches.length) {
        branches[currentBranchIndex] =
            session.messages
                .sublist(userMessageIndex)
                .map((m) => m.copyWith())
                .toList();
      }
    }

    // Messages to keep: everything BEFORE userMessageIndex (common ancestors)
    final messagesToKeep = session.messages.sublist(0, userMessageIndex);

    // Create new branch with the same user message but new assistant response
    final newBranchIndex = session.branches[parentId]!.length;

    // Copy user message with updated branch info
    final newUserMsg = userMsg.copyWith(
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
    );

    // Create new assistant placeholder
    final newAssistantMsg = ChatMessage.assistant(
      content: '',
      parentId: newUserMsg.id,
      branchIndex: newBranchIndex,
      totalBranches: newBranchIndex + 1,
    );

    // New branch contains the user message and new assistant placeholder
    final newBranch = [newUserMsg, newAssistantMsg];
    session.branches[parentId]!.add(newBranch);

    // Update current branch index to the new branch
    session.currentBranchIndex[parentId] = newBranchIndex;

    // Rebuild messages list: ancestors + new branch
    session.messages.clear();
    session.messages.addAll(messagesToKeep);
    session.messages.addAll(newBranch);

    // Clean up nested branch indices that are no longer valid
    _cleanupNestedBranchIndices(session, parentId);

    session.branches.refresh();
    session.currentBranchIndex.refresh();

    session.updatedAt = DateTime.now();

    isStreaming.value = true;
    final idx = session.messages.length - 1;

    streamText.value = '';
    _streamSessionId = session.id;
    _streamMsgIndex = idx;

    _sub = _service
        .streamCompletion(
          prompt: userMsg.content,
          attachments: userMsg.attachments,
        )
        .listen(
          (token) {
            streamText.value = streamText.value + token;
          },
          onError: (_) {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, userMessageIndex);
            isStreaming.value = false;
          },
          onDone: () {
            _commitStreamToMessage(session, idx);
            _syncCurrentBranchAfterStream(session, parentId, userMessageIndex);
            isStreaming.value = false;
          },
          cancelOnError: true,
        );
  }
}
