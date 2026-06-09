import 'package:equatable/equatable.dart';

class OAuth2TokenRequestDebugInfo extends Equatable {
  const OAuth2TokenRequestDebugInfo({
    required this.method,
    required this.url,
    required this.headers,
    required this.bodyFields,
    required this.encodedBody,
  });

  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> bodyFields;
  final String encodedBody;

  @override
  List<Object> get props => [method, url, headers, bodyFields, encodedBody];
}

class OAuth2TokenResponseDebugInfo extends Equatable {
  const OAuth2TokenResponseDebugInfo({
    required this.statusCode,
    required this.headers,
    required this.jsonBody,
    required this.rawBody,
  });

  final int? statusCode;
  final Map<String, String> headers;
  final Map<String, Object?>? jsonBody;
  final String rawBody;

  @override
  List<Object?> get props => [statusCode, headers, jsonBody, rawBody];
}

class OAuth2TokenDetailsEntity extends Equatable {
  const OAuth2TokenDetailsEntity({
    required this.success,
    required this.resolvedAuthUrl,
    required this.accessToken,
    required this.tokenType,
    required this.scope,
    required this.request,
    required this.response,
    this.refreshToken,
    this.expiresIn,
  });

  final bool success;
  final String resolvedAuthUrl;
  final String accessToken;
  final String tokenType;
  final String scope;
  final String? refreshToken;
  final int? expiresIn;
  final OAuth2TokenRequestDebugInfo request;
  final OAuth2TokenResponseDebugInfo response;

  /// Returns the display token type while falling back to the OAuth bearer default.
  String get resolvedTokenType {
    final normalizedTokenType = tokenType.trim();
    if (normalizedTokenType.isEmpty) {
      return 'bearer';
    }

    return normalizedTokenType;
  }

  /// Creates a copy with any updated runtime fields applied.
  OAuth2TokenDetailsEntity copyWith({
    bool? success,
    String? resolvedAuthUrl,
    String? accessToken,
    String? tokenType,
    String? scope,
    String? refreshToken,
    int? expiresIn,
    OAuth2TokenRequestDebugInfo? request,
    OAuth2TokenResponseDebugInfo? response,
  }) => OAuth2TokenDetailsEntity(
    success: success ?? this.success,
    resolvedAuthUrl: resolvedAuthUrl ?? this.resolvedAuthUrl,
    accessToken: accessToken ?? this.accessToken,
    tokenType: tokenType ?? this.tokenType,
    scope: scope ?? this.scope,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresIn: expiresIn ?? this.expiresIn,
    request: request ?? this.request,
    response: response ?? this.response,
  );

  @override
  List<Object?> get props => [
    success,
    resolvedAuthUrl,
    accessToken,
    tokenType,
    scope,
    refreshToken,
    expiresIn,
    request,
    response,
  ];
}
