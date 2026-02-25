import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/comment.dart';
import '../../../services/comment_service.dart';
import '../../../utils/date_utils.dart';
import '../../../widgets/image_carousel.dart';

class CommentSection extends StatefulWidget {
  final String blogId;
  const CommentSection({super.key, required this.blogId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _service = CommentService();
  final _textCtrl = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<Uint8List> _newImages = [];

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchComments(widget.blogId);
      if (mounted) {
        setState(() {
          _comments = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (imgs.isEmpty) return;

    final bytes = <Uint8List>[];
    for (var img in imgs) {
      bytes.add(await img.readAsBytes());
    }
    setState(() => _newImages.addAll(bytes));
  }

  void _removeImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _newImages.isEmpty) return;
    setState(() => _posting = true);
    try {
      await _service.addComment(
        blogId: widget.blogId,
        content: text,
        imagesBytes: _newImages.isNotEmpty ? _newImages : null,
      );
      _textCtrl.clear();
      setState(() => _newImages = []);
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting: $e')));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _deleteComment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This cannot be undone.',
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

    try {
      await _service.deleteComment(id);
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  Future<void> _editComment(Comment comment) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditCommentSheet(
        comment: comment,
        service: _service,
        onSaved: _loadComments,
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Comment input card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image grid preview
                if (_newImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _newImages
                          .asMap()
                          .entries
                          .map(
                            (e) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    e.value,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(e.key),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),

                // Input row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Builder(builder: (context) {
                        final cs = Theme.of(context).colorScheme;
                        return TextField(
                          controller: _textCtrl,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerLow,
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: cs.outline.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: _pickImages,
                          tooltip: 'Add images',
                        ),
                        IconButton(
                          icon: _posting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: _posting ? null : _post,
                          tooltip: 'Post',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Comments list
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Failed to load comments:\n$_error',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadComments,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No comments yet. Be the first!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._comments.map(
            (c) => _CommentTile(
              comment: c,
              isAuthor: c.authorId == _currentUserId,
              onDelete: () => _deleteComment(c.id),
              onEdit: () => _editComment(c),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Edit Comment Bottom Sheet ────────────────────────────────────────────────

class _EditCommentSheet extends StatefulWidget {
  final Comment comment;
  final CommentService service;
  final VoidCallback onSaved;

  const _EditCommentSheet({
    required this.comment,
    required this.service,
    required this.onSaved,
  });

  @override
  State<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<_EditCommentSheet> {
  late final TextEditingController _ctrl;
  List<Uint8List> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.comment.content);
    _existingImageUrls = List.from(widget.comment.imageUrls);
  }

  Future<void> _pickImages() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (imgs.isEmpty) return;

    final bytes = <Uint8List>[];
    for (var img in imgs) {
      bytes.add(await img.readAsBytes());
    }
    setState(() => _newImages.addAll(bytes));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _clearAllImages() {
    setState(() {
      _newImages = [];
      _existingImageUrls = [];
    });
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _newImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.service.updateComment(
        commentId: widget.comment.id,
        content: text,
        newImagesBytes: _newImages.isNotEmpty ? _newImages : null,
        existingImageUrls: _existingImageUrls,
        removeAllImages: _existingImageUrls.isEmpty && _newImages.isEmpty,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _hasImages => _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Edit Comment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image grid
            if (_hasImages)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Existing images
                    ..._existingImageUrls.asMap().entries.map(
                      (e) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              e.value,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(e.key),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // New images
                    ..._newImages.asMap().entries.map(
                      (e) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              e.value,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(e.key),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_hasImages) const SizedBox(height: 10),

            // Image action buttons
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(_hasImages ? 'Add more' : 'Add images'),
                ),
                if (_hasImages) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _clearAllImages,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Remove all',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Text field
            Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return TextField(
                controller: _ctrl,
                maxLines: 4,
                minLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Edit your comment...',
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.outline.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Save button
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comment Tile ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isAuthor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _CommentTile({
    required this.comment,
    required this.isAuthor,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            child: comment.authorAvatar == null
                ? Text(
                    (comment.authorName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorName ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDateTime(comment.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAuthor) ...[
                        GestureDetector(
                          onTap: onEdit,
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (comment.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(comment.content, style: theme.textTheme.bodyMedium),
                  ],
                  if (comment.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ImageCarousel(
                      imageUrls: comment.imageUrls,
                      height: 150,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
