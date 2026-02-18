import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/comment.dart';
import '../../../services/comment_service.dart';
import '../../../utils/date_utils.dart';

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
  Uint8List? _imageBytes;

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
      if (mounted)
        setState(() {
          _comments = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _post() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _imageBytes == null) return;
    setState(() => _posting = true);
    try {
      await _service.addComment(
        blogId: widget.blogId,
        content: text,
        imageBytes: _imageBytes,
      );
      _textCtrl.clear();
      setState(() => _imageBytes = null);
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
    final theme = Theme.of(context);

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
              children: [
                if (_imageBytes != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() => _imageBytes = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_imageBytes != null) const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 3,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: _pickImage,
                          tooltip: 'Add image',
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
  Uint8List? _newImageBytes;
  String? _existingImageUrl;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.comment.content);
    _existingImageUrl = widget.comment.imageUrl;
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _newImageBytes = bytes;
      _removeImage = false;
      _existingImageUrl = null;
    });
  }

  void _clearImage() {
    setState(() {
      _newImageBytes = null;
      _existingImageUrl = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _newImageBytes == null && _existingImageUrl == null) {
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
        newImageBytes: _newImageBytes,
        existingImageUrl: _existingImageUrl,
        removeImage: _removeImage,
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

  bool get _hasImage =>
      _newImageBytes != null || (_existingImageUrl != null && !_removeImage);

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

          // Image preview
          if (_hasImage)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _newImageBytes != null
                      ? Image.memory(
                          _newImageBytes!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _existingImageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _clearImage,
                      tooltip: 'Remove image',
                    ),
                  ),
                ),
              ],
            ),

          if (_hasImage) const SizedBox(height: 10),

          // Image action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(_hasImage ? 'Change image' : 'Add image'),
              ),
              if (_hasImage) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clearImage,
                  icon: const Icon(
                    Icons.hide_image_outlined,
                    size: 18,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Remove image',
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
          TextField(
            controller: _ctrl,
            maxLines: 4,
            minLines: 2,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Edit your comment...',
              border: OutlineInputBorder(),
            ),
          ),
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
                  if (comment.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        comment.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, _) => const SizedBox.shrink(),
                      ),
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
