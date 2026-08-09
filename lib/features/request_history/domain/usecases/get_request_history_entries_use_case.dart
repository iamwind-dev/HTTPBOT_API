import '../../../request_builder/domain/entities/request_draft.dart';
import '../entities/request_history_entry.dart';
import '../repositories/request_history_repository.dart';

class GetRequestHistoryEntriesUseCase {
  const GetRequestHistoryEntriesUseCase(this._repository);

  final RequestHistoryRepository _repository;

  /// Returns all entries or only the entries for the supplied request scope.
  Future<List<RequestHistoryEntry>> call({RequestDraft? request}) =>
      request == null
      ? _repository.getRequestHistoryEntries()
      : _repository.getRequestHistoryEntriesForRequest(request);
}
