import 'dart:convert';

const _maskedUnavailableValue = '—';
const _fullyMaskedValue = '****';
const _sensitiveBodyFieldKeys = <String>{
  'access_token',
  'refresh_token',
  'client_secret',
  'code',
  'code_verifier',
  'id_token',
  'token',
};

/// Masks a secret while leaving a short prefix visible for user-facing debug output.
String maskSecret(String value, {int visiblePrefix = 8}) {
  final trimmedValue = value.trim();
  if (trimmedValue.isEmpty) {
    return _maskedUnavailableValue;
  }

  if (trimmedValue.length <= visiblePrefix) {
    return _fullyMaskedValue;
  }

  return '${trimmedValue.substring(0, visiblePrefix)}...';
}

/// Returns a masked value for one OAuth-sensitive request or response field.
String maskSensitiveFieldValue(String key, String value) {
  final normalizedKey = key.trim().toLowerCase();
  if (!_sensitiveBodyFieldKeys.contains(normalizedKey)) {
    return value;
  }

  if (normalizedKey == 'client_secret' || normalizedKey == 'code_verifier') {
    return _fullyMaskedValue;
  }

  return maskSecret(value);
}

/// Applies OAuth-sensitive masking to a flat body field map.
Map<String, String> maskSensitiveBodyFields(Map<String, String> fields) => {
  for (final entry in fields.entries)
    entry.key: maskSensitiveFieldValue(entry.key, entry.value),
};

/// Applies OAuth-sensitive masking to a JSON-like response body structure.
Map<String, Object?> maskSensitiveJsonFields(Map<String, Object?> fields) => {
  for (final entry in fields.entries)
    entry.key: switch (entry.value) {
      final String value => maskSensitiveFieldValue(entry.key, value),
      final Map<dynamic, dynamic> value => maskSensitiveJsonFields(
        Map<String, Object?>.from(value),
      ),
      final List<dynamic> value =>
        value
            .map(
              (item) => item is Map<dynamic, dynamic>
                  ? maskSensitiveJsonFields(Map<String, Object?>.from(item))
                  : item,
            )
            .toList(growable: false),
      _ => entry.value,
    },
};

/// Builds a form-urlencoded body preview from already-masked request fields.
String buildEncodedBodyPreview(Map<String, String> fields) => fields.entries
    .map(
      (entry) =>
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
    )
    .join('&');

/// Builds a pretty JSON preview from already-masked response fields.
String buildPrettyMaskedJson(Map<String, Object?> fields) =>
    const JsonEncoder.withIndent('  ').convert(maskSensitiveJsonFields(fields));

/// Masks an Authorization header value when it uses Basic credentials.
String maskAuthorizationHeaderValue(String value) {
  if (value.trim().toLowerCase().startsWith('basic ')) {
    return 'Basic $_fullyMaskedValue';
  }

  return value;
}
