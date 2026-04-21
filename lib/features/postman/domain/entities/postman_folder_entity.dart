import 'postman_request_entity.dart';

class PostmanFolderEntity {
  final String id;
  final String name;
  final List<PostmanRequestEntity> requests;

  const PostmanFolderEntity({
    required this.id,
    required this.name,
    required this.requests,
  });

  int get itemCount => requests.length;
}
