import '../entities/postman_account_entity.dart';
import '../repositories/collection_repository.dart';

class GetPostmanAuthenticatedUserUseCase {
  final CollectionRepository repository;

  GetPostmanAuthenticatedUserUseCase(this.repository);

  Future<PostmanAccountEntity> call({
    required String apiKey,
  }) {
    return repository.getAuthenticatedUser(apiKey: apiKey);
  }
}
