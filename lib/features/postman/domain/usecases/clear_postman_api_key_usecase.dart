import '../repositories/postman_session_repository.dart';

class ClearPostmanApiKeyUseCase {
  final PostmanSessionRepository repository;

  ClearPostmanApiKeyUseCase(this.repository);

  Future<void> call() => repository.clearApiKey();
}
