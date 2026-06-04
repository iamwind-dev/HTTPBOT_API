import 'postman_collection_entity.dart';

class PostmanWorkspaceEntity {
  final String id;
  final String name;
  final String type;
  final List<PostmanCollectionEntity> collections;

  const PostmanWorkspaceEntity({
    required this.id,
    required this.name,
    required this.type,
    this.collections = const [],
  });

  PostmanWorkspaceEntity copyWith({
    String? id,
    String? name,
    String? type,
    List<PostmanCollectionEntity>? collections,
  }) {
    return PostmanWorkspaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      collections: collections ?? this.collections,
    );
  }

  bool get hasCollections => collections.isNotEmpty;
}
