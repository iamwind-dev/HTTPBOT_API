import '../../domain/entities/postman_collection_entity.dart';
import 'postman_auth_model.dart';
import 'postman_folder_model.dart';
import 'postman_request_model.dart';
import 'postman_variable_model.dart';

class PostmanCollectionModel {
  final String id;
  final String name;
  final String description;
  final PostmanAuthModel auth;
  final List<PostmanVariableModel> variables;
  final List<PostmanFolderModel> folders;
  final List<PostmanRequestModel> requests;

  const PostmanCollectionModel({
    required this.id,
    required this.name,
    this.description = '',
    this.auth = const PostmanAuthModel(),
    this.variables = const [],
    this.folders = const [],
    this.requests = const [],
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
        .toList();
    final folders = items
        .where((item) => item['item'] != null)
        .map((item) => PostmanFolderModel.fromCollectionItem(Map<String, dynamic>.from(item)))
        .toList();
    final requests = items
        .where((item) => item['request'] != null)
        .map((item) => PostmanRequestModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final info = json['info'] is Map ? Map<String, dynamic>.from(json['info']) : <String, dynamic>{};
    final variables = (json['variable'] as List? ?? [])
        .whereType<Map>()
        .map((item) => PostmanVariableModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return PostmanCollectionModel(
      id: info['_postman_id']?.toString() ?? '',
      name: info['name']?.toString() ?? '',
      description: _readDescription(info['description']),
      auth: PostmanAuthModel.fromJson(json['auth']),
      variables: variables,
      folders: folders,
      requests: requests,
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

  PostmanCollectionEntity toEntity() {
    return PostmanCollectionEntity(
      id: id,
      name: name,
      description: description,
      auth: auth.toEntity(),
      variables: variables.map((e) => e.toEntity()).toList(),
      folders: folders.map((e) => e.toEntity()).toList(),
      requests: requests.map((e) => e.toEntity()).toList(),
    );
  }
}
