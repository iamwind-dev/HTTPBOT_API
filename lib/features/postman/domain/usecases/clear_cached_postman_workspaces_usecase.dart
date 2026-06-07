import '../repositories/collection_repository.dart';

class ClearCachedPostmanWorkspacesUseCase {
  final CollectionRepository repository;

  ClearCachedPostmanWorkspacesUseCase(this.repository);

  Future<void> call() {
    return repository.clearCachedWorkspaces();
  }
}
