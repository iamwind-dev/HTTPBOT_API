import '../entities/request_draft.dart';
import '../repositories/request_builder_repository.dart';

class GetRequestDraftUseCase {
  const GetRequestDraftUseCase(this._repository);

  final RequestBuilderRepository _repository;

  RequestDraft call() => _repository.getInitialDraft();
}
