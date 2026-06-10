
import '../entities/postman_account_entity.dart';
import '../entities/postman_collection_entity.dart';
import '../entities/postman_workspace_entity.dart';

abstract class CollectionRepository {
  Future<PostmanAccountEntity> getAuthenticatedUser({
    required String apiKey,
  });

  Future<List<PostmanWorkspaceEntity>> getWorkspaces({
    required String apiKey,
  });

  Future<PostmanWorkspaceEntity> getWorkspaceDetail({
    required String apiKey,
    required String workspaceId,
  });

  Future<List<PostmanCollectionEntity>> getCollections({
    required String apiKey,
  });

  Future<PostmanCollectionEntity> getCollectionDetail({
    required String apiKey,
    required String collectionId,
  });

  Future<List<PostmanWorkspaceEntity>> loadCachedWorkspaces();

  Future<void> saveCachedWorkspaces(List<PostmanWorkspaceEntity> workspaces);

  Future<void> clearCachedWorkspaces();

  Future<List<PostmanCollectionEntity>> loadCachedCollections();

  Future<void> saveCachedCollections(List<PostmanCollectionEntity> collections);

  Future<void> clearCachedCollections();
}
