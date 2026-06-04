import '../../domain/entities/request_history_entry.dart';
import '../../domain/repositories/request_history_repository.dart';

class RequestHistoryRepositoryImpl implements RequestHistoryRepository {
  final List<RequestHistoryEntry> _entries = <RequestHistoryEntry>[];

  /// Returns a read-only snapshot of the current in-memory history entries.
  @override
  Future<List<RequestHistoryEntry>> getRequestHistoryEntries() async =>
      List<RequestHistoryEntry>.unmodifiable(_entries);

  /// Inserts the latest history entry at the top so newest requests appear first.
  @override
  Future<void> saveRequestHistoryEntry(RequestHistoryEntry entry) async {
    _entries.insert(0, entry);
  }

  /// Removes every in-memory history entry until persistent storage is added.
  @override
  Future<void> clearRequestHistory() async {
    _entries.clear();
  }
}
