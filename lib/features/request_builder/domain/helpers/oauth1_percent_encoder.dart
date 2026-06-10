import 'dart:convert';

/// Percent-encodes [value] using RFC 5849 OAuth 1.0a rules.
String oauth1PercentEncode(String value) {
  final buffer = StringBuffer();

  for (final byte in utf8.encode(value)) {
    final character = String.fromCharCode(byte);
    final isUnreserved =
        (byte >= 0x41 && byte <= 0x5A) ||
        (byte >= 0x61 && byte <= 0x7A) ||
        (byte >= 0x30 && byte <= 0x39) ||
        character == '-' ||
        character == '.' ||
        character == '_' ||
        character == '~';

    if (isUnreserved) {
      buffer.write(character);
      continue;
    }

    buffer.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
  }

  return buffer.toString();
}
