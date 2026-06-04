import '../entities/postman_workspace_entity.dart';
import '../repositories/collection_repository.dart';

class GetPostmanWorkspacesUseCase {
  final CollectionRepository repository;

  GetPostmanWorkspacesUseCase(this.repository);

  Future<List<PostmanWorkspaceEntity>> call({
    required String apiKey,
  }) {
    return repository.getWorkspaces(apiKey: apiKey);
  }
}
