import 'package:equatable/equatable.dart';

import 'request_auth_issue.dart';
import 'request_draft.dart';
import 'request_key_value.dart';
import 'request_resolution_issue.dart';

enum RequestExecutionErrorType {
  blocked,
  timeout,
  connection,
  ssl,
  cancelled,
  unknown,
}

class RequestExecutionResult extends Equatable {
  const RequestExecutionResult({
    required this.request,
    this.statusCode,
    this.statusMessage = '',
    this.headers = const <KeyValueItem>[],
    this.bodyBytes = const <int>[],
    this.bodyText = '',
    this.duration = Duration.zero,
    this.errorType,
    this.errorMessage = '',
    this.resolutionIssues = const <RequestResolutionIssue>[],
    this.authIssues = const <RequestAuthIssue>[],
  });

  final RequestDraft request;
  final int? statusCode;
  final String statusMessage;
  final List<KeyValueItem> headers;
  final List<int> bodyBytes;
  final String bodyText;
  final Duration duration;
  final RequestExecutionErrorType? errorType;
  final String errorMessage;
  final List<RequestResolutionIssue> resolutionIssues;
  final List<RequestAuthIssue> authIssues;

  /// Returns true when the request was not sent because upstream validation or auth issues blocked execution.
  bool get wasBlocked => errorType == RequestExecutionErrorType.blocked;

  /// Returns true when the network transport failed independently of HTTP status codes.
  bool get hasTransportError =>
      errorType != null && errorType != RequestExecutionErrorType.blocked;

  /// Returns the raw payload size in bytes so the parser or UI can format it later.
  int get payloadSizeBytes => bodyBytes.length;

  @override
  List<Object?> get props => [
    request,
    statusCode,
    statusMessage,
    headers,
    bodyBytes,
    bodyText,
    duration,
    errorType,
    errorMessage,
    resolutionIssues,
    authIssues,
  ];
}
