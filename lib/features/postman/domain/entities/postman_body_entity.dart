import 'postman_key_value_entity.dart';

enum PostmanBodyType {
  none,
  raw,
  formData,
  urlEncoded,
  graphQl,
  file,
}

enum PostmanRawBodySubtype { text, json, xml, html, javascript }

class PostmanBodyEntity {
  const PostmanBodyEntity({
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
  final List<PostmanKeyValueEntity> formData;
  final List<PostmanKeyValueEntity> urlEncoded;
  final String graphQlQuery;
  final String graphQlVariables;
  final String filePath;
}
