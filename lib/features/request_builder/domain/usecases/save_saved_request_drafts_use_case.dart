import '../entities/saved_request_draft.dart';
import '../repositories/request_builder_repository.dart';

class SaveSavedRequestDraftsUseCase {
  const SaveSavedRequestDraftsUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Persists the saved request list with full request drafts.
  Future<void> call(List<SavedRequestDraft> requests) =>
      _repository.saveSavedRequestDrafts(requests);
}
