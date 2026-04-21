import '../entities/postman_account_entity.dart';
import '../repositories/postman_session_repository.dart';

class SavePostmanAccountUseCase {
  final PostmanSessionRepository repository;

  SavePostmanAccountUseCase(this.repository);

  Future<void> call(PostmanAccountEntity account) =>
      repository.saveAccount(account);
}
