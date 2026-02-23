import 'package:flutter/material.dart';
import '../../../models/blog.dart';
import '../../../models/profile.dart';
import '../../../services/blog_service.dart';
import '../../../services/profile_service.dart';
import '../../../utils/date_utils.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/image_carousel.dart';
import 'blog_detail_screen.dart';
import 'blog_form_screen.dart';
import '../profile/profile_screen.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  final _service = BlogService();
  final _profileService = ProfileService();
  List<Blog> _blogs = [];
  Profile? _profile;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPage(0);
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _profileService.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _loadPage(int page) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data = await _service.fetchBlogs(page);
      setState(() {
        _blogs = data;
        _currentPage = page;
        // If we got a full page, there might be more
        if (data.length >= BlogService.limit) {
          _totalPages = page + 2; // at least one more page
        } else {
          _totalPages = page + 1; // this is the last page
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/images/logo.webp', height: 36),
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadProfile();
              _loadPage(_currentPage);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: _profile?.avatarUrl != null
                        ? NetworkImage(_profile!.avatarUrl!)
                        : null,
                    child: _profile?.avatarUrl == null
                        ? Text(
                            (_profile?.fullName ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _profile?.fullName ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const BlogFormScreen()),
          );
          if (created == true) _loadPage(0);
        },
        icon: const Icon(Icons.edit),
        label: const Text('New Post'),
      ),
      body: GradientBackground(
        child: RefreshIndicator(
          onRefresh: () => _loadPage(_currentPage),
          child: Column(
            children: [
              // Blog list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _blogs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Be the first to write something!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _blogs.length,
                        itemBuilder: (context, i) {
                          final blog = _blogs[i];
                          return _BlogCard(
                            blog: blog,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlogDetailScreen(blog: blog),
                                ),
                              );
                              _loadPage(_currentPage);
                            },
                          );
                        },
                      ),
              ),

              // Pagination bar
              if (!_loading && _blogs.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous button
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () => _loadPage(_currentPage - 1)
                            : null,
                        style: IconButton.styleFrom(
                          foregroundColor: _currentPage > 0
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                      ),

                      // Page number buttons
                      ..._buildPageButtons(theme),

                      // Next button
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages - 1
                            ? () => _loadPage(_currentPage + 1)
                            : null,
                        style: IconButton.styleFrom(
                          foregroundColor: _currentPage < _totalPages - 1
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons(ThemeData theme) {
    final buttons = <Widget>[];
    final start = (_currentPage - 2).clamp(
      0,
      (_totalPages - 5).clamp(0, _totalPages),
    );
    final end = (start + 5).clamp(0, _totalPages);

    // Show first page + ellipsis if needed
    if (start > 0) {
      buttons.add(
        _PageButton(
          page: 0,
          current: _currentPage,
          onTap: _loadPage,
          theme: theme,
        ),
      );
      if (start > 1) {
        buttons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
    }

    // Page range buttons
    for (int i = start; i < end; i++) {
      buttons.add(
        _PageButton(
          page: i,
          current: _currentPage,
          onTap: _loadPage,
          theme: theme,
        ),
      );
    }

    // Show last page + ellipsis if needed
    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        buttons.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
      buttons.add(
        _PageButton(
          page: _totalPages - 1,
          current: _currentPage,
          onTap: _loadPage,
          theme: theme,
        ),
      );
    }

    return buttons;
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final int current;
  final void Function(int) onTap;
  final ThemeData theme;

  const _PageButton({
    required this.page,
    required this.current,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = page == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: isActive ? null : () => onTap(page),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? null
                : Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '${page + 1}',
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Blog blog;
  final VoidCallback onTap;
  const _BlogCard({required this.blog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.imageUrls.isNotEmpty)
              ImageCarousel(
                imageUrls: blog.imageUrls,
                height: 180,
                borderRadius: BorderRadius.zero,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: blog.authorAvatar != null
                            ? NetworkImage(blog.authorAvatar!)
                            : null,
                        child: blog.authorAvatar == null
                            ? Text(
                                (blog.authorName ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blog.authorName ?? 'Unknown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatDate(blog.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
