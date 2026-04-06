import '../entities/request_history_entry.dart';

abstract class RequestHistoryRepository {
  /// Returns the saved request history entries in display order.
  Future<List<RequestHistoryEntry>> getRequestHistoryEntries();

  /// Persists one history entry after a request send completes.
  Future<void> saveRequestHistoryEntry(RequestHistoryEntry entry);

  /// Clears all saved history entries.
  Future<void> clearRequestHistory();
}
