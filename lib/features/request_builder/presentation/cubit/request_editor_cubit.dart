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
    emit(state.copyWith(draft: state.draft.copyWith(body: body)));
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
}
