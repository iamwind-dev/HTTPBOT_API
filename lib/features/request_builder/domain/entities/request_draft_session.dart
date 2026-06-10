import 'package:equatable/equatable.dart';

import 'request_draft.dart';

class RequestDraftSession extends Equatable {
  const RequestDraftSession({
    required this.title,
    required this.draft,
    this.requestIndex,
  });

  final String title;
  final RequestDraft draft;
  final int? requestIndex;

  bool get isNewRequest => requestIndex == null;

  @override
  List<Object?> get props => [title, draft, requestIndex];
}
