import '../../domain/entities/postman_request_entity.dart';

class PostmanRequestModel {
  final String name;
  final String method;
  final String rawUrl;

  const PostmanRequestModel({
    required this.name,
    required this.method,
    required this.rawUrl,
  });

  factory PostmanRequestModel.fromJson(Map<String, dynamic> json) {
    final request = json['request'] as Map<String, dynamic>? ?? {};
    final url = request['url'];

    String rawUrl = '';
    if (url is Map<String, dynamic>) {
      rawUrl = url['raw']?.toString() ?? '';
    } else if (url is String) {
      rawUrl = url;
    }

    return PostmanRequestModel(
      name: json['name']?.toString() ?? '',
      method: request['method']?.toString() ?? 'GET',
      rawUrl: rawUrl,
    );
  }

  PostmanRequestEntity toEntity() {
    return PostmanRequestEntity(
      name: name,
      method: method,
      rawUrl: rawUrl,
    );
  }
}