import '../entities/request_auth_draft.dart';
import 'oauth2_pkce.dart';

/// Builds the Authorization Code authorize URL when the required OAuth2 config is present.
Uri? buildOAuth2AuthorizationUrl(OAuth2AuthDraft auth) {
  final authorizationUrl = auth.authorizationUrl.trim();
  final clientId = auth.clientId.trim();
  final redirectUri = auth.redirectUri.trim();

  if (authorizationUrl.isEmpty || clientId.isEmpty || redirectUri.isEmpty) {
    return null;
  }

  final baseUri = Uri.tryParse(authorizationUrl);
  if (baseUri == null || !baseUri.hasScheme) {
    return null;
  }

  final queryParameters = <String, String>{
    'response_type': 'code',
    'client_id': clientId,
    'redirect_uri': redirectUri,
  };

  final scope = auth.scope.trim();
  if (scope.isNotEmpty) {
    queryParameters['scope'] = scope;
  }

  final state = auth.state.trim();
  if (state.isNotEmpty) {
    queryParameters['state'] = state;
  }

  if (auth.usePkce && auth.codeVerifier.trim().isNotEmpty) {
    queryParameters['code_challenge'] = buildOAuth2CodeChallenge(
      codeVerifier: auth.codeVerifier.trim(),
      method: auth.pkceMethod,
    );
    queryParameters['code_challenge_method'] =
        auth.pkceMethod == OAuth2PkceMethod.sha256 ? 'S256' : 'plain';
  }

  for (final item in auth.authUrlParams) {
    final key = item.key.trim();
    if (!item.isEnabled || key.isEmpty || queryParameters.containsKey(key)) {
      continue;
    }

    queryParameters[key] = item.value;
  }

  return baseUri.replace(
    queryParameters: <String, String>{
      ...baseUri.queryParameters,
      ...queryParameters,
    },
  );
}
