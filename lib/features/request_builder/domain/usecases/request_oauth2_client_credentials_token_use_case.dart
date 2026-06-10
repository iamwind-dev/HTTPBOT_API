import '../entities/oauth2_token_details_entity.dart';
import '../entities/request_auth_draft.dart';
import '../repositories/oauth2_repository.dart';

class RequestOAuth2ClientCredentialsTokenUseCase {
  const RequestOAuth2ClientCredentialsTokenUseCase(this._repository);

  final OAuth2Repository _repository;

  /// Requests an OAuth2 access token with the client credentials grant.
  Future<OAuth2TokenDetailsEntity> call({required OAuth2AuthDraft auth}) =>
      _repository.requestClientCredentialsToken(auth: auth);
}
