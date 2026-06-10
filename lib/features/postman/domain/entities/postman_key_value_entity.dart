enum PostmanKeyValueType { text, file }

class PostmanKeyValueEntity {
  const PostmanKeyValueEntity({
    required this.key,
    required this.value,
    this.isEnabled = true,
    this.type = PostmanKeyValueType.text,
    this.contentType = '',
    this.description = '',
  });

  final String key;
  final String value;
  final bool isEnabled;
  final PostmanKeyValueType type;
  final String contentType;
  final String description;
}
