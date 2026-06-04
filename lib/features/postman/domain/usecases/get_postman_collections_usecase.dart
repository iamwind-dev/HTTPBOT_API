import '../entities/postman_collection_entity.dart';
import '../repositories/collection_repository.dart';

class GetPostmanCollectionsUseCase {
  final CollectionRepository repository;

  GetPostmanCollectionsUseCase(this.repository);

  Future<List<PostmanCollectionEntity>> call({
    required String apiKey,
  }) {
    return repository.getCollections(apiKey: apiKey);
  }
}