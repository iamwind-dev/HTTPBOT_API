import '../entities/postman_workspace_entity.dart';
import '../repositories/collection_repository.dart';

class SaveCachedPostmanWorkspacesUseCase {
  final CollectionRepository repository;

  SaveCachedPostmanWorkspacesUseCase(this.repository);

  Future<void> call(List<PostmanWorkspaceEntity> workspaces) {
    return repository.saveCachedWorkspaces(workspaces);
  }
}
