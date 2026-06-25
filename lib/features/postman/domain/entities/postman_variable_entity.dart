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

  PostmanVariableEntity copyWith({
    String? key,
    String? value,
    String? type,
    bool? isEnabled,
  }) => PostmanVariableEntity(
    key: key ?? this.key,
    value: value ?? this.value,
    type: type ?? this.type,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}
