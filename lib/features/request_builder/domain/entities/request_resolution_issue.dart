import 'package:equatable/equatable.dart';

enum RequestResolutionIssueType {
  missingVariable,
  disabledVariable,
  emptyVariable,
}

class RequestResolutionIssue extends Equatable {
  const RequestResolutionIssue({
    required this.type,
    required this.variableKey,
    required this.source,
    required this.placeholder,
  });

  final RequestResolutionIssueType type;
  final String variableKey;
  final String source;
  final String placeholder;

  /// Returns true when the unresolved placeholder should block request sending.
  bool get isBlocking => true;

  @override
  List<Object> get props => [type, variableKey, source, placeholder];
}
