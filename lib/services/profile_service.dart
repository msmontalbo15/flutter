import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/profile.dart';

class ProfileService {
  final supabase = Supabase.instance.client;

  Future<Profile?> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<String?> getFullName() async {
    final profile = await getProfile();
    return profile?.fullName;
  }

  Future<void> updateProfile({
    required String fullName,
    Uint8List? avatarBytes,
    String? existingAvatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    String? avatarUrl = existingAvatarUrl;

    if (avatarBytes != null) {
      final fileName = '${user.id}/${const Uuid().v4()}.jpg';
      await supabase.storage
          .from('profile-images')
          .uploadBinary(
            fileName,
            avatarBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      avatarUrl = supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);
    }

    await supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    });
  }
}
