class PostmanVariableEntity {
  const PostmanVariableEntity({
    required this.key,
    required this.value,
    this.type = '',
    this.isEnabled = true,
  });

  final String key;
  final String value;
  final String type;
  final bool isEnabled;
}
