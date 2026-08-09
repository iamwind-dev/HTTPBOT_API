import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_applied_request.dart';
import '../../domain/entities/parsed_response.dart';
import '../../domain/entities/request_auth_issue.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_execution_result.dart';
import '../../domain/entities/request_resolution_issue.dart';
import '../../domain/entities/resolved_request.dart';

enum RequestSendStatus { initial, sending, blocked, completed }

class RequestSendState extends Equatable {
  /// Creates a state snapshot for the send pipeline with optional intermediate artifacts.
  const RequestSendState({
    required this.status,
    this.draft,
    this.resolvedRequest,
    this.authAppliedRequest,
    this.executionResult,
    this.parsedResponse,
    this.errorMessage = '',
  });

  /// Creates the idle state before any send attempt has started.
  const RequestSendState.initial()
    : status = RequestSendStatus.initial,
      draft = null,
      resolvedRequest = null,
      authAppliedRequest = null,
      executionResult = null,
      parsedResponse = null,
      errorMessage = '';

  /// Creates the in-flight state while the request pipeline is still running.
  const RequestSendState.sending({required RequestDraft draft})
    : this(status: RequestSendStatus.sending, draft: draft);

  /// Creates the blocked state when validation, resolution, or auth prevents execution.
  const RequestSendState.blocked({
    RequestDraft? draft,
    ResolvedRequest? resolvedRequest,
    AuthAppliedRequest? authAppliedRequest,
    RequestExecutionResult? executionResult,
    ParsedResponse? parsedResponse,
    required String errorMessage,
  }) : this(
         status: RequestSendStatus.blocked,
         draft: draft,
         resolvedRequest: resolvedRequest,
         authAppliedRequest: authAppliedRequest,
         executionResult: executionResult,
         parsedResponse: parsedResponse,
         errorMessage: errorMessage,
       );

  /// Creates the terminal state with the full pipeline output, including transport failures.
  const RequestSendState.completed({
    required RequestDraft draft,
    required ResolvedRequest resolvedRequest,
    required AuthAppliedRequest authAppliedRequest,
    required RequestExecutionResult executionResult,
    required ParsedResponse parsedResponse,
    String errorMessage = '',
  }) : this(
         status: RequestSendStatus.completed,
         draft: draft,
         resolvedRequest: resolvedRequest,
         authAppliedRequest: authAppliedRequest,
         executionResult: executionResult,
         parsedResponse: parsedResponse,
         errorMessage: errorMessage,
       );

  /// Creates a completed read-only state from a stored response execution.
  RequestSendState.history({
    required RequestExecutionResult executionResult,
    required ParsedResponse parsedResponse,
  }) : this(
         status: RequestSendStatus.completed,
         draft: executionResult.request,
         executionResult: executionResult,
         parsedResponse: parsedResponse,
       );

  final RequestSendStatus status;
  final RequestDraft? draft;
  final ResolvedRequest? resolvedRequest;
  final AuthAppliedRequest? authAppliedRequest;
  final RequestExecutionResult? executionResult;
  final ParsedResponse? parsedResponse;
  final String errorMessage;

  /// Returns the latest resolution issues produced anywhere in the send pipeline.
  List<RequestResolutionIssue> get resolutionIssues =>
      executionResult?.resolutionIssues ??
      authAppliedRequest?.resolutionIssues ??
      resolvedRequest?.issues ??
      const <RequestResolutionIssue>[];

  /// Returns the latest auth issues produced anywhere in the send pipeline.
  List<RequestAuthIssue> get authIssues =>
      executionResult?.authIssues ??
      authAppliedRequest?.authIssues ??
      const <RequestAuthIssue>[];

  /// Returns true when the state already has a parsed response ready for presentation.
  bool get hasParsedResponse => parsedResponse != null;

  @override
  List<Object?> get props => [
    status,
    draft,
    resolvedRequest,
    authAppliedRequest,
    executionResult,
    parsedResponse,
    errorMessage,
  ];
}
