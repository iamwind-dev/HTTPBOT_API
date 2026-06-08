import '../../domain/entities/postman_key_value_entity.dart';

class PostmanKeyValueModel {
  const PostmanKeyValueModel({
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

  factory PostmanKeyValueModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().trim().toLowerCase();
    return PostmanKeyValueModel(
      key: json['key']?.toString() ?? '',
      value: _readValue(json),
      isEnabled: !(json['disabled'] == true),
      type: rawType == 'file'
          ? PostmanKeyValueType.file
          : PostmanKeyValueType.text,
      contentType: json['contentType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  static String _readValue(Map<String, dynamic> json) {
    final src = json['src'];
    if (src is String) {
      return src;
    }

    return json['value']?.toString() ?? '';
  }

  PostmanKeyValueEntity toEntity() {
    return PostmanKeyValueEntity(
      key: key,
      value: value,
      isEnabled: isEnabled,
      type: type,
      contentType: contentType,
      description: description,
    );
  }
}
