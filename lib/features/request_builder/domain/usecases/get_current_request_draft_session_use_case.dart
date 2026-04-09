import '../entities/request_draft_session.dart';
import '../repositories/request_builder_repository.dart';

class GetCurrentRequestDraftSessionUseCase {
  const GetCurrentRequestDraftSessionUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Loads the latest autosaved editing session, if one exists.
  Future<RequestDraftSession?> call() =>
      _repository.getCurrentRequestDraftSession();
}
