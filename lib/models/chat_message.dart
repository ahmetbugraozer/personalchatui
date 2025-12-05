enum ChatRole { user, assistant }

// Removed AttachmentType; all attachments are generic files now.

class Attachment {
  final String id; // unique per selected file
  final String name;
  final String? path; // may be null on web
  final bool uploading;
  final double progress; // 0..1

  const Attachment({
    required this.id,
    required this.name,
    this.path,
    this.uploading = false,
    this.progress = 1.0,
  });

  Attachment copyWith({
    String? id,
    String? name,
    String? path,
    bool? uploading,
    double? progress,
  }) {
    return Attachment(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      uploading: uploading ?? this.uploading,
      progress: progress ?? this.progress,
    );
  }
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final List<Attachment> attachments;

  // Branch support: messages can have multiple branches after edits
  final String?
  parentId; // id of message this branches from (null for root messages)
  final int branchIndex; // which branch this message belongs to (0 = original)
  final int totalBranches; // total number of branches at this point

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.attachments = const [],
    this.parentId,
    this.branchIndex = 0,
    this.totalBranches = 1,
  });

  factory ChatMessage.user({
    required String content,
    List<Attachment> attachments = const [],
    String? parentId,
    int branchIndex = 0,
    int totalBranches = 1,
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    role: ChatRole.user,
    content: content,
    attachments: attachments,
    parentId: parentId,
    branchIndex: branchIndex,
    totalBranches: totalBranches,
  );

  factory ChatMessage.assistant({
    required String content,
    String? parentId,
    int branchIndex = 0,
    int totalBranches = 1,
  }) => ChatMessage(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    role: ChatRole.assistant,
    content: content,
    parentId: parentId,
    branchIndex: branchIndex,
    totalBranches: totalBranches,
  );

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    List<Attachment>? attachments,
    String? parentId,
    int? branchIndex,
    int? totalBranches,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      parentId: parentId ?? this.parentId,
      branchIndex: branchIndex ?? this.branchIndex,
      totalBranches: totalBranches ?? this.totalBranches,
    );
  }
}
