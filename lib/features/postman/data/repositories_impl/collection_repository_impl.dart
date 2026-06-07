import '../../domain/entities/postman_account_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/postman_local_datasource.dart';
import '../datasources/postman_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final PostmanRemoteDataSource remoteDataSource;
  final PostmanLocalDataSource localDataSource;

  CollectionRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<PostmanAccountEntity> getAuthenticatedUser({
    required String apiKey,
  }) async {
    final result = await remoteDataSource.getAuthenticatedUser(apiKey: apiKey);
    return result.toEntity();
  }

  @override
  Future<List<PostmanWorkspaceEntity>> getWorkspaces({
    required String apiKey,
  }) async {
    final result = await remoteDataSource.getWorkspaces(apiKey: apiKey);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PostmanWorkspaceEntity> getWorkspaceDetail({
    required String apiKey,
    required String workspaceId,
  }) async {
    final result = await remoteDataSource.getWorkspaceDetail(
      apiKey: apiKey,
      workspaceId: workspaceId,
    );
    return result.toEntity();
  }

  @override
  Future<List<PostmanCollectionEntity>> getCollections({
    required String apiKey,
  }) async {
    final result = await remoteDataSource.getCollections(apiKey: apiKey);
    return result.map((e) => e.toEntity()).toList();
  }

  @override
  Future<PostmanCollectionEntity> getCollectionDetail({
    required String apiKey,
    required String collectionId,
  }) async {
    final result = await remoteDataSource.getCollectionDetail(
      apiKey: apiKey,
      collectionId: collectionId,
    );
    return result.toEntity();
  }

  @override
  Future<List<PostmanWorkspaceEntity>> loadCachedWorkspaces() {
    return localDataSource.loadWorkspaces();
  }

  @override
  Future<void> saveCachedWorkspaces(List<PostmanWorkspaceEntity> workspaces) {
    return localDataSource.saveWorkspaces(workspaces);
  }

  @override
  Future<void> clearCachedWorkspaces() {
    return localDataSource.clearWorkspaces();
  }

  @override
  Future<List<PostmanCollectionEntity>> loadCachedCollections() {
    return localDataSource.loadCollections();
  }

  @override
  Future<void> saveCachedCollections(List<PostmanCollectionEntity> collections) {
    return localDataSource.saveCollections(collections);
  }

  @override
  Future<void> clearCachedCollections() {
    return localDataSource.clearCollections();
  }
}
