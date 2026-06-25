import 'postman_request_entity.dart';

class PostmanFolderEntity {
  final String id;
  final String name;
  final List<PostmanRequestEntity> requests;
  final List<PostmanFolderEntity> folders;

  const PostmanFolderEntity({
    required this.id,
    required this.name,
    this.requests = const [],
    this.folders = const [],
  });

  PostmanFolderEntity copyWith({
    String? id,
    String? name,
    List<PostmanRequestEntity>? requests,
    List<PostmanFolderEntity>? folders,
  }) => PostmanFolderEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    requests: requests ?? this.requests,
    folders: folders ?? this.folders,
  );

  int get itemCount =>
      requests.length +
      folders.fold(0, (sum, item) => sum + item.itemCount);
}
