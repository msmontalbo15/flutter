import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/blog.dart';

class BlogService {
  final _client = Supabase.instance.client;
  static const int limit = 5;

  /// READ - paginated with author profile joined
  Future<List<Blog>> fetchBlogs(int page) async {
    final response = await _client
        .from('blogs')
        .select('*, profiles(full_name, avatar_url)')
        .order('created_at', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return (response as List).map((map) => Blog.fromMap(map)).toList();
  }

  /// READ single blog
  Future<Blog> fetchBlog(String id) async {
    final response = await _client
        .from('blogs')
        .select('*, profiles(full_name, avatar_url)')
        .eq('id', id)
        .single();
    return Blog.fromMap(response);
  }

  /// CREATE with multiple images
  Future<void> createBlog({
    required String title,
    required String content,
    List<Uint8List>? imagesBytes, // Changed to list
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> imageUrls = [];
    if (imagesBytes != null && imagesBytes.isNotEmpty) {
      for (var imageBytes in imagesBytes) {
        final url = await _uploadImage(imageBytes, 'blog-images');
        imageUrls.add(url);
      }
    }

    await _client.from('blogs').insert({
      'title': title,
      'content': content,
      'author_id': user.id,
      'image_urls': imageUrls,
    });
  }

  /// UPDATE with multiple images
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String content,
    List<Uint8List>? newImagesBytes,
    List<String>? existingImageUrls,
  }) async {
    List<String> imageUrls = existingImageUrls ?? [];

    if (newImagesBytes != null && newImagesBytes.isNotEmpty) {
      for (var imageBytes in newImagesBytes) {
        final url = await _uploadImage(imageBytes, 'blog-images');
        imageUrls.add(url);
      }
    }

    await _client
        .from('blogs')
        .update({'title': title, 'content': content, 'image_urls': imageUrls})
        .eq('id', blogId);
  }

  /// DELETE
  Future<void> deleteBlog(String blogId) async {
    await _client.from('blogs').delete().eq('id', blogId);
  }

  /// Upload image helper
  Future<String> _uploadImage(Uint8List bytes, String bucket) async {
    final fileName = '${const Uuid().v4()}.jpg';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from(bucket).getPublicUrl(fileName);
  }
}
