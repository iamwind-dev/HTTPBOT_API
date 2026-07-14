import '../entities/request_history_entry.dart';

abstract class RequestHistoryRepository {
  /// Returns the saved request history entries in display order.
  Future<List<RequestHistoryEntry>> getRequestHistoryEntries();

  /// Persists one history entry after a request send completes.
  Future<void> saveRequestHistoryEntry(RequestHistoryEntry entry);

  /// Clears all saved history entries.
  Future<void> clearRequestHistory();

  /// Deletes saved history entries by id.
  Future<void> deleteRequestHistoryEntries(Set<String> entryIds);

  /// Deletes saved response history for one request scope.
  Future<void> deleteRequestHistoryForRequest(String requestId);
}
