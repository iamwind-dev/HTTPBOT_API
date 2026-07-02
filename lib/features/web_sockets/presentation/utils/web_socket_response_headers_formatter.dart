const _knownHeaderNames = <String, String>{
  'connection': 'Connection',
  'date': 'Date',
  'fly-request-id': 'Fly-Request-Id',
  'origin': 'Origin',
  'sec-websocket-accept': 'Sec-WebSocket-Accept',
  'server': 'Server',
  'upgrade': 'Upgrade',
  'via': 'Via',
};

/// Normalizes common WebSocket handshake header names for display.
Map<String, String> normalizeWebSocketResponseHeaders(
  Map<String, String> headers,
) {
  final entries =
      headers.entries
          .where((entry) => entry.key.trim().isNotEmpty)
          .map(
            (entry) => MapEntry<String, String>(
              _formatHeaderName(entry.key.trim()),
              entry.value,
            ),
          )
          .toList()
        ..sort(
          (left, right) =>
              left.key.toLowerCase().compareTo(right.key.toLowerCase()),
        );

  return Map<String, String>.fromEntries(entries);
}

/// Formats WebSocket handshake response headers as screenshot-style JSON.
String formatWebSocketResponseHeaders(Map<String, String> headers) {
  final normalized = normalizeWebSocketResponseHeaders(headers);
  if (normalized.isEmpty) {
    return '{}';
  }

  final entries = normalized.entries.toList(growable: false);
  final buffer = StringBuffer('{\n');
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    final comma = index == entries.length - 1 ? '' : ',';
    buffer.writeln(
      '  "${_escapeJsonString(entry.key)}" : '
      '"${_escapeJsonString(entry.value)}"$comma',
    );
  }
  buffer.write('}');
  return buffer.toString();
}

String _formatHeaderName(String key) {
  final lowerKey = key.toLowerCase();
  final knownName = _knownHeaderNames[lowerKey];
  if (knownName != null) {
    return knownName;
  }

  return lowerKey
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join('-');
}

String _escapeJsonString(String value) =>
    value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
