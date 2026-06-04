import '../repositories/postman_session_repository.dart';

class SavePostmanApiKeyUseCase {
  final PostmanSessionRepository repository;

  SavePostmanApiKeyUseCase(this.repository);

  Future<void> call(String apiKey) => repository.saveApiKey(apiKey);
}
