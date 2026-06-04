import '../../domain/entities/postman_account_entity.dart';

class PostmanAccountModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String avatarUrl;

  const PostmanAccountModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
  });

  factory PostmanAccountModel.fromJson(Map<String, dynamic> json) {
    return PostmanAccountModel(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatar']?.toString() ?? '',
    );
  }

  PostmanAccountEntity toEntity() {
    return PostmanAccountEntity(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
  }
}
