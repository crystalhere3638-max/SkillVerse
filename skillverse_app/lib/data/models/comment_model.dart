import 'package:cloud_firestore/cloud_firestore.dart';

/// A single comment or reply on a post. Replies are just comments
/// with a non-null [parentId] pointing at the comment they reply to —
/// one flat list, one level of nesting, kept simple on purpose.
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorLevel;
  final String text;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String? parentId;

  const Comment({
    required this.id,
    required this.postId,
    this.authorId = '',
    required this.authorName,
    required this.authorLevel,
    required this.text,
    required this.createdAt,
    this.editedAt,
    this.parentId,
  });

  bool get isReply => parentId != null;
  bool get isEdited => editedAt != null;

  Comment copyWith({String? text, DateTime? editedAt}) {
    return Comment(
      id: id,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorLevel: authorLevel,
      text: text ?? this.text,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      parentId: parentId,
    );
  }

  factory Comment.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    final editedAtRaw = data['editedAt'];
    return Comment(
      id: id,
      postId: data['postId'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      authorLevel: data['authorLevel'] as String? ?? 'Lv.1',
      text: data['text'] as String? ?? '',
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : DateTime.now(),
      editedAt: editedAtRaw is Timestamp ? editedAtRaw.toDate() : null,
      parentId: data['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorLevel': authorLevel,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'editedAt': editedAt?.toIso8601String(),
        'parentId': parentId,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        authorId: json['authorId'] as String? ?? '',
        authorName: json['authorName'] as String,
        authorLevel: (json['authorLevel'] as String?) ?? 'Lv.1',
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
        parentId: json['parentId'] as String?,
      );
}
