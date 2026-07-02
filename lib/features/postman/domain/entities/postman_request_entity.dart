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

  PostmanRequestEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? method,
    PostmanUrlEntity? url,
    List<PostmanKeyValueEntity>? queryParameters,
    List<PostmanKeyValueEntity>? headers,
    PostmanBodyEntity? body,
    PostmanAuthEntity? auth,
  }) => PostmanRequestEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    method: method ?? this.method,
    url: url ?? this.url,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    body: body ?? this.body,
    auth: auth ?? this.auth,
  );

  String get rawUrl => url.raw;
}
