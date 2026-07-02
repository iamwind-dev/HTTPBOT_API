/// Merges the standard headers an HTTP client adds on the wire into the
/// user-defined headers, so the Request tab reflects a faithful raw request.
///
/// These are not set by the app: `dart:io`'s `HttpClient` injects `Host`,
/// `Accept`, `Accept-Encoding`, and `Connection` automatically, and HTTP/2
/// connections add a `Priority` hint. They are only synthesized when the user
/// has not already provided an equivalent header (case-insensitive), and are
/// ordered first to match how a real request appears on the wire.
Map<String, String> withImplicitRequestHeaders({
  required String url,
  required Map<String, String> headers,
  String? protocol,
}) {
  final existingKeys = headers.keys
      .map((key) => key.trim().toLowerCase())
      .toSet();

  final isHttp2 = protocol?.trim().toLowerCase() == 'http/2';
  final defaults = <String, String>{
    'Host': _hostHeader(url),
    'Accept': '*/*',
    'Accept-Encoding': isHttp2 ? 'gzip, deflate, br' : 'gzip',
    'Connection': 'keep-alive',
    if (isHttp2) 'Priority': 'u=3, i',
  };

  final merged = <String, String>{};
  defaults.forEach((key, value) {
    if (value.isNotEmpty && !existingKeys.contains(key.toLowerCase())) {
      merged[key] = value;
    }
  });
  merged.addAll(headers);
  return merged;
}

String _hostHeader(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) {
    return '';
  }

  final isDefaultPort =
      !uri.hasPort ||
      (uri.scheme == 'https' && uri.port == 443) ||
      (uri.scheme == 'http' && uri.port == 80);
  return isDefaultPort ? uri.host : '${uri.host}:${uri.port}';
}
