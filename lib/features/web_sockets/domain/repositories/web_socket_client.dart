abstract class WebSocketClient {
  /// Opens a WebSocket connection with resolved URL, headers, and settings.
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Map<String, String> headers,
    required Duration timeout,
    required bool verifySsl,
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
