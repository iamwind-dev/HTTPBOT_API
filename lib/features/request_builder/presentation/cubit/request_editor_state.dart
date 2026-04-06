import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';

class RequestEditorState extends Equatable {
  const RequestEditorState({
    required this.title,
    required this.draft,
  });

  final String title;
  final RequestDraft draft;

  /// Creates a new immutable editor state with any updated presentation values applied.
  RequestEditorState copyWith({
    String? title,
    RequestDraft? draft,
  }) => RequestEditorState(
    title: title ?? this.title,
    draft: draft ?? this.draft,
  );

  @override
  List<Object> get props => [title, draft];
}
