import 'package:equatable/equatable.dart';

import '../../../request_builder/domain/entities/parsed_response.dart';
import '../../../request_builder/domain/entities/request_execution_result.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';

class RequestHistoryResponseSnapshot extends Equatable {
  const RequestHistoryResponseSnapshot({
    this.statusCode,
    this.statusMessage = '',
    this.headers = const <KeyValueItem>[],
    this.payloadSizeBytes = 0,
    this.duration = Duration.zero,
    this.errorType,
    this.errorMessage = '',
    this.rawBody = '',
    this.formattedBody = '',
    this.contentType = '',
    this.bodyType = ParsedResponseBodyType.empty,
  });

  final int? statusCode;
  final String statusMessage;
  final List<KeyValueItem> headers;
  final int payloadSizeBytes;
  final Duration duration;
  final RequestExecutionErrorType? errorType;
  final String errorMessage;
  final String rawBody;
  final String formattedBody;
  final String contentType;
  final ParsedResponseBodyType bodyType;

  /// Returns true when the stored response represents an HTTP or transport failure.
  bool get hasError =>
      errorType != null || (statusCode != null && statusCode! >= 400);

  @override
  List<Object?> get props => [
    statusCode,
    statusMessage,
    headers,
    payloadSizeBytes,
    duration,
    errorType,
    errorMessage,
    rawBody,
    formattedBody,
    contentType,
    bodyType,
  ];
}
