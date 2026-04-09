import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_draft_session.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/entities/saved_request_draft.dart';
import '../../domain/usecases/clear_current_request_draft_session_use_case.dart';
import '../../domain/usecases/get_current_request_draft_session_use_case.dart';
import '../../domain/usecases/get_request_draft_use_case.dart';
import '../../domain/usecases/get_request_variable_store_use_case.dart';
import '../../domain/usecases/get_saved_request_drafts_use_case.dart';
import '../../domain/usecases/save_current_request_draft_session_use_case.dart';
import '../../domain/usecases/save_saved_request_drafts_use_case.dart';
import '../models/request_list_item.dart';
import 'request_builder_state.dart';

class RequestBuilderCubit extends Cubit<RequestBuilderState> {
  RequestBuilderCubit(
    this._getRequestDraftUseCase,
    this._getRequestVariableStoreUseCase, {
    required GetCurrentRequestDraftSessionUseCase
    getCurrentRequestDraftSessionUseCase,
    required SaveCurrentRequestDraftSessionUseCase
    saveCurrentRequestDraftSessionUseCase,
    required ClearCurrentRequestDraftSessionUseCase
    clearCurrentRequestDraftSessionUseCase,
    required GetSavedRequestDraftsUseCase getSavedRequestDraftsUseCase,
    required SaveSavedRequestDraftsUseCase saveSavedRequestDraftsUseCase,
    List<RequestListItem>? seedRequests,
  }) : _getCurrentRequestDraftSessionUseCase =
           getCurrentRequestDraftSessionUseCase,
       _saveCurrentRequestDraftSessionUseCase =
           saveCurrentRequestDraftSessionUseCase,
       _clearCurrentRequestDraftSessionUseCase =
           clearCurrentRequestDraftSessionUseCase,
       _getSavedRequestDraftsUseCase = getSavedRequestDraftsUseCase,
       _saveSavedRequestDraftsUseCase = saveSavedRequestDraftsUseCase,
       _seedRequests = seedRequests,
       super(const RequestBuilderState.initial());

  final GetRequestDraftUseCase _getRequestDraftUseCase;
  final GetRequestVariableStoreUseCase _getRequestVariableStoreUseCase;
  final GetCurrentRequestDraftSessionUseCase
  _getCurrentRequestDraftSessionUseCase;
  final SaveCurrentRequestDraftSessionUseCase
  _saveCurrentRequestDraftSessionUseCase;
  final ClearCurrentRequestDraftSessionUseCase
  _clearCurrentRequestDraftSessionUseCase;
  final GetSavedRequestDraftsUseCase _getSavedRequestDraftsUseCase;
  final SaveSavedRequestDraftsUseCase _saveSavedRequestDraftsUseCase;
  final List<RequestListItem>? _seedRequests;

  /// Loads the starting draft, variable store, and the visible list of saved requests.
  Future<void> load() async {
    final draft = await _getRequestDraftUseCase();
    final draftSession = await _getCurrentRequestDraftSessionUseCase();
    final variableStore = await _getRequestVariableStoreUseCase();
    final persistedRequests = await _getSavedRequestDraftsUseCase();
    final initialDraft = draftSession?.draft ?? draft;
    final savedRequests = _initialSavedRequests(
      persistedRequests: persistedRequests,
      fallbackDraft: initialDraft,
    );
    final restoredSavedRequests = draftSession == null
        ? savedRequests
        : _applyDraftSessionToSavedRequests(savedRequests, draftSession);
    final requests = restoredSavedRequests
        .map(_listItemFromSavedRequest)
        .toList(growable: false);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        status: RequestBuilderStatus.ready,
        requests: requests,
        initialDraft: initialDraft,
        initialVariableStore: variableStore,
        savedRequests: restoredSavedRequests,
      ),
    );
  }

  /// Updates the request search query used to filter the list.
  void updateSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value));
  }

  /// Persists the latest draft and reflects core request metadata back into the list.
  Future<void> saveEditedDraft({
    required int requestIndex,
    required String title,
    required RequestDraft draft,
  }) async {
    await _saveCurrentRequestDraftSessionUseCase(
      RequestDraftSession(
        title: title,
        draft: draft,
        requestIndex: requestIndex,
      ),
    );

    if (isClosed) {
      return;
    }

    final updatedSavedRequests = _replaceSavedRequest(
      state.savedRequests,
      requestIndex,
      SavedRequestDraft(title: title, draft: draft),
    );
    await _saveSavedRequestDraftsUseCase(updatedSavedRequests);

    emit(
      state.copyWith(
        requests: updatedSavedRequests
            .map(_listItemFromSavedRequest)
            .toList(growable: false),
        savedRequests: updatedSavedRequests,
        initialDraft: draft,
      ),
    );
  }

  /// Adds a newly created request to the visible list and stores it as the active draft.
  Future<void> saveNewDraft({
    required String title,
    required RequestDraft draft,
  }) async {
    final requestIndex = state.savedRequests.length;
    await _saveCurrentRequestDraftSessionUseCase(
      RequestDraftSession(
        title: title,
        draft: draft,
        requestIndex: requestIndex,
      ),
    );

    if (isClosed) {
      return;
    }

    final updatedSavedRequests = [
      ...state.savedRequests,
      SavedRequestDraft(title: title, draft: draft),
    ];
    await _saveSavedRequestDraftsUseCase(updatedSavedRequests);

    emit(
      state.copyWith(
        requests: updatedSavedRequests
            .map(_listItemFromSavedRequest)
            .toList(growable: false),
        savedRequests: updatedSavedRequests,
        initialDraft: draft,
      ),
    );
  }

  Future<void> importHar() async {
    // TODO: Parse a selected HAR file and add the imported request drafts.
  }

  Future<void> importCurl() async {
    // TODO: Parse a pasted curl command and add the imported request draft.
  }

  Future<void> duplicateRequest(int requestIndex) async {
    if (requestIndex < 0 || requestIndex >= state.savedRequests.length) {
      return;
    }

    final sourceRequest = state.savedRequests[requestIndex];
    final duplicatedRequest = SavedRequestDraft(
      title: '${sourceRequest.title} Copy',
      draft: sourceRequest.draft,
    );
    final updatedSavedRequests = [
      ...state.savedRequests.sublist(0, requestIndex + 1),
      duplicatedRequest,
      ...state.savedRequests.sublist(requestIndex + 1),
    ];

    await _saveSavedRequestDraftsUseCase(updatedSavedRequests);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        requests: updatedSavedRequests
            .map(_listItemFromSavedRequest)
            .toList(growable: false),
        savedRequests: updatedSavedRequests,
      ),
    );
  }

  Future<void> deleteRequest(int requestIndex) async {
    if (requestIndex < 0 || requestIndex >= state.savedRequests.length) {
      return;
    }

    final updatedSavedRequests = [...state.savedRequests]
      ..removeAt(requestIndex);

    await _saveSavedRequestDraftsUseCase(updatedSavedRequests);

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        requests: updatedSavedRequests
            .map(_listItemFromSavedRequest)
            .toList(growable: false),
        savedRequests: updatedSavedRequests,
      ),
    );
  }

  Future<void> viewCurl(int requestIndex) async {
    // TODO: Generate and present the selected request as a cURL command.
  }

  Future<void> exportHar(int requestIndex) async {
    // TODO: Export the selected request as a HAR entry/file.
  }

  Future<void> toggleFavourite(int requestIndex) async {
    // TODO: Persist favourite state once request list items model favourites.
  }

  Future<void> saveCurrentDraftSession({
    required String title,
    required RequestDraft draft,
    int? requestIndex,
  }) async {
    await _saveCurrentRequestDraftSessionUseCase(
      RequestDraftSession(
        title: title,
        draft: draft,
        requestIndex: requestIndex,
      ),
    );
  }

  Future<void> discardCurrentDraftSession() =>
      _clearCurrentRequestDraftSessionUseCase();

  List<SavedRequestDraft> _initialSavedRequests({
    required List<SavedRequestDraft> persistedRequests,
    required RequestDraft fallbackDraft,
  }) {
    if (persistedRequests.isNotEmpty) {
      return persistedRequests;
    }

    if (_seedRequests != null) {
      return _seedRequests
          .map(
            (item) => SavedRequestDraft(
              title: item.title,
              draft: fallbackDraft.copyWith(
                method: _methodFromLabel(item.method),
                url: item.url,
              ),
            ),
          )
          .toList(growable: false);
    }

    return _buildSeedRequests(fallbackDraft);
  }

  List<SavedRequestDraft> _applyDraftSessionToSavedRequests(
    List<SavedRequestDraft> requests,
    RequestDraftSession session,
  ) {
    final savedRequest = SavedRequestDraft(
      title: session.title,
      draft: session.draft,
    );

    if (session.requestIndex == null || session.requestIndex! < 0) {
      if (requests.isEmpty) {
        return [savedRequest];
      }

      return [savedRequest, ...requests.skip(1)];
    }

    if (session.requestIndex! >= requests.length) {
      if (requests.isEmpty) {
        return [savedRequest];
      }

      return [savedRequest, ...requests.skip(1)];
    }

    final updatedRequests = [...requests];
    updatedRequests[session.requestIndex!] = savedRequest;
    return updatedRequests;
  }

  List<SavedRequestDraft> _replaceSavedRequest(
    List<SavedRequestDraft> requests,
    int requestIndex,
    SavedRequestDraft request,
  ) {
    if (requestIndex < 0 || requestIndex >= requests.length) {
      return [...requests, request];
    }

    final updatedRequests = [...requests];
    updatedRequests[requestIndex] = request;
    return updatedRequests;
  }

  RequestListItem _listItemFromSavedRequest(SavedRequestDraft request) =>
      RequestListItem(
        method: request.draft.method.label,
        title: request.title.trim().isEmpty
            ? 'Untitled Request'
            : request.title.trim(),
        url: request.draft.url,
      );

  HttpMethod _methodFromLabel(String label) {
    for (final method in HttpMethod.values) {
      if (method.label == label || method.wireName == label) {
        return method;
      }
    }

    return HttpMethod.get;
  }

  List<SavedRequestDraft> _buildSeedRequests(RequestDraft draft) =>
      <SavedRequestDraft>[
        SavedRequestDraft(title: 'Untitled Request', draft: draft),
        SavedRequestDraft(title: 'Untitled Request', draft: draft),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.post,
            url: 'https://api.example.com/posts',
          ),
        ),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.put,
            url: 'https://api.example.com/profile',
          ),
        ),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.delete,
            url: 'https://api.example.com/sessions/current',
          ),
        ),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.patch,
            url: 'https://api.example.com/preferences',
          ),
        ),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.head,
            url: 'https://api.example.com/health',
          ),
        ),
        const SavedRequestDraft(
          title: 'Untitled Request',
          draft: RequestDraft(
            method: HttpMethod.options,
            url: 'https://api.example.com/capabilities',
          ),
        ),
      ];
}
