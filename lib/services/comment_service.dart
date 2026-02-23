import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/comment.dart';

class CommentService {
  final _client = Supabase.instance.client;

  /// Fetch all comments for a blog
  Future<List<Comment>> fetchComments(String blogId) async {
    final response = await _client
        .from('comments')
        .select('*, profiles!comments_author_id_fkey(full_name, avatar_url)')
        .eq('blog_id', blogId)
        .order('created_at', ascending: true);

    return (response as List).map((map) => Comment.fromMap(map)).toList();
  }

  /// Add a comment with multiple images
  Future<void> addComment({
    required String blogId,
    required String content,
    List<Uint8List>? imagesBytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> imageUrls = [];
    if (imagesBytes != null && imagesBytes.isNotEmpty) {
      for (var imageBytes in imagesBytes) {
        final url = await _uploadImage(imageBytes);
        imageUrls.add(url);
      }
    }

    await _client.from('comments').insert({
      'blog_id': blogId,
      'author_id': user.id,
      'content': content,
      'image_urls': imageUrls,
    });
  }

  /// Update a comment with multiple images
  Future<void> updateComment({
    required String commentId,
    required String content,
    List<Uint8List>? newImagesBytes,
    List<String>? existingImageUrls,
    bool removeAllImages = false,
  }) async {
    List<String> imageUrls = removeAllImages ? [] : (existingImageUrls ?? []);

    if (newImagesBytes != null && newImagesBytes.isNotEmpty) {
      for (var imageBytes in newImagesBytes) {
        final url = await _uploadImage(imageBytes);
        imageUrls.add(url);
      }
    }

    await _client
        .from('comments')
        .update({'content': content, 'image_urls': imageUrls})
        .eq('id', commentId);
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  Future<String> _uploadImage(Uint8List bytes) async {
    final fileName = '${const Uuid().v4()}.jpg';
    await _client.storage
        .from('comment-images')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return _client.storage.from('comment-images').getPublicUrl(fileName);
  }
}
