import 'package:equatable/equatable.dart';

import 'request_auth_issue.dart';
import 'executed_request_snapshot.dart';
import 'request_draft.dart';
import 'request_test_result.dart';
import 'request_key_value.dart';
import 'request_resolution_issue.dart';
import 'http_cookie_entity.dart';
import 'http_exchange.dart';

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
    this.executedRequestSnapshot,
    this.exchanges = const <HttpExchange>[],
    this.responseCookies = const <HttpCookieEntity>[],
    this.testResults = const <RequestTestResult>[],
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
  final ExecutedRequestSnapshot? executedRequestSnapshot;
  final List<HttpExchange> exchanges;
  final List<HttpCookieEntity> responseCookies;
  final List<RequestTestResult> testResults;
  final List<RequestResolutionIssue> resolutionIssues;
  final List<RequestAuthIssue> authIssues;

  /// Returns true when the request was not sent because upstream validation or auth issues blocked execution.
  bool get wasBlocked => errorType == RequestExecutionErrorType.blocked;

  /// Returns true when the network transport failed independently of HTTP status codes.
  bool get hasTransportError =>
      errorType != null && errorType != RequestExecutionErrorType.blocked;

  /// Returns the raw payload size in bytes so the parser or UI can format it later.
  int get payloadSizeBytes => bodyBytes.length;

  RequestExecutionResult copyWith({
    RequestDraft? request,
    int? statusCode,
    String? statusMessage,
    List<KeyValueItem>? headers,
    List<int>? bodyBytes,
    String? bodyText,
    Duration? duration,
    RequestExecutionErrorType? errorType,
    bool clearErrorType = false,
    String? errorMessage,
    ExecutedRequestSnapshot? executedRequestSnapshot,
    List<HttpExchange>? exchanges,
    List<HttpCookieEntity>? responseCookies,
    List<RequestTestResult>? testResults,
    List<RequestResolutionIssue>? resolutionIssues,
    List<RequestAuthIssue>? authIssues,
  }) => RequestExecutionResult(
    request: request ?? this.request,
    statusCode: statusCode ?? this.statusCode,
    statusMessage: statusMessage ?? this.statusMessage,
    headers: headers ?? this.headers,
    bodyBytes: bodyBytes ?? this.bodyBytes,
    bodyText: bodyText ?? this.bodyText,
    duration: duration ?? this.duration,
    errorType: clearErrorType ? null : (errorType ?? this.errorType),
    errorMessage: errorMessage ?? this.errorMessage,
    executedRequestSnapshot:
        executedRequestSnapshot ?? this.executedRequestSnapshot,
    exchanges: exchanges ?? this.exchanges,
    responseCookies: responseCookies ?? this.responseCookies,
    testResults: testResults ?? this.testResults,
    resolutionIssues: resolutionIssues ?? this.resolutionIssues,
    authIssues: authIssues ?? this.authIssues,
  );

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
    executedRequestSnapshot,
    exchanges,
    responseCookies,
    testResults,
    resolutionIssues,
    authIssues,
  ];
}
