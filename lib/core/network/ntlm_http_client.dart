import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../features/request_builder/data/helpers/request_transport_inputs.dart';
import '../../features/request_builder/domain/entities/auth_applied_request.dart';
import '../../features/request_builder/domain/entities/executed_request_snapshot.dart';
import '../../features/request_builder/domain/entities/request_draft.dart';
import '../../features/request_builder/domain/entities/request_execution_result.dart';
import '../../features/request_builder/domain/entities/request_key_value.dart';
import 'ntlm/ntlm_messages.dart';

typedef HttpClientFactory = HttpClient Function();

/// Minimal parsed response from the raw Type-3 HTTP leg.
class _RawHttpResponse {
  _RawHttpResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final String reasonPhrase;
  final List<KeyValueItem> headers;
  final List<int> bodyBytes;
}

class NtlmHttpClient {
  NtlmHttpClient({HttpClientFactory? httpClientFactory})
    : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final HttpClientFactory _httpClientFactory;

  /// Executes [request] using an NTLMv2 three-way handshake.
  ///
  /// The handshake proceeds as follows:
  ///   1. A Type-1 (negotiate) request is sent via the pooled [HttpClient].
  ///   2. The server's Type-2 (challenge) token is read from `www-authenticate`.
  ///   3. The underlying socket is detached from [HttpClient] via
  ///      [HttpClientResponse.detachSocket], guaranteeing that the Type-3
  ///      (authenticate) request travels over the **exact same TCP connection**
  ///      that the server authenticated in step 1.
  ///   4. The Type-3 request is written manually over the detached [Socket]
  ///      and the response is parsed from it.
  ///
  /// Authentication failure (HTTP 401 on the Type-3 leg) yields a clear error
  /// result rather than throwing. Network, SSL, and format errors are mapped to
  /// typed [RequestExecutionErrorType] values; programming errors (Dart [Error]
  /// subclasses) are allowed to propagate so bugs surface immediately.
  Future<RequestExecutionResult> execute(AuthAppliedRequest request) async {
    final stopwatch = Stopwatch()..start();
    final draft = request.request;
    final ntlm = draft.auth.ntlm;
    final inputs = await buildRequestTransportInputs(draft);
    final uri = Uri.parse(inputs.url);
    final bodyBytes = _encodeBody(inputs);
    final settings = draft.settings;
    final requestHeaders = _injectSettingsUserAgent(
      headers: inputs.headers,
      userAgent: settings.normalizedUserAgent,
    );
    final executedRequestSnapshot = ExecutedRequestSnapshot(
      method: draft.method.wireName,
      url: inputs.url,
      headers: <String, String>{
        ...requestHeaders,
        HttpHeaders.authorizationHeader: 'NTLM ${createType1Message()}',
      },
      body: _buildRequestBodyPreview(inputs),
    );

    final client = _httpClientFactory();
    client.connectionTimeout = Duration(seconds: settings.timeoutSeconds);
    if (!settings.verifySsl) {
      client.badCertificateCallback = (_, _, _) => true;
    }

    try {
      // ── Type-1 (negotiate) ───────────────────────────────────────────────
      final httpRequest = await client.openUrl(draft.method.wireName, uri);
      httpRequest.persistentConnection = true;
      httpRequest.followRedirects = settings.followRedirects;
      requestHeaders.forEach(httpRequest.headers.set);
      httpRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'NTLM ${createType1Message()}',
      );
      final type1Response = await httpRequest.close();

      // Read www-authenticate BEFORE draining so the header is available.
      final challengeHeader = type1Response.headers['www-authenticate'];
      final challengeToken = selectNtlmChallenge(challengeHeader ?? const []);

      if (challengeToken == null) {
        await type1Response.drain<void>();
        return _errorResult(
          draft: draft,
          request: request,
          stopwatch: stopwatch,
          executedRequestSnapshot: executedRequestSnapshot,
          errorType: RequestExecutionErrorType.unknown,
          message: 'Server did not request NTLM authentication.',
        );
      }

      // ── Detach socket — own the connection from here on ─────────────────
      final socket = await type1Response.detachSocket();

      // ── Type-3 (authenticate) over the same socket ───────────────────────
      final type3 = createType3Message(
        type2: parseType2Message(challengeToken),
        username: ntlm.username.trim(),
        password: ntlm.password,
        domain: ntlm.domain.trim(),
        workstation: ntlm.workstation.trim(),
      );

      final _RawHttpResponse rawResponse;
      try {
        rawResponse = await _sendType3OverSocket(
          socket,
          method: draft.method.wireName,
          uri: uri,
          headers: requestHeaders,
          authorization: 'NTLM $type3',
          bodyBytes: bodyBytes,
        ).timeout(Duration(seconds: settings.timeoutSeconds));
      } on TimeoutException {
        socket.destroy();
        rethrow; // mapped by the outer handler to a timeout result
      }

      stopwatch.stop();

      if (rawResponse.statusCode == HttpStatus.unauthorized) {
        return RequestExecutionResult(
          request: draft,
          statusCode: rawResponse.statusCode,
          statusMessage: rawResponse.reasonPhrase,
          headers: rawResponse.headers,
          bodyBytes: rawResponse.bodyBytes,
          bodyText: utf8.decode(rawResponse.bodyBytes, allowMalformed: true),
          duration: stopwatch.elapsed,
          executedRequestSnapshot: executedRequestSnapshot,
          errorType: RequestExecutionErrorType.unknown,
          errorMessage:
              'NTLM authentication failed. Check username, password, and domain.',
          resolutionIssues: request.resolutionIssues,
          authIssues: request.authIssues,
        );
      }

      return RequestExecutionResult(
        request: draft,
        statusCode: rawResponse.statusCode,
        statusMessage: rawResponse.reasonPhrase,
        headers: rawResponse.headers,
        bodyBytes: rawResponse.bodyBytes,
        bodyText: utf8.decode(rawResponse.bodyBytes, allowMalformed: true),
        duration: stopwatch.elapsed,
        executedRequestSnapshot: executedRequestSnapshot,
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on TimeoutException {
      return _errorResult(
        draft: draft,
        request: request,
        stopwatch: stopwatch,
        executedRequestSnapshot: executedRequestSnapshot,
        errorType: RequestExecutionErrorType.timeout,
        message: 'Request timed out.',
      );
    } on FormatException {
      return _errorResult(
        draft: draft,
        request: request,
        stopwatch: stopwatch,
        executedRequestSnapshot: executedRequestSnapshot,
        errorType: RequestExecutionErrorType.unknown,
        message: 'Received a malformed NTLM challenge from the server.',
      );
    } on HandshakeException {
      return _errorResult(
        draft: draft,
        request: request,
        stopwatch: stopwatch,
        executedRequestSnapshot: executedRequestSnapshot,
        errorType: RequestExecutionErrorType.ssl,
        message: 'SSL handshake failed.',
      );
    } on SocketException {
      return _errorResult(
        draft: draft,
        request: request,
        stopwatch: stopwatch,
        executedRequestSnapshot: executedRequestSnapshot,
        errorType: RequestExecutionErrorType.connection,
        message: 'Network request failed.',
      );
    } on HttpException catch (error) {
      return _errorResult(
        draft: draft,
        request: request,
        stopwatch: stopwatch,
        executedRequestSnapshot: executedRequestSnapshot,
        errorType: RequestExecutionErrorType.unknown,
        message: error.message,
      );
    } finally {
      // After detachSocket the HttpClient no longer owns that socket; we
      // destroy it inside _sendType3OverSocket. Force-closing the client
      // here cleans up any other pooled connections.
      client.close(force: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Raw HTTP/1.1 Type-3 leg
  // ---------------------------------------------------------------------------

  /// Writes a complete HTTP/1.1 request for the Type-3 leg directly to
  /// [socket] (which was detached from the Type-1 [HttpClientResponse]) and
  /// returns the parsed response.
  ///
  /// Sending over the detached socket guarantees NTLM correctness: the server
  /// already authenticated this exact TCP connection during the Type-1/Type-2
  /// exchange.
  Future<_RawHttpResponse> _sendType3OverSocket(
    Socket socket, {
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String authorization,
    required List<int> bodyBytes,
  }) async {
    try {
      final requestBytes = _buildRawRequest(
        method: method,
        uri: uri,
        headers: headers,
        authorization: authorization,
        bodyBytes: bodyBytes,
      );

      socket.add(requestBytes);
      await socket.flush();

      // Read until the server closes the connection (Connection: close).
      final allBytes = await socket.fold<BytesBuilder>(
        BytesBuilder(copy: false),
        (builder, chunk) => builder..add(chunk),
      );
      final bytes = allBytes.takeBytes();

      return _parseRawResponse(bytes);
    } finally {
      socket.destroy();
    }
  }

  /// Builds the raw HTTP/1.1 request bytes for the Type-3 leg.
  List<int> _buildRawRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String authorization,
    required List<int> bodyBytes,
  }) {
    final pathAndQuery = uri.hasQuery
        ? '${uri.path}?${uri.query}'
        : (uri.path.isEmpty ? '/' : uri.path);

    final isDefaultPort =
        (uri.scheme == 'http' && uri.port == 80) ||
        (uri.scheme == 'https' && uri.port == 443);
    final hostHeader = isDefaultPort ? uri.host : '${uri.host}:${uri.port}';

    // Forbidden headers that we manage ourselves.
    const forbidden = {'host', 'content-length', 'authorization'};

    final buf = StringBuffer()
      ..write('$method $pathAndQuery HTTP/1.1\r\n')
      ..write('Host: $hostHeader\r\n');

    headers.forEach((name, value) {
      if (!forbidden.contains(name.toLowerCase())) {
        buf.write('$name: $value\r\n');
      }
    });

    buf
      ..write('Authorization: $authorization\r\n')
      ..write('Content-Length: ${bodyBytes.length}\r\n')
      ..write('Connection: close\r\n')
      ..write('\r\n');

    final headerBytes = ascii.encode(buf.toString());
    return [...headerBytes, ...bodyBytes];
  }

  /// Parses a complete HTTP/1.1 response from raw [bytes].
  ///
  /// Handles both identity-encoded and chunked transfer-encoded bodies.
  _RawHttpResponse _parseRawResponse(List<int> bytes) {
    // Locate the header/body boundary: \r\n\r\n = [13, 10, 13, 10].
    const separator = [13, 10, 13, 10];
    int boundaryIndex = -1;
    outer:
    for (int i = 0; i <= bytes.length - separator.length; i++) {
      for (int j = 0; j < separator.length; j++) {
        if (bytes[i + j] != separator[j]) continue outer;
      }
      boundaryIndex = i;
      break;
    }

    if (boundaryIndex == -1) {
      throw const FormatException('HTTP response missing header terminator');
    }

    final headerSection = ascii.decode(
      bytes.sublist(0, boundaryIndex),
      allowInvalid: true,
    );
    final bodyBytes = bytes.sublist(boundaryIndex + separator.length);

    final lines = headerSection.split('\r\n');
    if (lines.isEmpty) {
      throw const FormatException('HTTP response has no status line');
    }

    // Parse status line: HTTP/1.1 <code> <reason>
    final statusLine = lines[0];
    final spaceOne = statusLine.indexOf(' ');
    final spaceTwo = statusLine.indexOf(' ', spaceOne + 1);
    if (spaceOne == -1 || spaceTwo == -1) {
      throw FormatException('Malformed HTTP status line: $statusLine');
    }
    final statusCode = int.parse(statusLine.substring(spaceOne + 1, spaceTwo));
    final reasonPhrase = statusLine.substring(spaceTwo + 1);

    // Parse header lines.
    final responseHeaders = <KeyValueItem>[];
    String? transferEncoding;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;
      final colon = line.indexOf(':');
      if (colon == -1) continue;
      final name = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      responseHeaders.add(KeyValueItem(key: name, value: value));
      if (name == 'transfer-encoding') {
        transferEncoding = value.toLowerCase();
      }
    }

    // De-chunk if necessary — Connection: close avoids this in most cases, but
    // some servers always chunk.
    final finalBody =
        (transferEncoding != null && transferEncoding.contains('chunked'))
        ? _dechunk(bodyBytes)
        : bodyBytes;

    return _RawHttpResponse(
      statusCode: statusCode,
      reasonPhrase: reasonPhrase,
      headers: List<KeyValueItem>.unmodifiable(responseHeaders),
      bodyBytes: List<int>.unmodifiable(finalBody),
    );
  }

  /// Minimal chunked transfer-encoding decoder.
  ///
  /// Reads hex-length lines followed by that many data bytes until a
  /// zero-length chunk terminates the body.
  List<int> _dechunk(List<int> bytes) {
    final result = <int>[];
    int pos = 0;

    while (pos < bytes.length) {
      // Find end of chunk-size line (\r\n).
      int lineEnd = pos;
      while (lineEnd < bytes.length - 1 &&
          !(bytes[lineEnd] == 13 && bytes[lineEnd + 1] == 10)) {
        lineEnd++;
      }
      final sizeLine = ascii
          .decode(bytes.sublist(pos, lineEnd), allowInvalid: true)
          .trim();
      // Strip chunk extensions (anything after ';').
      final semi = sizeLine.indexOf(';');
      final hexStr = semi == -1 ? sizeLine : sizeLine.substring(0, semi);
      final chunkSize = int.parse(hexStr, radix: 16);
      pos = lineEnd + 2; // skip \r\n

      if (chunkSize == 0) break;

      result.addAll(bytes.sublist(pos, pos + chunkSize));
      pos += chunkSize + 2; // skip trailing \r\n
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<int> _encodeBody(RequestTransportInputs inputs) {
    if (!inputs.canSendBody) {
      return const <int>[];
    }
    final data = inputs.payload.data;
    if (data == null) {
      return const <int>[];
    }
    if (data is List<int>) {
      return data;
    }
    if (data is String) {
      return utf8.encode(data);
    }
    if (data is Map) {
      return utf8.encode(jsonEncode(data));
    }
    return utf8.encode(data.toString());
  }


  /// Stops [stopwatch] and returns a typed error [RequestExecutionResult].
  RequestExecutionResult _errorResult({
    required RequestDraft draft,
    required AuthAppliedRequest request,
    required Stopwatch stopwatch,
    required ExecutedRequestSnapshot executedRequestSnapshot,
    required RequestExecutionErrorType errorType,
    required String message,
  }) {
    stopwatch.stop();
    return RequestExecutionResult(
      request: draft,
      duration: stopwatch.elapsed,
      executedRequestSnapshot: executedRequestSnapshot,
      errorType: errorType,
      errorMessage: message,
      resolutionIssues: request.resolutionIssues,
      authIssues: request.authIssues,
    );
  }

  String? _buildRequestBodyPreview(RequestTransportInputs inputs) {
    if (!inputs.canSendBody) {
      return null;
    }

    final data = inputs.payload.data;
    if (data == null) {
      return null;
    }

    if (data is String) {
      return data;
    }

    if (data is Map) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }

    return data.toString();
  }

  Map<String, String> _injectSettingsUserAgent({
    required Map<String, String> headers,
    required String? userAgent,
  }) {
    if (userAgent == null) {
      return headers;
    }

    final hasManualUserAgent = headers.keys.any(
      (key) => key.trim().toLowerCase() == 'user-agent',
    );
    if (hasManualUserAgent) {
      return headers;
    }

    return <String, String>{...headers, 'User-Agent': userAgent};
  }
}
