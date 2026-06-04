import '../../domain/entities/postman_folder_entity.dart';
import 'postman_request_model.dart';

class PostmanFolderModel {
  final String id;
  final String name;
  final List<PostmanRequestModel> requests;

  const PostmanFolderModel({
    required this.id,
    required this.name,
    required this.requests,
  });

  factory PostmanFolderModel.fromCollectionItem(Map<String, dynamic> json) {
    final children = (json['item'] as List? ?? [])
        .whereType<Map>()
        .toList();

    final requests = children
        .where((item) => item['request'] != null)
        .map((item) => PostmanRequestModel.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();

    return PostmanFolderModel(
      id: json['id']?.toString() ?? json['name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      requests: requests,
    );
  }

  PostmanFolderEntity toEntity() {
    return PostmanFolderEntity(
      id: id,
      name: name,
      requests: requests.map((e) => e.toEntity()).toList(),
    );
  }
}
