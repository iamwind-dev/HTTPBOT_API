import '../entities/request_draft_session.dart';
import '../repositories/request_builder_repository.dart';

class SaveCurrentRequestDraftSessionUseCase {
  const SaveCurrentRequestDraftSessionUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Persists the active editing session through the repository contract.
  Future<void> call(RequestDraftSession session) =>
      _repository.saveCurrentRequestDraftSession(session);
}
