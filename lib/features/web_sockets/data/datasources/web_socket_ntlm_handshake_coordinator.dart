import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../../core/network/ntlm/ntlm_messages.dart';
import '../../domain/repositories/web_socket_client.dart';

enum WebSocketNtlmErrorKind {
  missingUsername,
  missingPassword,
  unsupportedPlatform,
  handshakeHeadersUnavailable,
  ntlmChallengeMissing,
  invalidNtlmChallenge,
  unsupportedNtlmVersion,
  authenticationFailed,
  handshakeRejected,
  timeout,
  cancelled,
}

class NtlmHandshakeCredentials {
  const NtlmHandshakeCredentials({
    required this.username,
    required this.password,
    this.domain = '',
    this.workstation = '',
  });

  final String username;
  final String password;
  final String domain;
  final String workstation;
}

class NtlmHandshakeContext {
  NtlmHandshakeContext(this.credentials);

  final NtlmHandshakeCredentials credentials;
  int step = 0;
  NtlmType2Message? challenge;

  /// Drops all mutable handshake artifacts at an attempt boundary.
  void clear() {
    step = 0;
    challenge = null;
  }
}

class WebSocketNtlmHandshakeResult {
  const WebSocketNtlmHandshakeResult({
    required this.webSocket,
    required this.responseHeaders,
  });

  final WebSocket webSocket;
  final Map<String, String> responseHeaders;
}

class WebSocketNtlmException implements Exception {
  const WebSocketNtlmException(this.kind, this.message);

  final WebSocketNtlmErrorKind kind;
  final String message;

  /// Returns only the stable safe error message.
  @override
  String toString() => message;
}

class WebSocketNtlmHandshakeCoordinator {
  const WebSocketNtlmHandshakeCoordinator();

  /// Negotiates NTLMv2 and upgrades a WebSocket on one raw socket.
  Future<WebSocketNtlmHandshakeResult> connect({
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
    required bool verifySsl,
    required NtlmHandshakeCredentials credentials,
    void Function(WebSocketNtlmStage stage)? onStage,
  }) async {
    _validateCredentials(credentials);
    final context = NtlmHandshakeContext(credentials);
    _SocketPump? pump;

    try {
      pump = await _connectSocket(uri, timeout: timeout, verifySsl: verifySsl);
      onStage?.call(WebSocketNtlmStage.negotiating);
      context.step = 1;
      final type1Key = _webSocketKey();
      await _sendHandshake(
        pump.socket,
        uri: uri,
        headers: headers,
        authorization: 'NTLM ${createType1Message()}',
        key: type1Key,
      );
      final type1 = await pump.readResponse(timeout);
      if (type1.statusCode != HttpStatus.unauthorized) {
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.handshakeRejected,
          'WebSocket handshake was rejected.',
        );
      }

      final authenticateHeaders =
          type1.headers[HttpHeaders.wwwAuthenticateHeader] ?? const <String>[];
      final challengeToken = selectNtlmChallenge(authenticateHeaders);
      if (challengeToken == null) {
        if (_hasMalformedNtlmChallenge(authenticateHeaders)) {
          throw const WebSocketNtlmException(
            WebSocketNtlmErrorKind.invalidNtlmChallenge,
            'The server returned an invalid NTLM challenge.',
          );
        }
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.ntlmChallengeMissing,
          'The server did not provide an NTLM challenge.',
        );
      }
      try {
        context.challenge = parseType2Message(challengeToken);
      } on FormatException {
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.invalidNtlmChallenge,
          'The server returned an invalid NTLM challenge.',
        );
      }

      final challenge = context.challenge;
      if (challenge == null) {
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.invalidNtlmChallenge,
          'The server returned an invalid NTLM challenge.',
        );
      }
      final type3Token = createType3Message(
        type2: challenge,
        username: credentials.username.trim(),
        password: credentials.password,
        domain: credentials.domain.trim(),
        workstation: credentials.workstation.trim(),
      );

      onStage?.call(WebSocketNtlmStage.authenticating);
      context.step = 2;
      final type3Key = _webSocketKey();
      await _sendHandshake(
        pump.socket,
        uri: uri,
        headers: headers,
        authorization: 'NTLM $type3Token',
        key: type3Key,
      );
      final type3 = await pump.readResponse(timeout);
      if (type3.statusCode == HttpStatus.unauthorized) {
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.authenticationFailed,
          'NTLM authentication failed.',
        );
      }
      if (type3.statusCode != HttpStatus.switchingProtocols) {
        throw const WebSocketNtlmException(
          WebSocketNtlmErrorKind.handshakeRejected,
          'WebSocket handshake was rejected.',
        );
      }

      _validateAcceptHeader(
        type3.headerValue('sec-websocket-accept'),
        type3Key,
      );
      final webSocket = WebSocket.fromUpgradedSocket(
        pump.detach(),
        serverSide: false,
        protocol: type3.headerValue('sec-websocket-protocol'),
      )..pingInterval = const Duration(seconds: 20);
      pump = null;
      return WebSocketNtlmHandshakeResult(
        webSocket: webSocket,
        responseHeaders: type3.flatHeaders,
      );
    } on TimeoutException {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.timeout,
        'WebSocket NTLM handshake timed out.',
      );
    } on WebSocketNtlmException {
      rethrow;
    } on SocketException {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.handshakeRejected,
        'WebSocket handshake failed.',
      );
    } finally {
      context.clear();
      pump?.destroy();
    }
  }

  /// Opens the TCP or TLS socket used for both NTLM legs.
  Future<_SocketPump> _connectSocket(
    Uri uri, {
    required Duration timeout,
    required bool verifySsl,
  }) async {
    final port = _portFor(uri);
    final socket = uri.scheme == 'wss'
        ? await SecureSocket.connect(
            uri.host,
            port,
            timeout: timeout,
            onBadCertificate: verifySsl ? null : (_) => true,
          )
        : await Socket.connect(uri.host, port, timeout: timeout);
    return _SocketPump(socket);
  }

  /// Validates credentials again at the transport boundary for direct callers.
  void _validateCredentials(NtlmHandshakeCredentials credentials) {
    if (credentials.username.trim().isEmpty) {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.missingUsername,
        'Username is required for NTLM Auth.',
      );
    }
    if (credentials.password.isEmpty) {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.missingPassword,
        'Password is required for NTLM Auth.',
      );
    }
  }

  /// Detects an NTLM challenge token that was present but not parseable.
  bool _hasMalformedNtlmChallenge(Iterable<String> values) {
    final pattern = RegExp(r'(?:^|,)\s*NTLM\s+([^,\s]+)', caseSensitive: false);
    return values.any(pattern.hasMatch);
  }

  /// Writes one HTTP WebSocket upgrade request onto the active socket.
  Future<void> _sendHandshake(
    Socket socket, {
    required Uri uri,
    required Map<String, String> headers,
    required String authorization,
    required String key,
  }) async {
    final request = StringBuffer()
      ..write('GET ${_pathAndQuery(uri)} HTTP/1.1\r\n')
      ..write('Host: ${_hostHeader(uri)}\r\n');
    _writeUserHeaders(request, headers);
    request
      ..write('Authorization: $authorization\r\n')
      ..write('Connection: Upgrade\r\n')
      ..write('Upgrade: websocket\r\n')
      ..write('Sec-WebSocket-Key: $key\r\n')
      ..write('Sec-WebSocket-Version: 13\r\n')
      ..write('\r\n');

    socket.add(ascii.encode(request.toString()));
    await socket.flush();
  }

  /// Writes user headers without letting them override protocol-owned fields.
  void _writeUserHeaders(StringBuffer request, Map<String, String> headers) {
    const forbidden = <String>{
      'host',
      'authorization',
      'connection',
      'upgrade',
      'sec-websocket-key',
      'sec-websocket-version',
    };
    headers.forEach((name, value) {
      if (!forbidden.contains(name.trim().toLowerCase())) {
        request.write('$name: $value\r\n');
      }
    });
  }

  /// Returns the request target used by the WebSocket HTTP upgrade.
  String _pathAndQuery(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }

  /// Returns the Host header, including non-default ports.
  String _hostHeader(Uri uri) {
    final port = _portFor(uri);
    final isDefault =
        (uri.scheme == 'ws' && port == 80) ||
        (uri.scheme == 'wss' && port == 443);
    return isDefault ? uri.host : '${uri.host}:$port';
  }

  /// Returns the effective network port for a WebSocket URI.
  int _portFor(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return uri.scheme == 'wss' ? 443 : 80;
  }

  /// Builds a fresh RFC 6455 client key for one handshake leg.
  String _webSocketKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Validates the server's RFC 6455 accept value without exposing it.
  void _validateAcceptHeader(String? value, String key) {
    final expected = base64.encode(
      sha1.convert(utf8.encode('$key$_webSocketAcceptGuid')).bytes,
    );
    if (value != expected) {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.handshakeRejected,
        'The server returned an invalid WebSocket accept header.',
      );
    }
  }
}

class _SocketPump {
  _SocketPump(this.socket) {
    _subscription = socket.listen(
      _onData,
      onError: _controller.addError,
      onDone: _controller.close,
      cancelOnError: true,
    );
  }

  final Socket socket;
  final _pending = <int>[];
  final _waiters = <Completer<void>>[];
  final _controller = StreamController<Uint8List>(sync: true);
  late final StreamSubscription<Uint8List> _subscription;
  bool _detached = false;

  /// Reads one HTTP response header block from the socket stream.
  Future<_RawHandshakeResponse> readResponse(Duration timeout) async {
    final bytes = <int>[];
    while (true) {
      final boundary = _headerBoundary(bytes);
      if (boundary != -1) {
        final remainder = bytes.sublist(boundary + 4);
        if (remainder.isNotEmpty) {
          _pending.insertAll(0, remainder);
        }
        return _RawHandshakeResponse.parse(bytes.sublist(0, boundary));
      }
      if (_pending.isEmpty) {
        await _waitForData().timeout(timeout);
      }
      bytes.addAll(_pending);
      _pending.clear();
    }
  }

  /// Hands the still-open socket to WebSocket after replaying buffered bytes.
  Socket detach() {
    _detached = true;
    if (_pending.isNotEmpty) {
      _controller.add(Uint8List.fromList(_pending));
      _pending.clear();
    }
    return _BufferedSocket(socket, _controller.stream, _subscription);
  }

  /// Closes the socket when the handshake exits before upgrade.
  void destroy() {
    if (!_detached) {
      unawaited(_subscription.cancel());
      socket.destroy();
      unawaited(_controller.close());
    }
  }

  /// Buffers incoming data until the WebSocket wrapper listens.
  void _onData(Uint8List data) {
    if (_detached) {
      _controller.add(data);
      return;
    }
    _pending.addAll(data);
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
    _waiters.clear();
  }

  /// Waits until at least one new socket chunk arrives.
  Future<void> _waitForData() {
    if (_pending.isNotEmpty) {
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  /// Finds the CRLFCRLF boundary in accumulated header bytes.
  int _headerBoundary(List<int> bytes) {
    for (var index = 0; index <= bytes.length - 4; index++) {
      if (bytes[index] == 13 &&
          bytes[index + 1] == 10 &&
          bytes[index + 2] == 13 &&
          bytes[index + 3] == 10) {
        return index;
      }
    }
    return -1;
  }
}

class _BufferedSocket extends Stream<Uint8List> implements Socket {
  _BufferedSocket(this._socket, this._stream, this._subscription);

  final Socket _socket;
  final Stream<Uint8List> _stream;
  final StreamSubscription<Uint8List> _subscription;

  @override
  Encoding encoding = utf8;

  @override
  InternetAddress get address => _socket.address;

  @override
  Future<void> get done => _socket.done;

  @override
  int get port => _socket.port;

  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;

  @override
  int get remotePort => _socket.remotePort;

  /// Forwards WebSocket reads through the already-owned socket subscription.
  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  void add(List<int> data) => _socket.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _socket.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<List<int>> stream) => _socket.addStream(stream);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _socket.close();
  }

  @override
  void destroy() {
    unawaited(_subscription.cancel());
    _socket.destroy();
  }

  @override
  Future<void> flush() => _socket.flush();

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);

  @override
  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);

  @override
  void write(Object? object) => _socket.write(object);

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _socket.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => _socket.writeln(object);
}

class _RawHandshakeResponse {
  const _RawHandshakeResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
  });

  final int statusCode;
  final String reasonPhrase;
  final Map<String, List<String>> headers;

  /// Parses a raw HTTP response header block.
  factory _RawHandshakeResponse.parse(List<int> bytes) {
    final lines = ascii
        .decode(bytes, allowInvalid: true)
        .split('\r\n')
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.handshakeRejected,
        'WebSocket handshake was rejected.',
      );
    }
    final status = RegExp(
      r'^HTTP/\d\.\d\s+(\d{3})(?:\s+(.*))?$',
    ).firstMatch(lines.first);
    if (status == null) {
      throw const WebSocketNtlmException(
        WebSocketNtlmErrorKind.handshakeRejected,
        'WebSocket handshake was rejected.',
      );
    }

    final headers = <String, List<String>>{};
    for (final line in lines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon <= 0) {
        continue;
      }
      final name = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      headers.putIfAbsent(name, () => <String>[]).add(value);
    }

    return _RawHandshakeResponse(
      statusCode: int.parse(status.group(1) ?? '0'),
      reasonPhrase: status.group(2) ?? '',
      headers: headers,
    );
  }

  /// Returns the first value for a case-normalized response header.
  String? headerValue(String name) => headers[name.toLowerCase()]?.first;

  /// Flattens response headers for existing session metadata.
  Map<String, String> get flatHeaders =>
      headers.map((name, values) => MapEntry(name, values.join(', ')));
}

const _webSocketAcceptGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
