class Blog {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int commentCount;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    List<String>? imageUrls,
    this.commentCount = 0,
  }) : imageUrls = imageUrls ?? [];

  // For backward compatibility
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  /// Copy this blog with a specific comment count
  factory Blog.withCommentCount(Blog blog, int count) {
    return Blog(
      id: blog.id,
      title: blog.title,
      content: blog.content,
      authorId: blog.authorId,
      createdAt: blog.createdAt,
      authorName: blog.authorName,
      authorAvatar: blog.authorAvatar,
      imageUrls: blog.imageUrls,
      commentCount: count,
    );
  }

  factory Blog.fromMap(Map<String, dynamic> map) {
    // Handle both old single image_url and new image_urls array
    List<String> images = [];
    if (map['image_urls'] != null && map['image_urls'] is List) {
      images = (map['image_urls'] as List).map((e) => e.toString()).toList();
    } else if (map['image_url'] != null) {
      images = [map['image_url']];
    }

    return Blog(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      authorId: map['author_id'],
      authorName: map['profiles']?['full_name'] ?? map['author_name'],
      authorAvatar: map['profiles']?['avatar_url'] ?? map['author_avatar'],
      imageUrls: images,
      createdAt: DateTime.parse(map['created_at']),
      commentCount: (map['comment_count'] as int?) ?? 0,
    );
  }
}
