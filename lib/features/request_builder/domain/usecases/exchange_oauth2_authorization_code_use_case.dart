import '../entities/oauth2_token_details_entity.dart';
import '../entities/request_auth_draft.dart';
import '../repositories/oauth2_repository.dart';

class ExchangeOAuth2AuthorizationCodeUseCase {
  const ExchangeOAuth2AuthorizationCodeUseCase(this._repository);

  final OAuth2Repository _repository;

  /// Exchanges an OAuth2 authorization code for an access token payload.
  Future<OAuth2TokenDetailsEntity> call({
    required OAuth2AuthDraft auth,
    required String code,
  }) => _repository.exchangeAuthorizationCode(auth: auth, code: code);
}
