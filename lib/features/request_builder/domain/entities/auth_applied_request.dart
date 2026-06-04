import 'package:equatable/equatable.dart';

import 'request_auth_draft.dart';
import 'request_auth_issue.dart';
import 'request_draft.dart';
import 'request_resolution_issue.dart';

class AuthAppliedRequest extends Equatable {
  const AuthAppliedRequest({
    required this.request,
    required this.appliedAuthType,
    this.resolutionIssues = const <RequestResolutionIssue>[],
    this.authIssues = const <RequestAuthIssue>[],
  });

  final RequestDraft request;
  final AuthType appliedAuthType;
  final List<RequestResolutionIssue> resolutionIssues;
  final List<RequestAuthIssue> authIssues;

  /// Returns true when request execution should stop because resolution or auth application failed.
  bool get hasBlockingIssues =>
      resolutionIssues.any((issue) => issue.isBlocking) ||
      authIssues.any((issue) => issue.isBlocking);

  @override
  List<Object> get props => [
    request,
    appliedAuthType,
    resolutionIssues,
    authIssues,
  ];
}
