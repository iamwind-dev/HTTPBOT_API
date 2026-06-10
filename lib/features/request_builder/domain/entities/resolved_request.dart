import 'package:equatable/equatable.dart';

import 'request_draft.dart';
import 'request_resolution_issue.dart';

class ResolvedRequest extends Equatable {
  const ResolvedRequest({
    required this.request,
    this.resolvedVariables = const <String, String>{},
    this.issues = const <RequestResolutionIssue>[],
  });

  final RequestDraft request;
  final Map<String, String> resolvedVariables;
  final List<RequestResolutionIssue> issues;

  /// Returns true when the resolved request still has issues that should stop sending.
  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);

  @override
  List<Object> get props => [
    request,
    issues,
    resolvedVariables.entries.toList(growable: false),
  ];
}
