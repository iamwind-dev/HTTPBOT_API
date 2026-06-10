import '../entities/postman_workspace_entity.dart';
import '../repositories/collection_repository.dart';

class GetPostmanWorkspaceDetailUseCase {
  final CollectionRepository repository;

  GetPostmanWorkspaceDetailUseCase(this.repository);

  Future<PostmanWorkspaceEntity> call({
    required String apiKey,
    required String workspaceId,
  }) {
    return repository.getWorkspaceDetail(
      apiKey: apiKey,
      workspaceId: workspaceId,
    );
  }
}
