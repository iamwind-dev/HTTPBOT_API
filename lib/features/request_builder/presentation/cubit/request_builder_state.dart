import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';

enum RequestBuilderStatus { initial, ready }

class RequestBuilderState extends Equatable {
  const RequestBuilderState({required this.status, required this.draft});

  const RequestBuilderState.initial()
    : status = RequestBuilderStatus.initial,
      draft = const RequestDraft(
        method: '',
        url: '',
        authMode: '',
        bodyMode: '',
      );

  final RequestBuilderStatus status;
  final RequestDraft draft;

  RequestBuilderState copyWith({
    RequestBuilderStatus? status,
    RequestDraft? draft,
  }) => RequestBuilderState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
  );

  @override
  List<Object> get props => [status, draft];
}
