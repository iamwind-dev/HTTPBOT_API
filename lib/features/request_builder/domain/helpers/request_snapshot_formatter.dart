import '../entities/executed_request_snapshot.dart';

/// Builds the raw HTTP request text shown in the Response Editor's Request tab.
///
/// Mirrors the wire layout: a request line, header lines, then an optional body
/// separated by a blank line.
String buildRawRequest(ExecutedRequestSnapshot snapshot) {
  final buffer = StringBuffer()
    ..writeln(_buildRequestLine(snapshot));

  snapshot.headers.forEach((key, value) {
    buffer.writeln('$key: $value');
  });

  final body = snapshot.body;
  if (body != null && body.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..write(body);
    return buffer.toString();
  }

  // Drop the trailing newline left by the final writeln when there is no body.
  return buffer.toString().trimRight();
}

String _buildRequestLine(ExecutedRequestSnapshot snapshot) {
  final protocol = snapshot.protocol?.trim().isNotEmpty == true
      ? snapshot.protocol!.trim()
      : 'HTTP/1.1';
  return '${snapshot.method} ${_pathAndQuery(snapshot.url)} $protocol';
}

String _pathAndQuery(String rawUrl) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) {
    return rawUrl.isEmpty ? '/' : rawUrl;
  }

  final path = uri.path.isEmpty ? '/' : uri.path;
  return uri.hasQuery ? '$path?${uri.query}' : path;
}
