import 'package:equatable/equatable.dart';

import 'request_auth_draft.dart';

enum RequestAuthIssueType {
  unsupportedAuthType,
  missingCredentials,
  invalidConfiguration,
}

class RequestAuthIssue extends Equatable {
  const RequestAuthIssue({
    required this.type,
    required this.authType,
    required this.message,
    this.fieldName = '',
  });

  final RequestAuthIssueType type;
  final AuthType authType;
  final String message;
  final String fieldName;

  /// Returns true when the auth issue should prevent request execution.
  bool get isBlocking => true;

  @override
  List<Object> get props => [type, authType, message, fieldName];
}
