import 'package:equatable/equatable.dart';

import 'request_draft.dart';

class SavedRequestDraft extends Equatable {
  const SavedRequestDraft({
    required this.title,
    required this.draft,
    this.isFavourite = false,
  });

  final String title;
  final RequestDraft draft;
  final bool isFavourite;

  @override
  List<Object> get props => [title, draft, isFavourite];
}
