import '../../domain/entities/postman_account_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';

abstract class PostmanLocalDataSource {
  Future<String?> loadApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<PostmanAccountEntity?> loadAccount();

  Future<void> saveAccount(PostmanAccountEntity account);

  Future<List<PostmanWorkspaceEntity>> loadWorkspaces();

  Future<void> saveWorkspaces(List<PostmanWorkspaceEntity> workspaces);

  Future<List<PostmanCollectionEntity>> loadCollections();

  Future<void> saveCollections(List<PostmanCollectionEntity> collections);

  Future<void> clearApiKey();

  Future<void> clearAccount();

  Future<void> clearWorkspaces();

  Future<void> clearCollections();
}
