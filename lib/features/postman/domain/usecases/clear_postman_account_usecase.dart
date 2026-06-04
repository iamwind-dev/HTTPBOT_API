import '../repositories/postman_session_repository.dart';

class ClearPostmanAccountUseCase {
  final PostmanSessionRepository repository;

  ClearPostmanAccountUseCase(this.repository);

  Future<void> call() => repository.clearAccount();
}
