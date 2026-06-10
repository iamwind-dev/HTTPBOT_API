import '../repositories/request_builder_repository.dart';

class ClearCurrentRequestDraftSessionUseCase {
  const ClearCurrentRequestDraftSessionUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Clears the autosaved editing session after an explicit discard.
  Future<void> call() => _repository.clearCurrentRequestDraftSession();
}
