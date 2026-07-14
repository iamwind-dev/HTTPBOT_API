import 'dart:convert';

const _jsonIndent = '  ';

/// Pretty-prints a decoded JSON value the way the Filter Response viewer expects:
/// objects/arrays indented two spaces, strings quoted, primitives bare.
String prettyPrintJsonValue(Object? value) {
  if (value is String) {
    return jsonEncode(value);
  }
  if (value == null || value is num || value is bool) {
    return jsonEncode(value);
  }
  return const JsonEncoder.withIndent(_jsonIndent).convert(value);
}

/// Pretty-prints a raw JSON document string, returning the original text when it
/// cannot be decoded so the viewer still shows something useful.
String prettyPrintJsonString(String body) {
  try {
    return prettyPrintJsonValue(jsonDecode(body));
  } on FormatException {
    return body;
  }
}
