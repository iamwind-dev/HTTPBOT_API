import '../../../request_builder/domain/entities/request_auth_draft.dart';

enum WebSocketNtlmStage { negotiating, authenticating }

abstract class WebSocketClient {
  /// Opens a WebSocket connection with resolved URL, headers, and settings.
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
    required bool verifySsl,
    NtlmAuthDraft? ntlmAuth,
    void Function(WebSocketNtlmStage stage)? onNtlmStage,
  });
}

abstract class WebSocketConnection {
  /// Emits incoming text and binary frames from the active socket.
  Stream<WebSocketFrameEntity> get stream;

  /// Returns handshake headers when the platform client exposes them.
  Map<String, String> get responseHeaders;

  /// Returns the close code after the socket finishes, when available.
  int? get closeCode;

  /// Returns the close reason after the socket finishes, when available.
  String? get closeReason;

  /// Sends one text frame to the remote peer.
  Future<void> sendText(String text);

  /// Sends one binary frame to the remote peer.
  Future<void> sendBinary(List<int> bytes);

  /// Closes the socket with an optional close code and reason.
  Future<void> close([int? code, String? reason]);
}

class WebSocketHandshakeException implements Exception {
  const WebSocketHandshakeException({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.uri,
  });

  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final Uri uri;

  @override
  String toString() => 'WebSocket upgrade failed: $statusCode $reasonPhrase';
}

class WebSocketFrameEntity {
  const WebSocketFrameEntity._({this.text, this.binary});

  final String? text;
  final List<int>? binary;

  /// Creates a text frame received from or sent to the socket.
  factory WebSocketFrameEntity.text(String text) =>
      WebSocketFrameEntity._(text: text);

  /// Creates a binary frame received from or sent to the socket.
  factory WebSocketFrameEntity.binary(List<int> binary) =>
      WebSocketFrameEntity._(binary: binary);

  /// Returns true when this frame carries text payload.
  bool get isText => text != null;
}
