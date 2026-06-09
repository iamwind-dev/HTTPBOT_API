import '../entities/saved_credential.dart';
import '../repositories/saved_credentials_repository.dart';

class SaveSavedCredentialsUseCase {
  const SaveSavedCredentialsUseCase(this._repository);

  final SavedCredentialsRepository _repository;

  /// Persists the full credential list.
  Future<void> call(List<SavedCredential> credentials) =>
      _repository.saveSavedCredentials(credentials);
}
