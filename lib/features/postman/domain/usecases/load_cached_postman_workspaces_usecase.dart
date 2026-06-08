import '../entities/postman_workspace_entity.dart';
import '../repositories/collection_repository.dart';

class LoadCachedPostmanWorkspacesUseCase {
  final CollectionRepository repository;

  LoadCachedPostmanWorkspacesUseCase(this.repository);

  Future<List<PostmanWorkspaceEntity>> call() {
    return repository.loadCachedWorkspaces();
  }
}
