import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'oauth1_request_signer.dart';

class OAuth1AuthSyncResult {
  const OAuth1AuthSyncResult({
    required this.queryParameters,
    required this.headers,
    this.authorizationHeaderPreview = '',
    this.errorMessage,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
  final String authorizationHeaderPreview;
  final String? errorMessage;
}

/// Synchronizes OAuth 1.0a auth with editor-managed header or query-param rows.
OAuth1AuthSyncResult syncOAuth1AuthToRequestFields({
  required List<KeyValueItem> queryParameters,
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
  required HttpMethod method,
  required String url,
  required RequestBodyDraft body,
  OAuth1RequestSigner? signer,
}) {
  final sanitizedQueryParameters = queryParameters
      .where((item) => !item.isSystemGeneratedOAuth1QueryParameter)
      .toList(growable: false);
  final sanitizedHeaders = headers
      .where((item) => !item.isSystemGeneratedOAuth1Header)
      .toList(growable: false);

  if (auth.type != AuthType.oauth1) {
    return OAuth1AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  final signingResult = (signer ?? OAuth1RequestSigner()).sign(
    method: method,
    url: url,
    queryParameters: sanitizedQueryParameters,
    body: body,
    auth: auth.oauth1,
  );
  if (!signingResult.isValid) {
    return OAuth1AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
      errorMessage: signingResult.errorMessage,
    );
  }

  if (auth.oauth1.asHeader) {
    final hasUserDefinedAuthorization = sanitizedHeaders.any(
      (item) =>
          item.key.trim().toLowerCase() == 'authorization' &&
          !item.isSystemGeneratedAuthorizationHeader &&
          !item.isSystemGeneratedAwsHeader,
    );
    if (hasUserDefinedAuthorization) {
      return OAuth1AuthSyncResult(
        queryParameters: List<KeyValueItem>.unmodifiable(
          sanitizedQueryParameters,
        ),
        headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
        errorMessage: 'Authorization header already exists as user-defined.',
      );
    }

    return OAuth1AuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
        ...sanitizedHeaders,
        KeyValueItem(
          key: 'Authorization',
          value: signingResult.authorizationHeader,
          description: oauth1SystemGeneratedHeaderDescription,
        ),
      ]),
      authorizationHeaderPreview: signingResult.authorizationHeaderPreview,
    );
  }

  final oauthQueryParameters = signingResult.oauthParameters.entries.map(
    (entry) => KeyValueItem(
      key: entry.key,
      value: entry.value,
      description: oauth1SystemGeneratedQueryParameterDescription,
    ),
  );

  return OAuth1AuthSyncResult(
    queryParameters: List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...sanitizedQueryParameters,
      ...oauthQueryParameters,
    ]),
    headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    authorizationHeaderPreview: signingResult.authorizationHeaderPreview,
  );
}
