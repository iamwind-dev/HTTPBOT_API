class OAuth2CallbackData {
  const OAuth2CallbackData({required this.code, required this.state});

  final String code;
  final String state;
}

/// Validates an OAuth2 callback URI and returns the authorization code payload.
OAuth2CallbackData parseOAuth2CallbackUri({
  required Uri callbackUri,
  required String expectedState,
}) {
  final error = callbackUri.queryParameters['error']?.trim() ?? '';
  if (error.isNotEmpty) {
    final errorDescription = callbackUri.queryParameters['error_description']
        ?.trim();
    final detail = errorDescription?.isNotEmpty == true
        ? errorDescription!
        : error;
    throw FormatException(detail);
  }

  final code = callbackUri.queryParameters['code']?.trim() ?? '';
  if (code.isEmpty) {
    throw const FormatException('OAuth callback did not include code.');
  }

  final state = callbackUri.queryParameters['state']?.trim() ?? '';
  if (expectedState.trim().isNotEmpty && state != expectedState.trim()) {
    throw const FormatException('State mismatch.');
  }

  return OAuth2CallbackData(code: code, state: state);
}
