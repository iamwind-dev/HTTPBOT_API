import '../entities/postman_collection_entity.dart';
import '../repositories/collection_repository.dart';

class LoadCachedPostmanCollectionsUseCase {
  final CollectionRepository repository;

  LoadCachedPostmanCollectionsUseCase(this.repository);

  Future<List<PostmanCollectionEntity>> call() {
    return repository.loadCachedCollections();
  }
}
