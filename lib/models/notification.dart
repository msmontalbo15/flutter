class AppNotification {
  final String id;
  final String recipientId;  // blog owner
  final String blogId;
  final String blogTitle;
  final String commentId;
  final String commenterName;
  final String? commenterAvatar;
  final String commentPreview;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.blogId,
    required this.blogTitle,
    required this.commentId,
    required this.commenterName,
    this.commenterAvatar,
    required this.commentPreview,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        recipientId: recipientId,
        blogId: blogId,
        blogTitle: blogTitle,
        commentId: commentId,
        commenterName: commenterName,
        commenterAvatar: commenterAvatar,
        commentPreview: commentPreview,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      recipientId: map['recipient_id'],
      blogId: map['blog_id'],
      blogTitle: map['blog_title'] ?? '',
      commentId: map['comment_id'],
      commenterName: map['commenter_name'] ?? 'Someone',
      commenterAvatar: map['commenter_avatar'],
      commentPreview: map['comment_preview'] ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
