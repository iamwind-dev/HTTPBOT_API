class OAuth2TokenResponse {
  const OAuth2TokenResponse({
    required this.accessToken,
    required this.tokenType,
    this.expiresIn,
    this.refreshToken,
    this.scope,
  });

  factory OAuth2TokenResponse.fromJson(Map<String, Object?> json) {
    final accessToken = json['access_token']?.toString().trim() ?? '';
    if (accessToken.isEmpty) {
      throw const FormatException('Missing access_token.');
    }

    return OAuth2TokenResponse(
      accessToken: accessToken,
      tokenType: json['token_type']?.toString().trim() ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      refreshToken: json['refresh_token']?.toString(),
      scope: json['scope']?.toString(),
    );
  }

  final String accessToken;
  final String tokenType;
  final int? expiresIn;
  final String? refreshToken;
  final String? scope;
}
