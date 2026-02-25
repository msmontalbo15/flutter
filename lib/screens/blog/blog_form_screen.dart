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

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));
  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) { _showSnack('Title is required'); return; }
    if (content.isEmpty) { _showSnack('Content is required'); return; }

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
    final colorScheme = theme.colorScheme;
    final hasImages = _newImages.isNotEmpty || _existingImageUrls.isNotEmpty;

    // Shared input decoration factory
    InputDecoration _fieldDecoration({
      required String label,
      required String hint,
      IconData? icon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
        labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
        prefixIcon: icon != null ? Icon(icon, color: colorScheme.primary) : null,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
    }

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
                          strokeWidth: 2, color: Colors.white),
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
              // ── Image preview grid ──────────────────────────
              if (hasImages) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Images (${_existingImageUrls.length + _newImages.length})',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                const SizedBox(height: 12),
              ],

              // ── Add images button ───────────────────────────
              FilledButton.tonalIcon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(hasImages ? 'Add more images' : 'Add images'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title field ─────────────────────────────────
              TextField(
                controller: _titleCtrl,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration(
                  label: 'Post Title',
                  hint: 'Enter a compelling title...',
                  icon: Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // ── Content field ───────────────────────────────
              TextField(
                controller: _contentCtrl,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                maxLines: null,
                minLines: 12,
                textCapitalization: TextCapitalization.sentences,
                decoration: _fieldDecoration(
                  label: 'Content',
                  hint: 'Write your story here...',
                  icon: Icons.edit_note_rounded,
                ).copyWith(
                  // For multiline, align prefix icon to top
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
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
              ? Image.network(imageUrl!,
                  width: 100, height: 100, fit: BoxFit.cover)
              : Image.memory(imageBytes!,
                  width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
