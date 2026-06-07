import '../entities/postman_collection_entity.dart';
import '../repositories/collection_repository.dart';

class SaveCachedPostmanCollectionsUseCase {
  final CollectionRepository repository;

  SaveCachedPostmanCollectionsUseCase(this.repository);

  Future<void> call(List<PostmanCollectionEntity> collections) {
    return repository.saveCachedCollections(collections);
  }
}
