class Comment {
  final String id;
  final String blogId;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final String content;
  final List<String> imageUrls; // Changed from single imageUrl to list
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.blogId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    List<String>? imageUrls,
  }) : imageUrls = imageUrls ?? [];

  // For backward compatibility
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory Comment.fromMap(Map<String, dynamic> map) {
    // Handle both old single image_url and new image_urls array
    List<String> images = [];
    if (map['image_urls'] != null && map['image_urls'] is List) {
      images = (map['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (map['image_url'] != null) {
      images = [map['image_url']];
    }

    return Comment(
      id: map['id'],
      blogId: map['blog_id'],
      authorId: map['author_id'],
      authorName: map['profiles']?['full_name'] ?? map['author_name'],
      authorAvatar: map['profiles']?['avatar_url'] ?? map['author_avatar'],
      content: map['content'],
      imageUrls: images,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
