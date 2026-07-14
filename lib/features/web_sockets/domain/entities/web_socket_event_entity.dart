import 'package:equatable/equatable.dart';

enum WebSocketEventType {
  lifecycle,
  sentText,
  receivedText,
  sentBinary,
  receivedBinary,
  ping,
  pong,
  disconnected,
  error,
}

class WebSocketEventEntity extends Equatable {
  const WebSocketEventEntity({
    required this.id,
    required this.type,
    required this.timestamp,
    this.title,
    this.text,
    this.binaryPreview,
    this.binarySizeBytes,
    this.fileName,
    this.errorMessage,
    this.responseHeaders,
    this.closeCode,
    this.closeReason,
  });

  final String id;
  final WebSocketEventType type;
  final DateTime timestamp;
  final String? title;
  final String? text;
  final List<int>? binaryPreview;
  final int? binarySizeBytes;
  final String? fileName;
  final String? errorMessage;
  final Map<String, String>? responseHeaders;
  final int? closeCode;
  final String? closeReason;

  @override
  List<Object?> get props => [
    id,
    type,
    timestamp,
    title,
    text,
    binaryPreview,
    binarySizeBytes,
    fileName,
    errorMessage,
    responseHeaders,
    closeCode,
    closeReason,
  ];
}
