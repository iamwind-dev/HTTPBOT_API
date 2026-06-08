import 'postman_collection_entity.dart';
import 'postman_variable_entity.dart';

class PostmanWorkspaceEntity {
  final String id;
  final String name;
  final String type;
  final String description;
  final List<PostmanVariableEntity> variables;
  final List<PostmanCollectionEntity> collections;

  const PostmanWorkspaceEntity({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.variables = const [],
    this.collections = const [],
  });

  PostmanWorkspaceEntity copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    List<PostmanVariableEntity>? variables,
    List<PostmanCollectionEntity>? collections,
  }) {
    return PostmanWorkspaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      variables: variables ?? this.variables,
      collections: collections ?? this.collections,
    );
  }

  bool get hasCollections => collections.isNotEmpty;
}
