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
