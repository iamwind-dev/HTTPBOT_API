import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/helpers/api_key_auth_ui_sync.dart';
import '../../domain/helpers/content_type_header_updater.dart';
import '../../domain/helpers/jwt_auth_ui_sync.dart';
import '../../domain/helpers/oauth1_auth_ui_sync.dart';
import '../../domain/helpers/oauth2_auth_ui_sync.dart';
import '../../domain/usecases/sync_request_auth_headers_use_case.dart';
import '../../domain/usecases/sync_request_query_parameters_use_case.dart';
import 'request_editor_state.dart';

class _AuthFieldSyncResult {
  const _AuthFieldSyncResult({
    required this.queryParameters,
    required this.headers,
  });

  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
}

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
    final authSyncedFields = _syncAuthFieldsStatic(
      method: initialDraft.method,
      url: initialDraft.url,
      queryParameters: initialDraft.queryParameters,
      headers: initialDraft.headers,
      body: initialDraft.body,
      auth: initialDraft.auth,
    );
    final queryParametersBaseUrl = queryParametersSyncUseCase.extractBaseUrl(
      url: initialDraft.url,
      queryParameters: authSyncedFields.queryParameters,
    );
    final rebuiltUrl = queryParametersSyncUseCase.rebuildUrl(
      baseUrl: queryParametersBaseUrl,
      queryParameters: authSyncedFields.queryParameters,
    );
    final syncedDraft = initialDraft.copyWith(
      url: rebuiltUrl,
      queryParameters: authSyncedFields.queryParameters,
      headers: _syncDerivedHeadersStatic(
        method: initialDraft.method,
        url: rebuiltUrl,
        headers: authSyncedFields.headers,
        body: initialDraft.body,
        auth: initialDraft.auth,
        authHeadersSyncUseCase: authHeadersSyncUseCase,
      ),
    );

    return RequestEditorState(
      title: title,
      draft: syncedDraft,
      queryParametersBaseUrl: queryParametersBaseUrl,
    );
  }

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  /// Updates the request method selected in the editor header.
  void updateMethod(HttpMethod method) {
    final syncedAuthFields = _syncAuthFields(
      method: method,
      url: state.draft.url,
      queryParameters: state.draft.queryParameters,
      headers: state.draft.headers,
      body: state.draft.body,
      auth: state.draft.auth,
    );
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          method: method,
          queryParameters: syncedAuthFields.queryParameters,
          headers: _syncDerivedHeaders(
            method: method,
            url: state.draft.url,
            headers: syncedAuthFields.headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  /// Updates the request URL shown in the main editor field.
  void updateUrl(String url) {
    final syncedAuthFields = _syncAuthFields(
      method: state.draft.method,
      url: url,
      queryParameters: state.draft.queryParameters,
      headers: state.draft.headers,
      body: state.draft.body,
      auth: state.draft.auth,
    );
    final queryParametersBaseUrl = _queryParametersSyncUseCase.extractBaseUrl(
      url: url,
      queryParameters: syncedAuthFields.queryParameters,
    );
    final rebuiltUrl = _queryParametersSyncUseCase.rebuildUrl(
      baseUrl: queryParametersBaseUrl,
      queryParameters: syncedAuthFields.queryParameters,
    );

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          url: rebuiltUrl,
          queryParameters: syncedAuthFields.queryParameters,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            url: rebuiltUrl,
            headers: syncedAuthFields.headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
        queryParametersBaseUrl: queryParametersBaseUrl,
      ),
    );
  }

  /// Replaces the full query parameter collection after list edits.
  void updateQueryParameters(List<KeyValueItem> queryParameters) {
    final syncedAuthFields = _syncAuthFields(
      method: state.draft.method,
      url: state.draft.url,
      queryParameters: queryParameters,
      headers: state.draft.headers,
      body: state.draft.body,
      auth: state.draft.auth,
    );
    final rebuiltUrl = _queryParametersSyncUseCase.rebuildUrl(
      baseUrl: state.queryParametersBaseUrl,
      queryParameters: syncedAuthFields.queryParameters,
    );

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          queryParameters: syncedAuthFields.queryParameters,
          url: rebuiltUrl,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            url: rebuiltUrl,
            headers: syncedAuthFields.headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  /// Replaces the full header collection after list edits.
  void updateHeaders(List<KeyValueItem> headers) {
    final syncedAuthFields = _syncAuthFields(
      method: state.draft.method,
      url: state.draft.url,
      queryParameters: state.draft.queryParameters,
      headers: headers,
      body: state.draft.body,
      auth: state.draft.auth,
    );
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          queryParameters: syncedAuthFields.queryParameters,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            url: state.draft.url,
            headers: syncedAuthFields.headers,
            body: state.draft.body,
            auth: state.draft.auth,
          ),
        ),
      ),
    );
  }

  void addHeader() {
    updateHeaders([
      ...state.draft.headers,
      const KeyValueItem(key: '', value: ''),
    ]);
  }

  /// Applies one header row change and promotes generated Content-Type rows after manual edits.
  void updateHeader(int index, KeyValueItem header) {
    final updatedHeaders = [...state.draft.headers];
    final existingHeader = updatedHeaders[index];
    updatedHeaders[index] =
        existingHeader.isAnySystemGeneratedHeader &&
            (existingHeader.key != header.key ||
                existingHeader.value != header.value)
        ? header.copyWith(description: '')
        : header;
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
    final syncedAuthFields = _syncAuthFields(
      method: state.draft.method,
      url: state.draft.url,
      queryParameters: state.draft.queryParameters,
      headers: state.draft.headers,
      body: body,
      auth: state.draft.auth,
    );
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          body: body,
          queryParameters: syncedAuthFields.queryParameters,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            url: state.draft.url,
            headers: syncedAuthFields.headers,
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
    final syncedAuthFields = _syncAuthFields(
      method: state.draft.method,
      url: state.draft.url,
      queryParameters: state.draft.queryParameters,
      headers: state.draft.headers,
      body: state.draft.body,
      auth: auth,
    );
    final rebuiltUrl = _queryParametersSyncUseCase.rebuildUrl(
      baseUrl: state.queryParametersBaseUrl,
      queryParameters: syncedAuthFields.queryParameters,
    );

    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          auth: auth,
          url: rebuiltUrl,
          queryParameters: syncedAuthFields.queryParameters,
          headers: _syncDerivedHeaders(
            method: state.draft.method,
            url: rebuiltUrl,
            headers: syncedAuthFields.headers,
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
    required String url,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
  }) {
    return _syncDerivedHeadersStatic(
      method: method,
      url: url,
      headers: headers,
      body: body,
      auth: auth,
      authHeadersSyncUseCase: _authHeadersSyncUseCase,
    );
  }

  /// Applies the editor-managed auth rows to query params and headers.
  _AuthFieldSyncResult _syncAuthFields({
    required HttpMethod method,
    required String url,
    required List<KeyValueItem> queryParameters,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
  }) => _syncAuthFieldsStatic(
    method: method,
    url: url,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    auth: auth,
  );

  /// Applies every header that is derived from body or auth editor state.
  static List<KeyValueItem> _syncDerivedHeadersStatic({
    required HttpMethod method,
    required String url,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
    required SyncRequestAuthHeadersUseCase authHeadersSyncUseCase,
  }) {
    final contentTypeSyncedHeaders = syncContentTypeHeaderWithBodyType(
      headers: headers,
      bodyType: body.type,
      method: method,
    );

    return authHeadersSyncUseCase(
      headers: contentTypeSyncedHeaders,
      auth: auth,
      method: method,
      url: url,
      body: body,
    );
  }

  /// Applies the editor-managed auth rows to query params and headers.
  static _AuthFieldSyncResult _syncAuthFieldsStatic({
    required HttpMethod method,
    required String url,
    required List<KeyValueItem> queryParameters,
    required List<KeyValueItem> headers,
    required RequestBodyDraft body,
    required RequestAuthDraft auth,
  }) {
    final jwtSyncedFields = syncJwtAuthToRequestFields(
      queryParameters: queryParameters,
      headers: headers,
      auth: auth,
    );
    final oauth1SyncedFields = syncOAuth1AuthToRequestFields(
      queryParameters: jwtSyncedFields.queryParameters,
      headers: jwtSyncedFields.headers,
      auth: auth,
      method: method,
      url: url,
      body: body,
    );
    final oauth2SyncedFields = syncOAuth2AuthToRequestFields(
      queryParameters: oauth1SyncedFields.queryParameters,
      headers: oauth1SyncedFields.headers,
      auth: auth,
    );
    final apiKeySyncedFields = syncApiKeyAuthToRequestFields(
      queryParameters: oauth2SyncedFields.queryParameters,
      headers: oauth2SyncedFields.headers,
      auth: auth,
    );

    return _AuthFieldSyncResult(
      queryParameters: apiKeySyncedFields.queryParameters,
      headers: apiKeySyncedFields.headers,
    );
  }
}
