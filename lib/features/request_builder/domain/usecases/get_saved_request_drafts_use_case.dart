import '../entities/saved_request_draft.dart';
import '../repositories/request_builder_repository.dart';

class GetSavedRequestDraftsUseCase {
  const GetSavedRequestDraftsUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Loads the saved request list with full request drafts.
  Future<List<SavedRequestDraft>> call() => _repository.getSavedRequestDrafts();
}
