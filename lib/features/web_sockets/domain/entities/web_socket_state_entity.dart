import 'package:equatable/equatable.dart';

import 'web_socket_event_entity.dart';
import 'web_socket_request_entity.dart';

enum WebSocketConnectionStatus {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketStateEntity extends Equatable {
  const WebSocketStateEntity({
    this.status = WebSocketConnectionStatus.idle,
    this.request = const WebSocketRequestEntity(
      id: 'default',
      name: 'Untitled',
    ),
    this.events = const <WebSocketEventEntity>[],
    this.errorMessage,
    this.isSending = false,
  });

  final WebSocketConnectionStatus status;
  final WebSocketRequestEntity request;
  final List<WebSocketEventEntity> events;
  final String? errorMessage;
  final bool isSending;

  /// Returns true when text or binary frames can be sent to the active socket.
  bool get canSend => status == WebSocketConnectionStatus.connected;

  /// Creates an immutable state copy with updated connection or editor fields.
  WebSocketStateEntity copyWith({
    WebSocketConnectionStatus? status,
    WebSocketRequestEntity? request,
    List<WebSocketEventEntity>? events,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isSending,
  }) => WebSocketStateEntity(
    status: status ?? this.status,
    request: request ?? this.request,
    events: events ?? this.events,
    errorMessage: clearErrorMessage
        ? null
        : (errorMessage ?? this.errorMessage),
    isSending: isSending ?? this.isSending,
  );

  @override
  List<Object?> get props => [status, request, events, errorMessage, isSending];
}
