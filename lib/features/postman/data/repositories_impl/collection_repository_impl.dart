import '../../domain/entities/postman_account_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/repositories/collection_repository.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import '../datasources/postman_remote_datasource.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  final PostmanRemoteDataSource remoteDataSource;

  CollectionRepositoryImpl(this.remoteDataSource);

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
}
