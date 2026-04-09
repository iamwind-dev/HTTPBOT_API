import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/requests_method.dart';
import 'request_editor_state.dart';

class RequestEditorCubit extends Cubit<RequestEditorState> {
  RequestEditorCubit({
    required String title,
    required RequestDraft initialDraft,
  }) : super(RequestEditorState(title: title, draft: initialDraft));

  void updateTitle(String title) {
    emit(state.copyWith(title: title));
  }

  /// Updates the request method selected in the editor header.
  void updateMethod(HttpMethod method) {
    emit(state.copyWith(draft: state.draft.copyWith(method: method)));
  }

  /// Updates the request URL shown in the main editor field.
  void updateUrl(String url) {
    emit(state.copyWith(draft: state.draft.copyWith(url: url)));
  }

  /// Replaces the full query parameter collection after list edits.
  void updateQueryParameters(List<KeyValueItem> queryParameters) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(queryParameters: queryParameters),
      ),
    );
  }

  /// Replaces the full header collection after list edits.
  void updateHeaders(List<KeyValueItem> headers) {
    emit(state.copyWith(draft: state.draft.copyWith(headers: headers)));
  }

  /// Replaces the body draft after body mode or content changes.
  void updateBody(RequestBodyDraft body) {
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          body: body,
          headers: _syncContentTypeHeader(state.draft.headers, body),
        ),
      ),
    );
  }

  /// Replaces the auth draft after auth mode or credential changes.
  void updateAuth(RequestAuthDraft auth) {
    emit(state.copyWith(draft: state.draft.copyWith(auth: auth)));
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

  List<KeyValueItem> _syncContentTypeHeader(
    List<KeyValueItem> headers,
    RequestBodyDraft body,
  ) {
    final contentType = _contentTypeForBody(body);
    if (contentType == null) {
      return headers;
    }

    var hasContentTypeHeader = false;
    final updatedHeaders = <KeyValueItem>[];

    for (final header in headers) {
      if (!_isContentTypeHeader(header)) {
        updatedHeaders.add(header);
        continue;
      }

      if (hasContentTypeHeader) {
        continue;
      }

      hasContentTypeHeader = true;
      updatedHeaders.add(
        header.copyWith(
          key: 'Content-Type',
          value: contentType,
          isEnabled: true,
          type: KeyValueItemType.text,
        ),
      );
    }

    if (!hasContentTypeHeader) {
      updatedHeaders.add(
        KeyValueItem(key: 'Content-Type', value: contentType, isEnabled: true),
      );
    }

    return updatedHeaders;
  }

  String? _contentTypeForBody(RequestBodyDraft body) => switch (body.type) {
    RequestBodyType.json => 'application/json',
    RequestBodyType.xWwwFormUrlEncoded => 'application/x-www-form-urlencoded',
    RequestBodyType.formData => 'multipart/form-data',
    RequestBodyType.graphql => 'application/json',
    RequestBodyType.raw =>
      _isJsonContentType(body.rawContentType) ? 'application/json' : null,
    RequestBodyType.none => null,
  };

  bool _isContentTypeHeader(KeyValueItem header) =>
      header.key.trim().toLowerCase() == 'content-type';

  bool _isJsonContentType(String contentType) =>
      contentType.trim().toLowerCase() == 'application/json';
}
