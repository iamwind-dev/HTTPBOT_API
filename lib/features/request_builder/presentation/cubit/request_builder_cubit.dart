import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_request_draft_use_case.dart';
import 'request_builder_state.dart';

class RequestBuilderCubit extends Cubit<RequestBuilderState> {
  RequestBuilderCubit(this._getRequestDraftUseCase)
    : super(const RequestBuilderState.initial());

  final GetRequestDraftUseCase _getRequestDraftUseCase;

  void load() {
    final draft = _getRequestDraftUseCase();

    emit(state.copyWith(status: RequestBuilderStatus.ready, draft: draft));
  }
}
