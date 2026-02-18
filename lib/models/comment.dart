class Comment {
  final String id;
  final String blogId;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.blogId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.imageUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      blogId: map['blog_id'],
      authorId: map['author_id'],
      authorName: map['profiles']?['full_name'] ?? map['author_name'],
      authorAvatar: map['profiles']?['avatar_url'] ?? map['author_avatar'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
