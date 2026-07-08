import '../entities/request_auth_draft.dart';
import '../entities/saved_credential.dart';

class ApplyApiKeyCredentialToAuthUseCase {
  const ApplyApiKeyCredentialToAuthUseCase();

  /// Copies a saved credential auth config onto the current request.
  RequestAuthDraft call(RequestAuthDraft current, SavedCredential credential) =>
      credential.auth;
}
