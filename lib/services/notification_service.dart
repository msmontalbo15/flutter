import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

/// Notifications are derived entirely from the existing [comments] + [blogs]
/// + [profiles] tables — no extra DB table required.
///
/// Read-state is persisted locally via SharedPreferences because there is no
/// notifications table in the schema.  The key format is:
///   "notif_read_<commentId>"  →  "true"
class NotificationService {
  final _client = Supabase.instance.client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ── Read-state helpers (SharedPreferences) ──────────────────────────────

  Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys()
        .where((k) => k.startsWith('notif_read_'))
        .map((k) => k.replaceFirst('notif_read_', ''))
        .toSet();
  }

  Future<void> _setRead(String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_read_$commentId', true);
  }

  Future<void> _setAllRead(List<String> commentIds) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in commentIds) {
      await prefs.setBool('notif_read_$id', true);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch all notifications for the current user (newest first, limit 50).
  /// Steps:
  ///   1. Get IDs of blogs authored by [_currentUserId].
  ///   2. Get comments on those blogs, excluding own comments.
  ///   3. Merge with local read-state.
  Future<List<AppNotification>> fetchNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    // 1. My blog IDs
    final blogRows = await _client
        .from('blogs')
        .select('id, title')
        .eq('author_id', userId);

    if ((blogRows as List).isEmpty) return [];

    final blogMap = <String, String>{};   // id → title
    for (final b in blogRows) {
      blogMap[b['id'] as String] = b['title'] as String? ?? '';
    }

    // 2. Comments on those blogs, not by me
    final commentRows = await _client
        .from('comments')
        .select('id, blog_id, author_id, content, created_at, profiles!comments_author_id_fkey(full_name, avatar_url)')
        .inFilter('blog_id', blogMap.keys.toList())
        .neq('author_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    // 3. Local read-state
    final readIds = await _readIds();

    return (commentRows as List).map((row) {
      final profile  = row['profiles'] as Map<String, dynamic>?;
      final commentId = row['id'] as String;
      final blogId    = row['blog_id'] as String? ?? '';
      final content   = row['content'] as String? ?? '';

      return AppNotification(
        id:              commentId,
        recipientId:     userId,
        blogId:          blogId,
        blogTitle:       blogMap[blogId] ?? '',
        commentId:       commentId,
        commenterName:   profile?['full_name'] as String? ?? 'Someone',
        commenterAvatar: profile?['avatar_url'] as String?,
        commentPreview:  content.length > 80 ? '${content.substring(0, 80)}…' : content,
        isRead:          readIds.contains(commentId),
        createdAt:       DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  /// Mark a single notification as read (locally).
  Future<void> markAsRead(String commentId) => _setRead(commentId);

  /// Mark all supplied comment IDs as read (locally).
  Future<void> markAllAsRead(List<String> commentIds) => _setAllRead(commentIds);

  /// Subscribe to realtime INSERT events on [comments].
  /// [onNew] is called only when the new comment is on one of the current
  /// user's blogs (we verify this in the callback using [myBlogIds]).
  RealtimeChannel subscribeToNewComments({
    required Set<String> myBlogIds,
    required void Function(Map<String, dynamic> payload) onNew,
  }) {
    final userId = _currentUserId ?? '';

    final channel = _client
        .channel('comments-notify-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comments',
          callback: (payload) {
            final record = payload.newRecord;
            final blogId   = record['blog_id'] as String?;
            final authorId = record['author_id'] as String?;

            // Only notify if: comment is on my blog AND not by me
            if (blogId != null &&
                myBlogIds.contains(blogId) &&
                authorId != userId) {
              onNew(record);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Fetch only the IDs of blogs the current user owns (used for realtime filter).
  Future<Set<String>> fetchMyBlogIds() async {
    final userId = _currentUserId;
    if (userId == null) return {};
    final rows = await _client
        .from('blogs')
        .select('id')
        .eq('author_id', userId);
    return (rows as List).map((r) => r['id'] as String).toSet();
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
