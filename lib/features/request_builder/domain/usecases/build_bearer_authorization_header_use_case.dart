import '../entities/request_auth_draft.dart';

/// Returns a token value without whitespace or a duplicated Bearer prefix.
String normalizeBearerToken(String input) {
  final value = input.trim();
  if (value.toLowerCase() == 'bearer') {
    return '';
  }
  if (value.toLowerCase().startsWith('bearer ')) {
    return value.substring(7).trim();
  }
  return value;
}

class BuildBearerAuthorizationHeaderUseCase {
  const BuildBearerAuthorizationHeaderUseCase();

  /// Returns the Authorization header value while avoiding duplicate prefixes.
  String? call(BearerTokenAuthDraft bearerTokenAuth) {
    final token = normalizeBearerToken(bearerTokenAuth.token);
    if (token.isEmpty) {
      return null;
    }

    final prefix = bearerTokenAuth.prefix.trim().isEmpty
        ? 'Bearer'
        : bearerTokenAuth.prefix.trim();
    return '$prefix $token';
  }
}
