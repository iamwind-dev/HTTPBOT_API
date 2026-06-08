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

  int get itemCount =>
      requests.length +
      folders.fold(0, (sum, item) => sum + item.itemCount);
}
