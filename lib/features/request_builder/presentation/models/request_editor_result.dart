import 'package:equatable/equatable.dart';
import '../../domain/entities/request_draft.dart';

class RequestEditorResult extends Equatable {
  const RequestEditorResult({
    required this.title,
    required this.draft,
  });
  final String title;
  final RequestDraft draft;

  @override
  List<Object?> get props => [title, draft];
}