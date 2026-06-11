import '../entities/request_auth_draft.dart';
import '../entities/request_key_value.dart';
import 'jwt_token_builder.dart';

class JwtAuthSyncResult {
  /// Carries JWT-generated request fields or a stable validation error.
  const JwtAuthSyncResult({
    required this.queryParameters,
    required this.headers,
    this.generatedToken = '',
    this.errorMessage,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
  final String generatedToken;
  final String? errorMessage;
}

/// Synchronizes JWT auth with editor-managed Authorization or query-param rows.
JwtAuthSyncResult syncJwtAuthToRequestFields({
  required List<KeyValueItem> queryParameters,
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  JwtTokenBuilder tokenBuilder = const JwtTokenBuilder(),
}) {
  final sanitizedQueryParameters = queryParameters
      .where((item) => !item.isSystemGeneratedJwtQueryParameter)
      .toList(growable: false);
  final sanitizedHeaders = headers
      .where((item) => !item.isJwtSystemGeneratedHeader)
      .toList(growable: false);

  if (auth.type != AuthType.jwt) {
    return JwtAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  final buildResult = tokenBuilder.build(auth.jwt);
  if (!buildResult.isValid) {
    return JwtAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      errorMessage: buildResult.errorMessage,
    );
  }

  if (auth.jwt.sendAsHeader) {
    final hasUserDefinedAuthorization = sanitizedHeaders.any(
      (item) =>
          item.key.trim().toLowerCase() == 'authorization' &&
          !item.isSystemGeneratedAuthorizationHeader,
    );
    if (hasUserDefinedAuthorization) {
      return JwtAuthSyncResult(
        queryParameters: List<KeyValueItem>.unmodifiable(
          sanitizedQueryParameters,
        ),
        headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
        generatedToken: buildResult.token,
        errorMessage: 'Authorization header already exists as user-defined.',
      );
    }

    return JwtAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
        ...sanitizedHeaders,
        KeyValueItem(
          key: 'Authorization',
          value: auth.jwt.authorizationValueForToken(buildResult.token),
          description: jwtAuthSystemGeneratedHeaderDescription,
        ),
      ]),
      generatedToken: buildResult.token,
    );
  }

  final hasUserDefinedTokenParameter = sanitizedQueryParameters.any(
    (item) =>
        item.key.trim() == 'token' && !item.isSystemGeneratedJwtQueryParameter,
  );
  if (hasUserDefinedTokenParameter) {
    return JwtAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      generatedToken: buildResult.token,
      errorMessage: 'token query parameter already exists as user-defined.',
    );
  }

  return JwtAuthSyncResult(
    queryParameters: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...sanitizedQueryParameters,
      KeyValueItem(
        key: 'token',
        value: buildResult.token,
        description: jwtAuthSystemGeneratedQueryParameterDescription,
      ),
    ]),
    headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    generatedToken: buildResult.token,
  );
}
