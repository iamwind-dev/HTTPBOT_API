import 'package:equatable/equatable.dart';

import 'request_draft.dart';

class SavedRequestDraft extends Equatable {
  const SavedRequestDraft({required this.title, required this.draft});

  final String title;
  final RequestDraft draft;

  @override
  List<Object> get props => [title, draft];
}
