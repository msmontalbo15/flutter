import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/profile.dart';
import '../../../services/profile_service.dart';
import '../../../store/app_state.dart';
import '../../../store/auth/auth_reducer.dart';
import '../../../widgets/gradient_background.dart';
import '../../../store/theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _nameCtrl = TextEditingController();
  Profile? _profile;
  bool _loading = true;
  bool _saving = false;
  Uint8List? _newAvatarBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final p = await _profileService.getProfile();
      setState(() {
        _profile = p;
        _nameCtrl.text = p?.fullName ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    setState(() => _newAvatarBytes = bytes);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Name cannot be empty');
      return;
    }
    setState(() => _saving = true);
    try {
      await _profileService.updateProfile(
        fullName: _nameCtrl.text.trim(),
        avatarBytes: _newAvatarBytes,
        existingAvatarUrl: _profile?.avatarUrl,
      );
      await _loadProfile();
      setState(() => _newAvatarBytes = null);
      _showSnack('Profile updated!');
    } catch (e) {
      _showSnack('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    StoreProvider.of<AppState>(context).dispatch(LogoutAction());
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Avatar
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: _newAvatarBytes != null
                                ? MemoryImage(_newAvatarBytes!)
                                : (_profile?.avatarUrl != null
                                      ? NetworkImage(_profile!.avatarUrl!)
                                            as ImageProvider
                                      : null),
                            child:
                                (_newAvatarBytes == null &&
                                    _profile?.avatarUrl == null)
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Display name card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Display Name',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                                hintText: 'Your display name',
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _saving ? null : _save,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
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
                    ),
                    const SizedBox(height: 16),

                    // Theme card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (context, themeMode, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'Appearance',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                RadioListTile<ThemeMode>(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('System default'),
                                  secondary: const Icon(
                                    Icons.brightness_auto_outlined,
                                  ),
                                  value: ThemeMode.system,
                                  groupValue: themeMode,
                                  onChanged: (_) => themeNotifier.setSystem(),
                                ),
                                RadioListTile<ThemeMode>(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Light'),
                                  secondary: const Icon(
                                    Icons.light_mode_outlined,
                                  ),
                                  value: ThemeMode.light,
                                  groupValue: themeMode,
                                  onChanged: (_) => themeNotifier.setLight(),
                                ),
                                RadioListTile<ThemeMode>(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Dark'),
                                  secondary: const Icon(
                                    Icons.dark_mode_outlined,
                                  ),
                                  value: ThemeMode.dark,
                                  groupValue: themeMode,
                                  onChanged: (_) => themeNotifier.setDark(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign out
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
