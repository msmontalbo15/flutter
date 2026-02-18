class Blog {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final String? imageUrl;
  final DateTime createdAt;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.imageUrl,
  });

  factory Blog.fromMap(Map<String, dynamic> map) {
    return Blog(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      authorId: map['author_id'],
      authorName: map['profiles']?['full_name'] ?? map['author_name'],
      authorAvatar: map['profiles']?['avatar_url'] ?? map['author_avatar'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
