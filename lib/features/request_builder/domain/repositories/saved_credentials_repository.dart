import '../entities/saved_credential.dart';

abstract interface class SavedCredentialsRepository {
  /// Returns all persisted credentials.
  Future<List<SavedCredential>> getSavedCredentials();

  /// Persists the full credential list, replacing any previous value.
  Future<void> saveSavedCredentials(List<SavedCredential> credentials);
}
