import '../entities/postman_account_entity.dart';
import '../repositories/postman_session_repository.dart';

class LoadPostmanAccountUseCase {
  final PostmanSessionRepository repository;

  LoadPostmanAccountUseCase(this.repository);

  Future<PostmanAccountEntity?> call() => repository.loadAccount();
}
