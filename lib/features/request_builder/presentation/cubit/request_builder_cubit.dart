import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_draft.dart';
import '../../domain/usecases/get_request_draft_use_case.dart';
import '../../domain/usecases/get_request_variable_store_use_case.dart';
import '../models/request_list_item.dart';
import 'request_builder_state.dart';

class RequestBuilderCubit extends Cubit<RequestBuilderState> {
  RequestBuilderCubit(
    this._getRequestDraftUseCase,
    this._getRequestVariableStoreUseCase, {
    List<RequestListItem>? seedRequests,
  }) : _seedRequests = seedRequests,
       super(const RequestBuilderState.initial());

  final GetRequestDraftUseCase _getRequestDraftUseCase;
  final GetRequestVariableStoreUseCase _getRequestVariableStoreUseCase;
  final List<RequestListItem>? _seedRequests;

  /// Loads the starting draft, variable store, and the visible list of saved requests.
  Future<void> load() async {
    final draft = await _getRequestDraftUseCase();
    final variableStore = await _getRequestVariableStoreUseCase();
    final requests = _seedRequests ?? _buildSeedRequests(draft);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        status: RequestBuilderStatus.ready,
        requests: requests,
        initialDraft: draft,
        initialVariableStore: variableStore,
      ),
    );
  }

  /// Updates the request search query used to filter the list.
  void updateSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value));
  }

  List<RequestListItem> _buildSeedRequests(RequestDraft draft) =>
      <RequestListItem>[
        RequestListItem(
          method: draft.method.label,
          title: 'Untitled Request',
          url: draft.url,
        ),
        RequestListItem(
          method: draft.method.label,
          title: 'Untitled Request',
          url: draft.url,
        ),
        const RequestListItem(
          method: 'POST',
          title: 'Untitled Request',
          url: 'https://api.example.com/posts',
        ),
        const RequestListItem(
          method: 'PUT',
          title: 'Untitled Request',
          url: 'https://api.example.com/profile',
        ),
        const RequestListItem(
          method: 'DEL',
          title: 'Untitled Request',
          url: 'https://api.example.com/sessions/current',
        ),
        const RequestListItem(
          method: 'PAT',
          title: 'Untitled Request',
          url: 'https://api.example.com/preferences',
        ),
        const RequestListItem(
          method: 'HEAD',
          title: 'Untitled Request',
          url: 'https://api.example.com/health',
        ),
        const RequestListItem(
          method: 'OPT',
          title: 'Untitled Request',
          url: 'https://api.example.com/capabilities',
        ),
      ];
}
