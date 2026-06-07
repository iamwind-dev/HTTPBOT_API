import '../repositories/collection_repository.dart';

class ClearCachedPostmanCollectionsUseCase {
  final CollectionRepository repository;

  ClearCachedPostmanCollectionsUseCase(this.repository);

  Future<void> call() {
    return repository.clearCachedCollections();
  }
}
