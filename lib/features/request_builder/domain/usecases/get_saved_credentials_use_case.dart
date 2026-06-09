import '../entities/saved_credential.dart';
import '../repositories/saved_credentials_repository.dart';

class GetSavedCredentialsUseCase {
  const GetSavedCredentialsUseCase(this._repository);

  final SavedCredentialsRepository _repository;

  /// Loads all persisted credentials.
  Future<List<SavedCredential>> call() => _repository.getSavedCredentials();
}
