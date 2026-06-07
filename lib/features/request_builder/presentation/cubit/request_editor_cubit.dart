import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/usecases/sync_request_auth_headers_use_case.dart';
import '../../domain/usecases/sync_request_query_parameters_use_case.dart';
import 'request_editor_state.dart';

class RequestEditorCubit extends Cubit<RequestEditorState> {
  RequestEditorCubit({
    required String title,
    required RequestDraft initialDraft,
    SyncRequestQueryParametersUseCase queryParametersSyncUseCase =
        const SyncRequestQueryParametersUseCase(),
    SyncRequestAuthHeadersUseCase authHeadersSyncUseCase =
        const SyncRequestAuthHeadersUseCase(),
  }) : _queryParametersSyncUseCase = queryParametersSyncUseCase,
       _authHeadersSyncUseCase = authHeadersSyncUseCase,
       super(
         _buildInitialState(
           title: title,
           initialDraft: initialDraft,
           queryParametersSyncUseCase: queryParametersSyncUseCase,
           authHeadersSyncUseCase: authHeadersSyncUseCase,
         ),
       );

  final SyncRequestQueryParametersUseCase _queryParametersSyncUseCase;
  final SyncRequestAuthHeadersUseCase _authHeadersSyncUseCase;

  /// Builds the initial editor state after syncing derived headers from body and auth.
  static RequestEditorState _buildInitialState({
    required String title,
    required RequestDraft initialDraft,
    required SyncRequestQueryParametersUseCase queryParametersSyncUseCase,
    required SyncRequestAuthHeadersUseCase authHeadersSyncUseCase,
  }) {
    final syncedDraft = initialDraft.copyWith(
      headers: _syncDerivedHeadersStatic(
        method: initialDraft.method,
        headers: initialDraft.headers,
        body: initialDraft.body,
        auth: initialDraft.auth,
        authHeadersSyncUseCase: authHeadersSyncUseCase,
      ),
    );

    return RequestEditorState(
      title: title,
      draft: syncedDraft,
      queryParametersBaseUrl: queryParametersSyncUseCase.extractBaseUrl(
        url: syncedDraft.url,
        queryParameters: syncedDraft.queryParameters,
      ),
    );
  }

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  /// Updates the request method selected in the editor header.
  void updateMethod(HttpMethod method) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          method: method,
          headers: _syncDerivedHeaders(
            method: method,
            headers: state.draft.headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  /// Updates the request URL shown in the main editor field.
  void updateUrl(String url) {
    final queryParametersBaseUrl = _queryParametersSyncUseCase.extractBaseUrl(
      url: url,
      queryParameters: state.draft.queryParameters,
    );

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          url: _queryParametersSyncUseCase.rebuildUrl(
            baseUrl: queryParametersBaseUrl,
            queryParameters: state.draft.queryParameters,
          ),
        ),
        queryParametersBaseUrl: queryParametersBaseUrl,
      ),
    );
  }

  /// Replaces the full query parameter collection after list edits.
  void updateQueryParameters(List<KeyValueItem> queryParameters) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          queryParameters: queryParameters,
          url: _queryParametersSyncUseCase.rebuildUrl(
            baseUrl: state.queryParametersBaseUrl,
            queryParameters: queryParameters,
          ),
        ),
      ),
    );
  }

  /// Replaces the full header collection after list edits.
  void updateHeaders(List<KeyValueItem> headers) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            headers: headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  void addHeader() {
    updateHeaders([...state.draft.headers, const KeyValueItem(key: '', value: '')]);
  }

  void updateHeader(int index, KeyValueItem header) {
    final updatedHeaders = [...state.draft.headers];
    updatedHeaders[index] = header;
    updateHeaders(updatedHeaders);
  }

  void removeHeader(int index) {
    final updatedHeaders = [...state.draft.headers]..removeAt(index);
    updateHeaders(updatedHeaders);
  }

  void toggleHeaderEnabled(int index) {
    final header = state.draft.headers[index];
    updateHeader(index, header.copyWith(isEnabled: !header.isEnabled));
  }

  void updateHeaderKey(int index, String key) {
    final header = state.draft.headers[index];
    updateHeader(index, header.copyWith(key: key));
  }

  void updateHeaderValue(int index, String value) {
    final header = state.draft.headers[index];
    updateHeader(index, header.copyWith(value: value));
  }

  /// Replaces the body draft after body mode or content changes.
  void updateBody(RequestBodyDraft body) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          body: body,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            headers: state.draft.headers,
            body: body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  /// Switches the body editor to a new mode while preserving other mode-specific drafts.
  void updateBodyType(RequestBodyType type) {
    updateBody(state.draft.body.copyWith(type: type));
  }

  /// Replaces the URL-encoded item collection used by the active body editor.
  void updateUrlEncodedBodyItems(List<KeyValueItem> items) {
    updateBody(state.draft.body.copyWith(urlEncoded: items));
  }

  /// Replaces the multipart form-data item collection used by the active body editor.
  void updateFormDataBodyItems(List<KeyValueItem> items) {
    updateBody(state.draft.body.copyWith(formData: items));
  }

  /// Updates the raw body draft, including subtype and content, in one place.
  void updateRawBody(RawBodyDraft raw) {
    updateBody(state.draft.body.copyWith(raw: raw));
  }

  /// Updates the GraphQL body draft, including query and variables, in one place.
  void updateGraphQlBody(GraphQlBodyDraft graphQl) {
    updateBody(state.draft.body.copyWith(graphQl: graphQl));
  }

  /// Replaces the auth draft after auth mode or credential changes.
  void updateAuth(RequestAuthDraft auth) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          auth: auth,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            headers: state.draft.headers,
            body: state.draft.body,
            auth: auth,
          ),
        ),
      ),
    );
  }

  /// Updates the timeout using whole seconds to match the current mobile form.
  void updateTimeoutSeconds(int timeoutSeconds) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          timeout: Duration(seconds: timeoutSeconds.clamp(1, 3600)),
        ),
      ),
    );
  }

  /// Updates whether SSL verification stays enabled for execution.
  void updateVerifySsl(bool verifySsl) {
    emit(state.copyWith(draft: state.draft.copyWith(verifySsl: verifySsl)));
  }

  /// Applies every header that is derived from body or auth editor state.
  List<KeyValueItem> _syncDerivedHeaders({
    required HttpMethod method,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
  }) {
    return _syncDerivedHeadersStatic(
      method: method,
      headers: headers,
      body: body,
      auth: auth,
      authHeadersSyncUseCase: _authHeadersSyncUseCase,
    );
  }

  /// Applies every header that is derived from body or auth editor state.
  static List<KeyValueItem> _syncDerivedHeadersStatic({
    required HttpMethod method,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
    required SyncRequestAuthHeadersUseCase authHeadersSyncUseCase,
  }) {
    final contentTypeSyncedHeaders = headers
        .where((header) => !header.isSystemGeneratedContentTypeHeader)
        .toList(growable: false);

    return authHeadersSyncUseCase(
      headers: contentTypeSyncedHeaders,
      auth: auth,
    );
  }
}
