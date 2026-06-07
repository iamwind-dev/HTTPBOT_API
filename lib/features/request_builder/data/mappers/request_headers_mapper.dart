import '../../domain/entities/request_key_value.dart';

bool headersContainsContentType(Map<String, dynamic> headers) => headers.keys.any(
  (key) => key.trim().toLowerCase() == 'content-type',
);

Map<String, dynamic> buildEnabledHeaders(List<KeyValueItem> headers) {
  final enabledHeaders = <String, dynamic>{};

  for (final header in headers) {
    if (!header.isEnabled) {
      continue;
    }

    final trimmedKey = header.key.trim();
    if (trimmedKey.isEmpty) {
      continue;
    }

    enabledHeaders[trimmedKey] = header.value;
  }

  return enabledHeaders;
}

Map<String, dynamic> applyAutoContentTypeIfNeeded({
  required Map<String, dynamic> headers,
  required String? contentType,
  required bool canAutoAttachContentType,
}) {
  if (!canAutoAttachContentType) {
    return headers;
  }

  final trimmedContentType = contentType?.trim() ?? '';
  if (trimmedContentType.isEmpty) {
    return headers;
  }

  if (headersContainsContentType(headers)) {
    return headers;
  }

  return <String, dynamic>{
    ...headers,
    'Content-Type': trimmedContentType,
  };
}
