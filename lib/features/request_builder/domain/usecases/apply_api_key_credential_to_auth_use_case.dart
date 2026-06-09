import '../entities/request_auth_draft.dart';
import '../entities/saved_credential.dart';

class ApplyApiKeyCredentialToAuthUseCase {
  const ApplyApiKeyCredentialToAuthUseCase();

  /// Maps a saved API Key credential onto the current auth draft.
  ///
  /// Sets the auth type to API Key and replaces only the API Key payload,
  /// preserving any other auth-mode drafts already present.
  RequestAuthDraft call(RequestAuthDraft current, SavedCredential credential) =>
      current.copyWith(type: AuthType.apiKey, apiKey: credential.apiKey);
}
