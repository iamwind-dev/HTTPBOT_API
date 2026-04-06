import 'package:equatable/equatable.dart';

import 'request_execution_result.dart';

enum ParsedResponseBodyType { empty, json, text, binary, error }

class ParsedResponse extends Equatable {
  const ParsedResponse({
    required this.execution,
    required this.bodyType,
    this.formattedBody = '',
    this.contentType = '',
    this.isPrettyPrinted = false,
  });

  final RequestExecutionResult execution;
  final ParsedResponseBodyType bodyType;
  final String formattedBody;
  final String contentType;
  final bool isPrettyPrinted;

  /// Returns the payload size from the underlying execution result.
  int get payloadSizeBytes => execution.payloadSizeBytes;

  /// Returns true when the parsed response should be presented as an error state in the UI.
  bool get hasErrorState =>
      bodyType == ParsedResponseBodyType.error ||
      execution.errorType != null ||
      (execution.statusCode != null && execution.statusCode! >= 400);

  @override
  List<Object> get props => [
    execution,
    bodyType,
    formattedBody,
    contentType,
    isPrettyPrinted,
  ];
}
