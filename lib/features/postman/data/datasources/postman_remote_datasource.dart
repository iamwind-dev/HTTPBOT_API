import 'package:dio/dio.dart';
import '../model/postman_account_model.dart';
import '../model/postman_collection_model.dart';
import '../model/postman_workspace_model.dart';

abstract class PostmanRemoteDataSource {
  Future<PostmanAccountModel> getAuthenticatedUser({
    required String apiKey,
  });

  Future<List<PostmanWorkspaceModel>> getWorkspaces({
    required String apiKey,
  });

  Future<PostmanWorkspaceModel> getWorkspaceDetail({
    required String apiKey,
    required String workspaceId,
  });

  Future<List<PostmanCollectionModel>> getCollections({
    required String apiKey,
  });

  Future<PostmanCollectionModel> getCollectionDetail({
    required String apiKey,
    required String collectionId,
  });
}

class PostmanRemoteDataSourceImpl implements PostmanRemoteDataSource {
  final Dio dio;

  PostmanRemoteDataSourceImpl(this.dio);

  @override
  Future<PostmanAccountModel> getAuthenticatedUser({
    required String apiKey,
  }) async {
    final response = await dio.get(
      'https://api.getpostman.com/me',
      options: Options(
        headers: {
          'X-API-Key': apiKey,
        },
      ),
    );

    return PostmanAccountModel.fromJson(
      Map<String, dynamic>.from(response.data['user'] as Map? ?? const {}),
    );
  }

  @override
  Future<List<PostmanWorkspaceModel>> getWorkspaces({
    required String apiKey,
  }) async {
    final response = await dio.get(
      'https://api.getpostman.com/workspaces',
      options: Options(
        headers: {
          'X-API-Key': apiKey,
        },
      ),
    );

    final raw = (response.data['workspaces'] as List? ?? []);
    return raw
        .whereType<Map>()
        .map(
          (item) => PostmanWorkspaceModel.fromListJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  @override
  Future<PostmanWorkspaceModel> getWorkspaceDetail({
    required String apiKey,
    required String workspaceId,
  }) async {
    final response = await dio.get(
      'https://api.getpostman.com/workspaces/$workspaceId',
      options: Options(
        headers: {
          'X-API-Key': apiKey,
        },
      ),
    );

    return PostmanWorkspaceModel.fromDetailJson(
      Map<String, dynamic>.from(response.data['workspace']),
    );
  }

  @override
  Future<List<PostmanCollectionModel>> getCollections({
    required String apiKey,
  }) async {
    final response = await dio.get(
      'https://api.getpostman.com/collections',
      options: Options(
        headers: {
          'X-API-Key': apiKey,
        },
      ),
    );

    final raw = (response.data['collections'] as List? ?? []);
    return raw
        .whereType<Map>()
        .map((e) => PostmanCollectionModel.fromListJson(
      Map<String, dynamic>.from(e),
    ))
        .toList();
  }

  @override
  Future<PostmanCollectionModel> getCollectionDetail({
    required String apiKey,
    required String collectionId,
  }) async {
    final response = await dio.get(
      'https://api.getpostman.com/collections/$collectionId',
      options: Options(
        headers: {
          'X-API-Key': apiKey,
        },
      ),
    );

    return PostmanCollectionModel.fromDetailJson(
      Map<String, dynamic>.from(response.data['collection']),
    );
  }
}
