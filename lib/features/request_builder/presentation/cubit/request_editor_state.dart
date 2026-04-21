import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';

class RequestEditorState extends Equatable {
  const RequestEditorState({
    required this.title,
    required this.draft,
    required this.queryParametersBaseUrl,
  });

  final String title;
  final RequestDraft draft;
  final String queryParametersBaseUrl;

  /// Creates a new immutable editor state with any updated presentation values applied.
  RequestEditorState copyWith({
    String? title,
    RequestDraft? draft,
    String? queryParametersBaseUrl,
  }) => RequestEditorState(
    title: title ?? this.title,
    draft: draft ?? this.draft,
    queryParametersBaseUrl: queryParametersBaseUrl ?? this.queryParametersBaseUrl,
  );

  @override
  List<Object> get props => [title, draft, queryParametersBaseUrl];
}
