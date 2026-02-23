import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/blog.dart';
import '../../../services/blog_service.dart';
import '../../../widgets/gradient_background.dart';

class BlogFormScreen extends StatefulWidget {
  final Blog? blog;
  const BlogFormScreen({super.key, this.blog});

  @override
  State<BlogFormScreen> createState() => _BlogFormScreenState();
}

class _BlogFormScreenState extends State<BlogFormScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _service = BlogService();
  bool _saving = false;
  List<Uint8List> _newImages = [];
  List<String> _existingImageUrls = [];

  bool get _isEditing => widget.blog != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.blog!.title;
      _contentCtrl.text = widget.blog!.content;
      _existingImageUrls = List.from(widget.blog!.imageUrls);
    }
  }

  Future<void> _pickImages() async {
    final imgs = await ImagePicker().pickMultiImage(imageQuality: 80);
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
          newImagesBytes: _newImages.isNotEmpty ? _newImages : null,
          existingImageUrls: _existingImageUrls,
        );
        _showSnack('Post updated!');
      } else {
        await _service.createBlog(
          title: title,
          content: content,
          imagesBytes: _newImages.isNotEmpty ? _newImages : null,
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
    final hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;

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
              // Image grid
              if (hasImages)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images (${_existingImageUrls.length + _newImages.length})',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._existingImageUrls.asMap().entries.map(
                            (e) => _ImageTile(
                              isNetwork: true,
                              imageUrl: e.value,
                              onRemove: () => _removeExistingImage(e.key),
                            ),
                          ),
                          ..._newImages.asMap().entries.map(
                            (e) => _ImageTile(
                              isNetwork: false,
                              imageBytes: e.value,
                              onRemove: () => _removeNewImage(e.key),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (hasImages) const SizedBox(height: 12),

              // Add images button
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(hasImages ? 'Add more images' : 'Add images'),
              ),
              const SizedBox(height: 20),

              // Title
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

              // Content
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

class _ImageTile extends StatelessWidget {
  final bool isNetwork;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback onRemove;

  const _ImageTile({
    required this.isNetwork,
    this.imageUrl,
    this.imageBytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isNetwork
              ? Image.network(
                  imageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                )
              : Image.memory(
                  imageBytes!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
