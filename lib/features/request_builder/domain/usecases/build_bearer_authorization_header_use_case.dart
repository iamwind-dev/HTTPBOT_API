import '../entities/request_auth_draft.dart';

class BuildBearerAuthorizationHeaderUseCase {
  const BuildBearerAuthorizationHeaderUseCase();

  /// Returns the Authorization header value while avoiding duplicate prefixes.
  String? call(BearerTokenAuthDraft bearerTokenAuth) {
    final token = bearerTokenAuth.token.trim();
    if (token.isEmpty) {
      return null;
    }

    final prefix = bearerTokenAuth.prefix.trim().isEmpty
        ? 'Bearer'
        : bearerTokenAuth.prefix.trim();
    final normalizedPrefix = '${prefix.toLowerCase()} ';

    if (token.toLowerCase().startsWith(normalizedPrefix)) {
      return token;
    }

    return '$prefix $token';
  }
}
