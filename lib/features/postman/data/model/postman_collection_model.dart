import '../../domain/entities/postman_collection_entity.dart';
import 'postman_folder_model.dart';

class PostmanCollectionModel {
  final String id;
  final String name;
  final List<PostmanFolderModel> folders;

  const PostmanCollectionModel({
    required this.id,
    required this.name,
    this.folders = const [],
  });

  factory PostmanCollectionModel.fromListJson(Map<String, dynamic> json) {
    return PostmanCollectionModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  factory PostmanCollectionModel.fromDetailJson(Map<String, dynamic> json) {
    final items = (json['item'] as List? ?? [])
        .whereType<Map>()
        .map((e) => PostmanFolderModel.fromCollectionItem(
      Map<String, dynamic>.from(e),
    ))
        .where((e) => e.requests.isNotEmpty)
        .toList();

    return PostmanCollectionModel(
      id: json['info']?['_postman_id']?.toString() ?? '',
      name: json['info']?['name']?.toString() ?? '',
      folders: items,
    );
  }

  PostmanCollectionEntity toEntity() {
    return PostmanCollectionEntity(
      id: id,
      name: name,
      folders: folders.map((e) => e.toEntity()).toList(),
    );
  }
}