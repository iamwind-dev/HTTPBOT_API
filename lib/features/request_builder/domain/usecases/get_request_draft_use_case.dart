import '../entities/request_draft.dart';
import '../repositories/request_builder_repository.dart';

class GetRequestDraftUseCase {
  const GetRequestDraftUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Loads the current request draft through the domain repository contract.
  Future<RequestDraft> call() => _repository.getRequestDraft();
}
