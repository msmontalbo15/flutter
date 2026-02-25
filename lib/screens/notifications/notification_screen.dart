import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../services/blog_service.dart';
import '../../utils/date_utils.dart';
import '../blog/blog_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  final _blogService = BlogService();
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchNotifications();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.isRead).map((n) => n.commentId).toList();
    if (unread.isEmpty) return;
    await _service.markAllAsRead(unread);
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _openNotification(AppNotification notif) async {
    if (!notif.isRead) {
      await _service.markAsRead(notif.commentId);
      setState(() {
        _notifications = _notifications
            .map((n) => n.id == notif.id ? n.copyWith(isRead: true) : n)
            .toList();
      });
    }

    try {
      final blog = await _blogService.fetchBlog(notif.blogId);
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BlogDetailScreen(blog: blog)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 72, color: cs.outlineVariant),
                    itemBuilder: (context, i) => _NotificationTile(
                      notification: _notifications[i],
                      onTap: () => _openNotification(_notifications[i]),
                    ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 40, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'All caught up!',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'No comments on your posts yet.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isUnread
            ? cs.primaryContainer.withOpacity(isDark ? 0.15 : 0.25)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with unread dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage: notification.commenterAvatar != null
                      ? NetworkImage(notification.commenterAvatar!)
                      : null,
                  child: notification.commenterAvatar == null
                      ? Text(
                          notification.commenterName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
                if (isUnread)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF020617) : cs.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: notification.commenterName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: ' commented on ',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: notification.blogTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notification.commentPreview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${notification.commentPreview}"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        formatDateTime(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right-side unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
