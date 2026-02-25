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
import '../../../widgets/notification_bell.dart';

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
  int _totalCount = 0;
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
      final result = await _service.fetchBlogs(page);
      setState(() {
        _blogs = result.blogs;
        _totalCount = result.totalCount;
        _currentPage = page;
        _totalPages = (result.totalCount / BlogService.limit).ceil().clamp(1, double.infinity).toInt();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
          const NotificationBell(),
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
                                Icon(Icons.article_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No posts yet',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
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
                                      builder: (_) =>
                                          BlogDetailScreen(blog: blog),
                                    ),
                                  );
                                  _loadPage(_currentPage);
                                },
                              );
                            },
                          ),
              ),

              // Modern Pagination Bar
              if (!_loading && _blogs.isNotEmpty)
                _ModernPagination(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  totalCount: _totalCount,
                  limit: BlogService.limit,
                  onPageChanged: _loadPage,
                ),

              const SizedBox(height: 80), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Modern Pagination Widget
// ─────────────────────────────────────────────

class _ModernPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int limit;
  final void Function(int) onPageChanged;

  const _ModernPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.limit,
    required this.onPageChanged,
  });

  List<_PageItem> _buildPageItems() {
    final items = <_PageItem>[];

    if (totalPages <= 7) {
      for (int i = 0; i < totalPages; i++) {
        items.add(_PageItem.page(i));
      }
      return items;
    }

    // Always show first
    items.add(_PageItem.page(0));

    final showLeftDots = currentPage > 3;
    final showRightDots = currentPage < totalPages - 4;

    if (showLeftDots) {
      items.add(_PageItem.dots());
    }

    // Pages around current
    final start = showLeftDots ? (currentPage - 1).clamp(1, totalPages - 2) : 1;
    final end = showRightDots
        ? (currentPage + 1).clamp(1, totalPages - 2)
        : totalPages - 2;

    for (int i = start; i <= end; i++) {
      items.add(_PageItem.page(i));
    }

    if (showRightDots) {
      items.add(_PageItem.dots());
    }

    // Always show last
    items.add(_PageItem.page(totalPages - 1));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final startEntry = currentPage * limit + 1;
    final endEntry = ((currentPage + 1) * limit).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Showing X–Y of Z label
          Text(
            'Showing $startEntry–$endEntry of $totalCount posts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // Pagination row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ← Prev button
              _NavButton(
                icon: Icons.arrow_back_ios_new_rounded,
                enabled: currentPage > 0,
                onTap: () => onPageChanged(currentPage - 1),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 6),

              // Page number pills
              ..._buildPageItems().map((item) {
                if (item.isDots) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      '···',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  );
                }
                final page = item.page!;
                final isActive = page == currentPage;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Material(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isActive ? null : () => onPageChanged(page),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 42 : 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '${page + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(width: 6),

              // → Next button
              _NavButton(
                icon: Icons.arrow_forward_ios_rounded,
                enabled: currentPage < totalPages - 1,
                onTap: () => onPageChanged(currentPage + 1),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageItem {
  final int? page;
  final bool isDots;

  const _PageItem._({this.page, this.isDots = false});

  factory _PageItem.page(int p) => _PageItem._(page: p);
  factory _PageItem.dots() => const _PageItem._(isDots: true);
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Blog Card
// ─────────────────────────────────────────────

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
                      // Comment count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 12,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${blog.commentCount}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
