import '../../domain/entities/postman_request_entity.dart';
import 'postman_auth_model.dart';
import 'postman_body_model.dart';
import 'postman_key_value_model.dart';
import 'postman_url_model.dart';

class PostmanRequestModel {
  final String id;
  final String name;
  final String description;
  final String method;
  final PostmanUrlModel url;
  final List<PostmanKeyValueModel> queryParameters;
  final List<PostmanKeyValueModel> headers;
  final PostmanBodyModel body;
  final PostmanAuthModel auth;

  const PostmanRequestModel({
    required this.id,
    required this.name,
    required this.description,
    required this.method,
    required this.url,
    this.queryParameters = const [],
    this.headers = const [],
    this.body = const PostmanBodyModel(),
    this.auth = const PostmanAuthModel(),
  });

  factory PostmanRequestModel.fromJson(Map<String, dynamic> json) {
    final request = json['request'] as Map<String, dynamic>? ?? {};
    final url = PostmanUrlModel.fromJson(request['url']);
    final queryParameters = url.queryParameters;
    final headers = (request['header'] as List? ?? [])
        .whereType<Map>()
        .map((item) => PostmanKeyValueModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return PostmanRequestModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: _readDescription(json['description']),
      method: request['method']?.toString() ?? 'GET',
      url: url,
      queryParameters: queryParameters,
      headers: headers,
      body: PostmanBodyModel.fromJson(request['body']),
      auth: PostmanAuthModel.fromJson(request['auth']),
    );
  }

  static String _readDescription(Object? input) {
    if (input is String) {
      return input;
    }

    if (input is Map) {
      return Map<String, dynamic>.from(input)['content']?.toString() ?? '';
    }

    return '';
  }

  PostmanRequestEntity toEntity() {
    return PostmanRequestEntity(
      id: id,
      name: name,
      description: description,
      method: method,
      url: url.toEntity(),
      queryParameters: queryParameters.map((item) => item.toEntity()).toList(),
      headers: headers.map((item) => item.toEntity()).toList(),
      body: body.toEntity(),
      auth: auth.toEntity(),
    );
  }
}
