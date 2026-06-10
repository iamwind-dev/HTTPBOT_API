import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_variable_store.dart';

sealed class RequestSendEvent extends Equatable {
  const RequestSendEvent();
}

class RequestSendRequested extends RequestSendEvent {
  const RequestSendRequested({
    required this.draft,
    required this.variableStore,
  });

  final RequestDraft draft;
  final RequestVariableStore variableStore;

  @override
  List<Object> get props => [draft, variableStore];
}

class RequestSendResetRequested extends RequestSendEvent {
  const RequestSendResetRequested();

  @override
  List<Object> get props => const <Object>[];
}
