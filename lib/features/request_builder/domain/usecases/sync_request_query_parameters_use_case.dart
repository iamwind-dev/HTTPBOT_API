import '../entities/request_key_value.dart';

class SyncRequestQueryParametersUseCase {
  const SyncRequestQueryParametersUseCase();

  /// Rebuilds the visible URL by appending only enabled inline query-param rows.
  String rebuildUrl({
    required String baseUrl,
    required List<KeyValueItem> queryParameters,
  }) {
    final managedQuery = _buildManagedQuery(queryParameters);
    if (managedQuery.isEmpty) {
      return baseUrl;
    }

    if (baseUrl.isEmpty) {
      return '?$managedQuery';
    }

    final separator = baseUrl.endsWith('?') || baseUrl.endsWith('&')
        ? ''
        : baseUrl.contains('?')
        ? '&'
        : '?';

    return '$baseUrl$separator$managedQuery';
  }

  /// Removes the current managed query-param suffix so repeated syncs do not duplicate it.
  String extractBaseUrl({
    required String url,
    required List<KeyValueItem> queryParameters,
  }) {
    final managedQuery = _buildManagedQuery(queryParameters);
    if (managedQuery.isEmpty) {
      return url;
    }

    final managedSuffixes = ['?$managedQuery', '&$managedQuery'];

    for (final suffix in managedSuffixes) {
      if (url.endsWith(suffix)) {
        return url.substring(0, url.length - suffix.length);
      }
    }

    return url;
  }

  /// Builds the inline query string exactly as the editor rows describe it.
  String _buildManagedQuery(List<KeyValueItem> queryParameters) =>
      queryParameters
          .where(_shouldIncludeInUrl)
          .map(_serializeQueryParameter)
          .join('&');

  /// Includes only enabled user rows; auth-generated params stay out of the
  /// visible URL and are appended to the execution URL at send time instead.
  bool _shouldIncludeInUrl(KeyValueItem item) =>
      item.isEnabled &&
      (item.key.isNotEmpty || item.value.isNotEmpty) &&
      !item.isSystemGeneratedJwtQueryParameter &&
      !item.isSystemGeneratedOAuth1QueryParameter &&
      !item.isSystemGeneratedOAuth2QueryParameter &&
      !item.isSystemGeneratedApiKeyQueryParameter;

  /// Serializes one row while intentionally preserving the `=value` shape for value-only entries.
  String _serializeQueryParameter(KeyValueItem item) {
    final encodedKey = Uri.encodeQueryComponent(item.key);
    final encodedValue = Uri.encodeQueryComponent(item.value);

    if (item.value.isEmpty) {
      return encodedKey;
    }

    return '$encodedKey=$encodedValue';
  }
}
