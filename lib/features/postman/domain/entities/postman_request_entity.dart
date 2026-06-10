import 'postman_auth_entity.dart';
import 'postman_body_entity.dart';
import 'postman_key_value_entity.dart';
import 'postman_url_entity.dart';

class PostmanRequestEntity {
  final String id;
  final String name;
  final String description;
  final String method;
  final PostmanUrlEntity url;
  final List<PostmanKeyValueEntity> queryParameters;
  final List<PostmanKeyValueEntity> headers;
  final PostmanBodyEntity body;
  final PostmanAuthEntity auth;

  const PostmanRequestEntity({
    required this.name,
    required this.method,
    required this.url,
    this.id = '',
    this.description = '',
    this.queryParameters = const [],
    this.headers = const [],
    this.body = const PostmanBodyEntity(),
    this.auth = const PostmanAuthEntity(),
  });

  String get rawUrl => url.raw;
}
