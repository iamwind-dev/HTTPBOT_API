import '../entities/request_auth_draft.dart';

class BuildBearerAuthorizationHeaderUseCase {
  const BuildBearerAuthorizationHeaderUseCase();

  /// Returns the Bearer Authorization header value when the token is present.
  String? call(BearerTokenAuthDraft bearerTokenAuth) {
    final token = bearerTokenAuth.token.trim();
    if (token.isEmpty) {
      return null;
    }

    return 'Bearer $token';
  }
}
