import '../../domain/entities/postman_workspace_entity.dart';
import 'postman_collection_model.dart';

class PostmanWorkspaceModel {
  final String id;
  final String name;
  final String type;
  final List<PostmanCollectionModel> collections;

  const PostmanWorkspaceModel({
    required this.id,
    required this.name,
    required this.type,
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

    return PostmanWorkspaceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      collections: rawCollections,
    );
  }

  PostmanWorkspaceEntity toEntity() {
    return PostmanWorkspaceEntity(
      id: id,
      name: name,
      type: type,
      collections: collections.map((item) => item.toEntity()).toList(),
    );
  }
}
