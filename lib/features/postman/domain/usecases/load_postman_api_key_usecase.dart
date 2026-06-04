import '../repositories/postman_session_repository.dart';

class LoadPostmanApiKeyUseCase {
  final PostmanSessionRepository repository;

  LoadPostmanApiKeyUseCase(this.repository);

  Future<String?> call() => repository.loadApiKey();
}
