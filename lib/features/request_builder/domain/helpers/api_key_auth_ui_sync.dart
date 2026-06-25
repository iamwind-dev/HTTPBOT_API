import '../entities/request_auth_draft.dart';
import '../entities/request_key_value.dart';

class ApiKeyAuthSyncResult {
  const ApiKeyAuthSyncResult({
    required this.queryParameters,
    required this.headers,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
}

/// Synchronizes API Key auth with the visible query-param and header editor rows.
ApiKeyAuthSyncResult syncApiKeyAuthToRequestFields({
  required List<KeyValueItem> queryParameters,
  required List<KeyValueItem> headers,
  required RequestAuthDraft auth,
}) {
  final sanitizedQueryParameters = queryParameters
      .where((item) => !item.isSystemGeneratedApiKeyQueryParameter)
      .toList(growable: false);
  final sanitizedHeaders = headers
      .where((item) => !item.isSystemGeneratedApiKeyHeader)
      .toList(growable: false);

  if (auth.type != AuthType.apiKey) {
    return ApiKeyAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  final key = auth.apiKey.name.trim();
  final value = auth.apiKey.value;

  if (key.isEmpty || value.isEmpty) {
    return ApiKeyAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    );
  }

  return switch (auth.apiKey.location) {
    ApiKeyLocation.header => ApiKeyAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: _withApiKeyHeader(sanitizedHeaders, key: key, value: value),
    ),
    ApiKeyLocation.query => ApiKeyAuthSyncResult(
      queryParameters: _withApiKeyQueryParameter(
        sanitizedQueryParameters,
        key: key,
        value: value,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    ),
    ApiKeyLocation.cookie => ApiKeyAuthSyncResult(
      queryParameters: List<KeyValueItem>.unmodifiable(
        sanitizedQueryParameters,
      ),
      headers: List<KeyValueItem>.unmodifiable(sanitizedHeaders),
    ),
  };
}

/// Adds one API Key header when no user-defined header already owns the same key.
List<KeyValueItem> _withApiKeyHeader(
  List<KeyValueItem> headers, {
  required String key,
  required String value,
}) {
  final hasUserDefinedMatch = headers.any(
    (item) => item.key.trim().toLowerCase() == key.toLowerCase(),
  );

  if (hasUserDefinedMatch) {
    return List<KeyValueItem>.unmodifiable(headers);
  }

  return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
    ...headers,
    KeyValueItem(
      key: key,
      value: value,
      description: apiKeySystemGeneratedHeaderDescription,
    ),
  ]);
}

/// Adds one API Key query parameter when no user-defined parameter already owns the same key.
List<KeyValueItem> _withApiKeyQueryParameter(
  List<KeyValueItem> queryParameters, {
  required String key,
  required String value,
}) {
  final hasUserDefinedMatch = queryParameters.any((item) => item.key == key);

  if (hasUserDefinedMatch) {
    return List<KeyValueItem>.unmodifiable(queryParameters);
  }

  return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
    ...queryParameters,
    KeyValueItem(
      key: key,
      value: value,
      description: apiKeySystemGeneratedQueryParameterDescription,
    ),
  ]);
}
