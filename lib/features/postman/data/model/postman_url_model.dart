import '../../domain/entities/postman_url_entity.dart';
import 'postman_key_value_model.dart';

class PostmanUrlModel {
  const PostmanUrlModel({
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
  final List<PostmanKeyValueModel> queryParameters;

  factory PostmanUrlModel.fromJson(Object? json) {
    if (json is String) {
      return PostmanUrlModel(raw: json);
    }

    if (json is! Map) {
      return const PostmanUrlModel(raw: '');
    }

    final map = Map<String, dynamic>.from(json);
    final rawQuery = (map['query'] as List? ?? [])
        .whereType<Map>()
        .map((item) => PostmanKeyValueModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return PostmanUrlModel(
      raw: map['raw']?.toString() ?? '',
      protocol: map['protocol']?.toString() ?? '',
      host: _toStringList(map['host']),
      path: _toStringList(map['path']),
      queryParameters: rawQuery,
    );
  }

  static List<String> _toStringList(Object? input) {
    if (input is List) {
      return input.map((item) => item.toString()).toList();
    }

    return const [];
  }

  PostmanUrlEntity toEntity() {
    return PostmanUrlEntity(
      raw: raw,
      protocol: protocol,
      host: host,
      path: path,
      queryParameters: queryParameters.map((item) => item.toEntity()).toList(),
    );
  }
}
