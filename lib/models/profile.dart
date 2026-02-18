class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;

  Profile({required this.id, this.fullName, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
    );
  }
}
