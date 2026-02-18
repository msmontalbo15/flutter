import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/blog.dart';
import '../../../services/blog_service.dart';
import '../../../widgets/gradient_background.dart';

class BlogFormScreen extends StatefulWidget {
  final Blog? blog; // null = create, non-null = edit
  const BlogFormScreen({super.key, this.blog});

  @override
  State<BlogFormScreen> createState() => _BlogFormScreenState();
}

class _BlogFormScreenState extends State<BlogFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _service = BlogService();
  bool _saving = false;
  Uint8List? _imageBytes;
  String? _existingImageUrl;

  bool get _isEditing => widget.blog != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.blog!.title;
      _contentCtrl.text = widget.blog!.content;
      _existingImageUrl = widget.blog!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _existingImageUrl = null;
    });
  }

  void _removeImage() => setState(() {
    _imageBytes = null;
    _existingImageUrl = null;
  });

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack('Title is required');
      return;
    }
    if (content.isEmpty) {
      _showSnack('Content is required');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.updateBlog(
          blogId: widget.blog!.id,
          title: title,
          content: content,
          newImageBytes: _imageBytes,
          existingImageUrl: _existingImageUrl,
        );
        _showSnack('Post updated!');
      } else {
        await _service.createBlog(
          title: title,
          content: content,
          imageBytes: _imageBytes,
        );
        _showSnack('Post published!');
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _imageBytes != null || _existingImageUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Update' : 'Publish'),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              if (hasImage)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageBytes != null
                          ? Image.memory(
                              _imageBytes!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              _existingImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add cover image (optional)',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasImage)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change image'),
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleCtrl,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Post title...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                style: theme.textTheme.bodyLarge,
                maxLines: null,
                minLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Write your story...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
