class PostmanAccountEntity {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String avatarUrl;

  const PostmanAccountEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
  });

  String get displayName => fullName.isNotEmpty ? fullName : username;
}
