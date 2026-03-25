import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_draft.dart';
import '../../domain/usecases/get_request_draft_use_case.dart';
import '../models/request_list_item.dart';
import 'request_builder_state.dart';

class RequestBuilderCubit extends Cubit<RequestBuilderState> {
  RequestBuilderCubit(
    this._getRequestDraftUseCase, {
    List<RequestListItem>? seedRequests,
  }) : _seedRequests = seedRequests,
       super(const RequestBuilderState.initial());

  final GetRequestDraftUseCase _getRequestDraftUseCase;
  final List<RequestListItem>? _seedRequests;

  void load() {
    final draft = _getRequestDraftUseCase();
    final requests = _seedRequests ?? _buildSeedRequests(draft);

    emit(
      state.copyWith(status: RequestBuilderStatus.ready, requests: requests),
    );
  }

  void updateSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value, clearPlaceholderTab: true));
  }

  void showPlaceholderTab(RequestBottomTab tab) {
    if (tab == RequestBottomTab.requests) {
      emit(
        state.copyWith(
          selectedTab: RequestBottomTab.requests,
          clearPlaceholderTab: true,
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        selectedTab: RequestBottomTab.requests,
        placeholderTab: tab,
      ),
    );
  }

  void clearPlaceholderTab() {
    emit(state.copyWith(clearPlaceholderTab: true));
  }

  List<RequestListItem> _buildSeedRequests(RequestDraft draft) =>
      <RequestListItem>[
        RequestListItem(
          method: draft.method,
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
