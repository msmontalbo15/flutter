import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/blog.dart';
import '../../../services/blog_service.dart';
import '../../../utils/date_utils.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/image_carousel.dart';
import 'blog_form_screen.dart';
import '../comment/comment_section.dart';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;
  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _service = BlogService();
  late Blog _blog;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;
    _refreshBlog();
  }

  Future<void> _refreshBlog() async {
    try {
      final fresh = await _service.fetchBlog(_blog.id);
      if (mounted) setState(() => _blog = fresh);
    } catch (_) {}
  }

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';
  bool get _isAuthor => _blog.authorId == _currentUserId;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _service.deleteBlog(_blog.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _deleting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_blog.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_isAuthor) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlogFormScreen(blog: _blog),
                  ),
                );
                if (updated == true) {
                  final fresh = await _service.fetchBlog(_blog.id);
                  setState(() => _blog = fresh);
                }
              },
            ),
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: _deleting ? null : _delete,
            ),
          ],
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image carousel
              if (_blog.imageUrls.isNotEmpty)
                ImageCarousel(
                  imageUrls: _blog.imageUrls,
                  height: 250,
                  borderRadius: BorderRadius.circular(12),
                ),
              if (_blog.imageUrls.isNotEmpty) const SizedBox(height: 20),

              // Title
              Text(
                _blog.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _blog.authorAvatar != null
                        ? NetworkImage(_blog.authorAvatar!)
                        : null,
                    child: _blog.authorAvatar == null
                        ? Text((_blog.authorName ?? '?')[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _blog.authorName ?? 'Unknown',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatDateTime(_blog.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _blog.content,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),

              // Comments
              Text(
                'Comments',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CommentSection(blogId: _blog.id),
            ],
          ),
        ),
      ),
    );
  }
}
