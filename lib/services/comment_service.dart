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
        .order('created_at', ascending: false);

    return (response as List).map((map) => Comment.fromMap(map)).toList();
  }

  /// Add a comment
  Future<void> addComment({
    required String blogId,
    required String content,
    Uint8List? imageBytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await _uploadImage(imageBytes);
    }

    await _client.from('comments').insert({
      'blog_id': blogId,
      'author_id': user.id,
      'content': content,
      'image_url': imageUrl,
    });
  }

  /// Update a comment
  Future<void> updateComment({
    required String commentId,
    required String content,
    Uint8List? newImageBytes,
    String? existingImageUrl,
    bool removeImage = false,
  }) async {
    String? imageUrl;
    if (removeImage) {
      imageUrl = null;
    } else if (newImageBytes != null) {
      imageUrl = await _uploadImage(newImageBytes);
    } else {
      imageUrl = existingImageUrl;
    }

    await _client
        .from('comments')
        .update({'content': content, 'image_url': imageUrl})
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
