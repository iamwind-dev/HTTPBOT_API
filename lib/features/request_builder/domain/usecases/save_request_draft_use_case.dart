import '../entities/request_draft.dart';
import '../repositories/request_builder_repository.dart';

class SaveRequestDraftUseCase {
  const SaveRequestDraftUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Persists the current editor draft through the domain repository contract.
  Future<void> call(RequestDraft draft) => _repository.saveRequestDraft(draft);
}
