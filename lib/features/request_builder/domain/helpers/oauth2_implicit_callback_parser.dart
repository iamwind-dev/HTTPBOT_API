class OAuth2ImplicitCallbackData {
  const OAuth2ImplicitCallbackData({
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    required this.state,
    this.expiresIn,
  });

  final String accessToken;
  final String tokenType;
  final String scope;
  final String state;
  final int? expiresIn;
}

/// Validates an OAuth2 implicit callback URI and returns the token payload from the URL fragment.
OAuth2ImplicitCallbackData parseOAuth2ImplicitCallbackUri({
  required Uri callbackUri,
  required String expectedState,
}) {
  // Implicit providers return the token in the fragment; query is a fallback
  // for providers that deviate from the spec.
  final parameters = <String, String>{
    ...callbackUri.queryParameters,
    ..._parseFragmentParameters(callbackUri.fragment),
  };

  final error = parameters['error']?.trim() ?? '';
  if (error.isNotEmpty) {
    final errorDescription = parameters['error_description']?.trim();
    final detail = errorDescription?.isNotEmpty == true
        ? errorDescription!
        : error;
    throw FormatException(detail);
  }

  final accessToken = parameters['access_token']?.trim() ?? '';
  if (accessToken.isEmpty) {
    throw const FormatException('OAuth callback did not include access_token.');
  }

  final state = parameters['state']?.trim() ?? '';
  if (expectedState.trim().isNotEmpty && state != expectedState.trim()) {
    throw const FormatException('State mismatch.');
  }

  return OAuth2ImplicitCallbackData(
    accessToken: accessToken,
    tokenType: parameters['token_type']?.trim() ?? '',
    scope: parameters['scope']?.trim() ?? '',
    state: state,
    expiresIn: int.tryParse(parameters['expires_in']?.trim() ?? ''),
  );
}

/// Splits the URL fragment as query parameters, rejecting malformed encodings.
Map<String, String> _parseFragmentParameters(String fragment) {
  final trimmedFragment = fragment.trim();
  if (trimmedFragment.isEmpty) {
    return const <String, String>{};
  }

  try {
    return Uri.splitQueryString(trimmedFragment);
  } on FormatException {
    throw const FormatException('Invalid callback URL.');
  }
}
