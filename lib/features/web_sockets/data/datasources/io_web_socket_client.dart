import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../domain/repositories/web_socket_client.dart';

class IoWebSocketClient implements WebSocketClient {
  const IoWebSocketClient();

  /// Opens a mobile/desktop WebSocket using dart:io without adding a package.
  @override
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
    required bool verifySsl,
  }) async {
    final client = HttpClient();
    if (!verifySsl) {
      client.badCertificateCallback = (_, __, ___) => true;
    }
    client.connectionTimeout = timeout;

    final request = await client
        .openUrl('GET', _httpUpgradeUri(uri))
        .timeout(timeout);
    headers.forEach(request.headers.set);

    final key = _webSocketKey();
    request.headers
      ..set(HttpHeaders.connectionHeader, 'Upgrade')
      ..set(HttpHeaders.upgradeHeader, 'websocket')
      ..set('Sec-WebSocket-Key', key)
      ..set('Sec-WebSocket-Version', '13');

    final response = await request.close().timeout(timeout);
    final responseHeaders = _responseHeaders(response.headers);
    if (response.statusCode != HttpStatus.switchingProtocols) {
      await response.drain<void>();
      throw HttpException(
        'WebSocket upgrade failed: ${response.statusCode} ${response.reasonPhrase}',
        uri: uri,
      );
    }

    _validateAcceptHeader(response.headers.value('Sec-WebSocket-Accept'), key);

    final socket = await response.detachSocket();
    final webSocket = WebSocket.fromUpgradedSocket(
      socket,
      serverSide: false,
      protocol: response.headers.value('Sec-WebSocket-Protocol'),
    )..pingInterval = _webSocketPingInterval;

    return IoWebSocketConnection(webSocket, responseHeaders);
  }

  /// Converts ws/wss URLs into the HTTP URL used for the upgrade request.
  Uri _httpUpgradeUri(Uri uri) =>
      uri.replace(scheme: uri.scheme == 'wss' ? 'https' : 'http');

  /// Builds the random client key required by RFC 6455.
  String _webSocketKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Ensures the server accepted the exact client handshake key.
  void _validateAcceptHeader(String? acceptHeader, String key) {
    final expected = base64.encode(
      sha1.convert(utf8.encode('$key$_webSocketAcceptGuid')).bytes,
    );
    if (acceptHeader != expected) {
      throw const WebSocketException('Invalid WebSocket accept header.');
    }
  }

  /// Flattens the handshake response headers for the session event log.
  Map<String, String> _responseHeaders(HttpHeaders headers) {
    final result = <String, String>{};
    headers.forEach((name, values) {
      result[name] = values.join(', ');
    });
    return result;
  }
}

class IoWebSocketConnection implements WebSocketConnection {
  IoWebSocketConnection(this._socket, this.responseHeaders);

  final WebSocket _socket;

  @override
  final Map<String, String> responseHeaders;

  @override
  int? get closeCode => _socket.closeCode;

  @override
  String? get closeReason => _socket.closeReason;

  @override
  Stream<WebSocketFrameEntity> get stream => _socket.map((event) {
    if (event is String) {
      return WebSocketFrameEntity.text(event);
    }

    if (event is List<int>) {
      return WebSocketFrameEntity.binary(event);
    }

    return WebSocketFrameEntity.text(event.toString());
  });

  /// Closes the socket with the provided close code and reason.
  @override
  Future<void> close([int? code, String? reason]) {
    return _socket.close(code, reason);
  }

  /// Sends a binary frame to the active socket.
  @override
  Future<void> sendBinary(List<int> bytes) async {
    _socket.add(bytes);
  }

  /// Sends a text frame to the active socket.
  @override
  Future<void> sendText(String text) async {
    _socket.add(text);
  }
}

const _webSocketAcceptGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
const _webSocketPingInterval = Duration(seconds: 20);
