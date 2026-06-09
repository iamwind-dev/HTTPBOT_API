import '../entities/request_auth_draft.dart';
import '../entities/request_key_value.dart';

class OAuth2AuthSyncResult {
  const OAuth2AuthSyncResult({
    required this.queryParameters,
    required this.headers,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
}

/// Synchronizes manual OAuth2 auth with the visible query-param and header editor rows.
OAuth2AuthSyncResult syncOAuth2AuthToRequestFields({
  required List<KeyValueItem> queryParameters,
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
}) {
  final sanitizedQueryParameters = queryParameters
      .where((item) => !item.isSystemGeneratedOAuth2QueryParameter)
      .toList(growable: false);
  final sanitizedHeaders = headers
      .where((item) => !item.isSystemGeneratedOAuth2Header)
      .toList(growable: false);

  if (auth.type != AuthType.oauth2 || !auth.oauth2.canApplyManualToken) {
    return OAuth2AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  if (auth.oauth2.sendsTokenAsHeader) {
    final hasUserDefinedAuthorization = sanitizedHeaders.any(
      (item) =>
          item.key.trim().toLowerCase() == 'authorization' &&
          !item.isSystemGeneratedAuthorizationHeader &&
          !item.isSystemGeneratedAwsHeader,
    );

    if (hasUserDefinedAuthorization) {
      return OAuth2AuthSyncResult(
        queryParameters: List<KeyValueItem>.unmodifiable(
          sanitizedQueryParameters,
        ),
        headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      );
    }

    return OAuth2AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
        ...sanitizedHeaders,
        KeyValueItem(
          key: 'Authorization',
          value: auth.oauth2.resolvedAuthorizationValue,
          description: oauth2SystemGeneratedHeaderDescription,
        ),
      ]),
    );
  }

  final hasUserDefinedAccessToken = sanitizedQueryParameters.any(
    (item) => item.key.trim() == 'access_token',
  );

  if (hasUserDefinedAccessToken) {
    return OAuth2AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  return OAuth2AuthSyncResult(
    queryParameters: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...sanitizedQueryParameters,
      KeyValueItem(
        key: 'access_token',
        value: auth.oauth2.accessToken.trim(),
        description: oauth2SystemGeneratedQueryParameterDescription,
      ),
    ]),
    headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
  );
}
