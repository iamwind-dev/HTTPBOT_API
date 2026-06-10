import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/helpers/request_auth_validator.dart';
import '../../domain/usecases/apply_request_auth_use_case.dart';
import '../../domain/usecases/execute_request_use_case.dart';
import '../../domain/usecases/parse_response_use_case.dart';
import '../../domain/usecases/resolve_request_use_case.dart';
import '../../../request_history/domain/usecases/save_request_history_entry_use_case.dart';
import 'request_send_event.dart';
import 'request_send_state.dart';

class RequestSendBloc extends Bloc<RequestSendEvent, RequestSendState> {
  /// Wires the request send pipeline so presentation triggers a single event for the full flow.
  RequestSendBloc({
    required ResolveRequestUseCase resolveRequestUseCase,
    required ApplyRequestAuthUseCase applyRequestAuthUseCase,
    required ExecuteRequestUseCase executeRequestUseCase,
    required ParseResponseUseCase parseResponseUseCase,
    required SaveRequestHistoryEntryUseCase saveRequestHistoryEntryUseCase,
  }) : _resolveRequestUseCase = resolveRequestUseCase,
       _applyRequestAuthUseCase = applyRequestAuthUseCase,
       _executeRequestUseCase = executeRequestUseCase,
       _parseResponseUseCase = parseResponseUseCase,
       _saveRequestHistoryEntryUseCase = saveRequestHistoryEntryUseCase,
       super(const RequestSendState.initial()) {
    on<RequestSendRequested>(_onRequestSendRequested);
    on<RequestSendResetRequested>(_onRequestSendResetRequested);
  }

  final ResolveRequestUseCase _resolveRequestUseCase;
  final ApplyRequestAuthUseCase _applyRequestAuthUseCase;
  final ExecuteRequestUseCase _executeRequestUseCase;
  final ParseResponseUseCase _parseResponseUseCase;
  final SaveRequestHistoryEntryUseCase _saveRequestHistoryEntryUseCase;

  /// Runs the full send pipeline from validation through parsed response output.
  Future<void> _onRequestSendRequested(
    RequestSendRequested event,
    Emitter<RequestSendState> emit,
  ) async {
    final validationError = _validateDraft(event.draft);
    if (validationError != null) {
      emit(
        RequestSendState.blocked(
          draft: event.draft,
          errorMessage: validationError,
        ),
      );
      return;
    }

    emit(RequestSendState.sending(draft: event.draft));

    final resolvedRequest = _resolveRequestUseCase(
      draft: event.draft,
      variableStore: event.variableStore,
    );
    final authAppliedRequest = _applyRequestAuthUseCase(
      resolvedRequest: resolvedRequest,
    );
    final executionResult = await _executeRequestUseCase(authAppliedRequest);
    final parsedResponse = _parseResponseUseCase(executionResult);

    if (executionResult.wasBlocked) {
      emit(
        RequestSendState.blocked(
          draft: event.draft,
          resolvedRequest: resolvedRequest,
          authAppliedRequest: authAppliedRequest,
          executionResult: executionResult,
          parsedResponse: parsedResponse,
          errorMessage: executionResult.errorMessage,
        ),
      );
      return;
    }

    await _saveRequestHistoryEntryUseCase(
      executionResult: executionResult,
      parsedResponse: parsedResponse,
    );

    emit(
      RequestSendState.completed(
        draft: event.draft,
        resolvedRequest: resolvedRequest,
        authAppliedRequest: authAppliedRequest,
        executionResult: executionResult,
        parsedResponse: parsedResponse,
        errorMessage: executionResult.errorMessage,
      ),
    );
  }

  /// Clears the send pipeline state so the editor can start a fresh request cycle.
  void _onRequestSendResetRequested(
    RequestSendResetRequested event,
    Emitter<RequestSendState> emit,
  ) {
    emit(const RequestSendState.initial());
  }

  /// Performs the minimal preflight validation required before the request can enter the pipeline.
  String? _validateDraft(RequestDraft draft) {
    if (draft.url.trim().isEmpty) {
      return 'Request URL is required before sending.';
    }

    if (!_isValidAbsoluteUrl(draft.url)) {
      return 'Request URL must be a valid absolute URL.';
    }

    final authValidation = validateAuthBeforeSend(draft.auth);
    if (!authValidation.isValid) {
      return authValidation.errorMessage;
    }

    if (draft.body.type == RequestBodyType.graphql) {
      final validationError = _validateGraphQlVariables(
        draft.body.graphQl.variables,
      );
      if (validationError != null) {
        return validationError;
      }
    }

    return null;
  }

  /// Returns true when the request URL can be sent through the transport layer as an absolute HTTP(S) URL.
  bool _isValidAbsoluteUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return false;
    }

    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty;
  }

  String? _validateGraphQlVariables(String variables) {
    final trimmed = variables.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return null;
      }
    } on FormatException {
      // Fall through to the shared error message below.
    }

    return 'GraphQL variables must be a valid JSON object.';
  }
}
