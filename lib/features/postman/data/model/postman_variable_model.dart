import '../../domain/entities/postman_variable_entity.dart';

class PostmanVariableModel {
  const PostmanVariableModel({
    required this.key,
    required this.value,
    this.type = '',
    this.isEnabled = true,
  });

  final String key;
  final String value;
  final String type;
  final bool isEnabled;

  factory PostmanVariableModel.fromJson(Map<String, dynamic> json) {
    return PostmanVariableModel(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      isEnabled: !(json['disabled'] == true),
    );
  }

  PostmanVariableEntity toEntity() {
    return PostmanVariableEntity(
      key: key,
      value: value,
      type: type,
      isEnabled: isEnabled,
    );
  }
}
