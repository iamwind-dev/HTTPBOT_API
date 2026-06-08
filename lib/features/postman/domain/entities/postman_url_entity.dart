import 'postman_key_value_entity.dart';

class PostmanUrlEntity {
  const PostmanUrlEntity({
    required this.raw,
    this.protocol = '',
    this.host = const [],
    this.path = const [],
    this.queryParameters = const [],
  });

  final String raw;
  final String protocol;
  final List<String> host;
  final List<String> path;
  final List<PostmanKeyValueEntity> queryParameters;
}
