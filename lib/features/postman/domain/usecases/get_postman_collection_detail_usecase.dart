import '../entities/postman_collection_entity.dart';
import '../repositories/collection_repository.dart';

class GetPostmanCollectionDetailUseCase {
  final CollectionRepository repository;

  GetPostmanCollectionDetailUseCase(this.repository);

  Future<PostmanCollectionEntity> call({
    required String apiKey,
    required String collectionId,
  }) {
    return repository.getCollectionDetail(
      apiKey: apiKey,
      collectionId: collectionId,
    );
  }
}