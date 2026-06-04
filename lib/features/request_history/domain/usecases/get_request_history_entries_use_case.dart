import '../entities/request_history_entry.dart';
import '../repositories/request_history_repository.dart';

class GetRequestHistoryEntriesUseCase {
  const GetRequestHistoryEntriesUseCase(this._repository);

  final RequestHistoryRepository _repository;

  /// Returns the full saved request history for future list and detail screens.
  Future<List<RequestHistoryEntry>> call() =>
      _repository.getRequestHistoryEntries();
}
