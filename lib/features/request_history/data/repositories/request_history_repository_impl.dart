import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../request_builder/domain/entities/request_draft.dart';
import '../../domain/entities/request_history_entry.dart';
import '../../domain/repositories/request_history_repository.dart';
import '../request_history_entry_codec.dart';

class RequestHistoryRepositoryImpl implements RequestHistoryRepository {
  static const _storageKey = 'request_history_entries_v1';

  final List<RequestHistoryEntry> _entries = <RequestHistoryEntry>[];
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  /// Returns a read-only snapshot of all persisted history entries.
  @override
  Future<List<RequestHistoryEntry>> getRequestHistoryEntries() async {
    await _ensureLoaded();
    return List<RequestHistoryEntry>.unmodifiable(_entries);
  }

  /// Returns a read-only snapshot filtered to one method and URL scope.
  @override
  Future<List<RequestHistoryEntry>> getRequestHistoryEntriesForRequest(
    RequestDraft request,
  ) async {
    await _ensureLoaded();
    return List<RequestHistoryEntry>.unmodifiable(
      _entries.where((entry) => _isSameRequestScope(entry.request, request)),
    );
  }

  /// Inserts the latest history entry at the top so newest requests appear first.
  @override
  Future<void> saveRequestHistoryEntry(RequestHistoryEntry entry) async {
    await _ensureLoaded();

    final maxEntriesForRequest = entry.request.settings.savedResponsesInHistory;
    if (maxEntriesForRequest == 0) {
      _entries.removeWhere(
        (existingEntry) =>
            _isSameRequestScope(existingEntry.request, entry.request),
      );
      await _persist();
      return;
    }

    _entries.insert(0, entry);
    var keptForRequest = 0;
    _entries.removeWhere((existingEntry) {
      if (!_isSameRequestScope(existingEntry.request, entry.request)) {
        return false;
      }

      keptForRequest++;
      return keptForRequest > maxEntriesForRequest;
    });

    await _persist();
  }

  /// Removes every persisted history entry.
  @override
  Future<void> clearRequestHistory() async {
    await _ensureLoaded();
    _entries.clear();
    await _persist();
  }

  /// Deletes persisted history entries with one of the supplied IDs.
  @override
  Future<void> deleteRequestHistoryEntries(Set<String> entryIds) async {
    await _ensureLoaded();
    _entries.removeWhere((entry) => entryIds.contains(entry.id));
    await _persist();
  }

  /// Deletes all persisted responses for one request scope key.
  @override
  Future<void> deleteRequestHistoryForRequest(String requestId) async {
    await _ensureLoaded();
    _entries.removeWhere((entry) => _requestKey(entry.request) == requestId);
    await _persist();
  }

  /// Loads the local cache once and shares the in-flight load with concurrent reads.
  Future<void> _ensureLoaded() {
    if (_isLoaded) {
      return Future<void>.value();
    }

    return _loadFuture ??= _loadFromPreferences();
  }

  /// Restores valid history records while treating malformed local records as empty.
  Future<void> _loadFromPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final serializedEntries = preferences.getString(_storageKey);

    if (serializedEntries == null || serializedEntries.trim().isEmpty) {
      _isLoaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(serializedEntries);
      if (decoded is List) {
        _entries.addAll(
          decoded.map(_tryDecodeEntry).whereType<RequestHistoryEntry>(),
        );
      }
    } on FormatException {
      // A stale or corrupt cache must not prevent the request builder from opening.
    } finally {
      _isLoaded = true;
    }
  }

  /// Decodes one record and skips only records that cannot be restored safely.
  RequestHistoryEntry? _tryDecodeEntry(Object? value) {
    if (value is! Map) {
      return null;
    }

    try {
      return requestHistoryEntryFromJson(Map<String, dynamic>.from(value));
    } on Object {
      // Local cache records are disposable; no response data is logged on failure.
      return null;
    }
  }

  /// Writes the complete in-memory snapshot so retention and deletions survive restart.
  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(
        _entries.map(requestHistoryEntryToJson).toList(growable: false),
      ),
    );
  }

  /// Compares the method and URL that define one request's response history.
  bool _isSameRequestScope(RequestDraft left, RequestDraft right) =>
      left.method == right.method && left.url == right.url;

  /// Builds the stable scope key used by request-specific deletion.
  String _requestKey(RequestDraft request) =>
      '${request.method.wireName}|${request.url}';
}
