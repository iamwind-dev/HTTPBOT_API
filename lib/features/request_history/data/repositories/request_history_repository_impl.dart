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
    final maxEntriesForRequest = entry.request.settings.savedResponsesInHistory;
    if (maxEntriesForRequest == 0) {
      _entries.removeWhere(
        (existingEntry) => _isSameRequestScope(existingEntry, entry),
      );
      return;
    }

    _entries.insert(0, entry);
    var keptForRequest = 0;
    _entries.removeWhere((existingEntry) {
      if (!_isSameRequestScope(existingEntry, entry)) {
        return false;
      }

      keptForRequest++;
      return keptForRequest > maxEntriesForRequest;
    });
  }

  /// Removes every in-memory history entry until persistent storage is added.
  @override
  Future<void> clearRequestHistory() async {
    _entries.clear();
  }

  bool _isSameRequestScope(
    RequestHistoryEntry left,
    RequestHistoryEntry right,
  ) =>
      left.request.method == right.request.method &&
      left.request.url == right.request.url;
}
