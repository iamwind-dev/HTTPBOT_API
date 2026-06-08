import '../../domain/entities/postman_body_entity.dart';
import 'postman_key_value_model.dart';

class PostmanBodyModel {
  const PostmanBodyModel({
    this.type = PostmanBodyType.none,
    this.raw = '',
    this.rawSubtype = PostmanRawBodySubtype.text,
    this.formData = const [],
    this.urlEncoded = const [],
    this.graphQlQuery = '',
    this.graphQlVariables = '',
    this.filePath = '',
  });

  final PostmanBodyType type;
  final String raw;
  final PostmanRawBodySubtype rawSubtype;
  final List<PostmanKeyValueModel> formData;
  final List<PostmanKeyValueModel> urlEncoded;
  final String graphQlQuery;
  final String graphQlVariables;
  final String filePath;

  factory PostmanBodyModel.fromJson(Object? json) {
    if (json is! Map) {
      return const PostmanBodyModel();
    }

    final map = Map<String, dynamic>.from(json);
    final mode = map['mode']?.toString().trim().toLowerCase() ?? '';

    return PostmanBodyModel(
      type: _parseBodyType(mode),
      raw: map['raw']?.toString() ?? '',
      rawSubtype: _parseRawSubtype(map['options']),
      formData: _parseKeyValueList(map['formdata']),
      urlEncoded: _parseKeyValueList(map['urlencoded']),
      graphQlQuery: map['graphql'] is Map
          ? Map<String, dynamic>.from(map['graphql'])['query']?.toString() ?? ''
          : '',
      graphQlVariables: map['graphql'] is Map
          ? Map<String, dynamic>.from(map['graphql'])['variables']?.toString() ?? ''
          : '',
      filePath: map['file'] is Map
          ? Map<String, dynamic>.from(map['file'])['src']?.toString() ?? ''
          : '',
    );
  }

  static List<PostmanKeyValueModel> _parseKeyValueList(Object? input) {
    return (input as List? ?? [])
        .whereType<Map>()
        .map((item) => PostmanKeyValueModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static PostmanBodyType _parseBodyType(String mode) {
    switch (mode) {
      case 'raw':
        return PostmanBodyType.raw;
      case 'formdata':
        return PostmanBodyType.formData;
      case 'urlencoded':
        return PostmanBodyType.urlEncoded;
      case 'graphql':
        return PostmanBodyType.graphQl;
      case 'file':
        return PostmanBodyType.file;
      default:
        return PostmanBodyType.none;
    }
  }

  static PostmanRawBodySubtype _parseRawSubtype(Object? input) {
    if (input is! Map) {
      return PostmanRawBodySubtype.text;
    }

    final raw = Map<String, dynamic>.from(input)['raw'];
    if (raw is! Map) {
      return PostmanRawBodySubtype.text;
    }

    switch (Map<String, dynamic>.from(raw)['language']?.toString().trim().toLowerCase()) {
      case 'json':
        return PostmanRawBodySubtype.json;
      case 'xml':
        return PostmanRawBodySubtype.xml;
      case 'html':
        return PostmanRawBodySubtype.html;
      case 'javascript':
        return PostmanRawBodySubtype.javascript;
      default:
        return PostmanRawBodySubtype.text;
    }
  }

  PostmanBodyEntity toEntity() {
    return PostmanBodyEntity(
      type: type,
      raw: raw,
      rawSubtype: rawSubtype,
      formData: formData.map((item) => item.toEntity()).toList(),
      urlEncoded: urlEncoded.map((item) => item.toEntity()).toList(),
      graphQlQuery: graphQlQuery,
      graphQlVariables: graphQlVariables,
      filePath: filePath,
    );
  }
}
