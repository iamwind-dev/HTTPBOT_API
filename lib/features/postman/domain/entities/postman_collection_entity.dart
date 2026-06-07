import 'postman_auth_entity.dart';
import 'postman_folder_entity.dart';
import 'postman_request_entity.dart';
import 'postman_variable_entity.dart';

class PostmanCollectionEntity {
  final String id;
  final String name;
  final String description;
  final PostmanAuthEntity auth;
  final List<PostmanVariableEntity> variables;
  final List<PostmanFolderEntity> folders;
  final List<PostmanRequestEntity> requests;

  const PostmanCollectionEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.auth = const PostmanAuthEntity(),
    this.variables = const [],
    this.folders = const [],
    this.requests = const [],
  });

  PostmanCollectionEntity copyWith({
    String? id,
    String? name,
    String? description,
    PostmanAuthEntity? auth,
    List<PostmanVariableEntity>? variables,
    List<PostmanFolderEntity>? folders,
    List<PostmanRequestEntity>? requests,
  }) {
    return PostmanCollectionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      auth: auth ?? this.auth,
      variables: variables ?? this.variables,
      folders: folders ?? this.folders,
      requests: requests ?? this.requests,
    );
  }

  int get totalRequestCount {
    return requests.length + folders.fold(0, (sum, item) => sum + item.itemCount);
  }
}
