import '../entities/oauth2_token_details_entity.dart';
import '../entities/request_auth_draft.dart';

abstract class OAuth2Repository {
  Future<OAuth2TokenDetailsEntity> exchangeAuthorizationCode({
    required OAuth2AuthDraft auth,
    required String code,
  });
}
