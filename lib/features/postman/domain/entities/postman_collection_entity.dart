import 'postman_folder_entity.dart';

class PostmanCollectionEntity {
  final String id;
  final String name;
  final List<PostmanFolderEntity> folders;

  const PostmanCollectionEntity({
    required this.id,
    required this.name,
    this.folders = const [],
  });

  PostmanCollectionEntity copyWith({
    String? id,
    String? name,
    List<PostmanFolderEntity>? folders,
  }) {
    return PostmanCollectionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      folders: folders ?? this.folders,
    );
  }

  int get totalRequestCount {
    return folders.fold(0, (sum, item) => sum + item.requests.length);
  }
}
