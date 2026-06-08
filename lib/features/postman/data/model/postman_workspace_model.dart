import '../../domain/entities/postman_workspace_entity.dart';
import 'postman_collection_model.dart';
import 'postman_variable_model.dart';

class PostmanWorkspaceModel {
  final String id;
  final String name;
  final String type;
  final String description;
  final List<PostmanVariableModel> variables;
  final List<PostmanCollectionModel> collections;

  const PostmanWorkspaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.variables = const [],
    this.collections = const [],
  });

  factory PostmanWorkspaceModel.fromListJson(Map<String, dynamic> json) {
    return PostmanWorkspaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  factory PostmanWorkspaceModel.fromDetailJson(Map<String, dynamic> json) {
    final rawCollections = (json['collections'] as List? ?? [])
        .whereType<Map>()
        .map(
          (item) => PostmanCollectionModel.fromListJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
    final variables = (json['variables'] as List? ?? [])
        .whereType<Map>()
        .map((item) => PostmanVariableModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return PostmanWorkspaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: _readDescription(json['description']),
      variables: variables,
      collections: rawCollections,
    );
  }

  static String _readDescription(Object? input) {
    if (input is String) {
      return input;
    }

    if (input is Map) {
      return Map<String, dynamic>.from(input)['content']?.toString() ?? '';
    }

    return '';
  }

  PostmanWorkspaceEntity toEntity() {
    return PostmanWorkspaceEntity(
      id: id,
      name: name,
      type: type,
      description: description,
      variables: variables.map((item) => item.toEntity()).toList(),
      collections: collections.map((item) => item.toEntity()).toList(),
    );
  }
}
