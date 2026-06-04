import '../entities/request_draft.dart';
import '../entities/request_draft_session.dart';
import '../entities/request_variable_store.dart';
import '../entities/saved_request_draft.dart';

abstract interface class RequestBuilderRepository {
  /// Returns the active editor draft, restoring persisted state when available.
  Future<RequestDraft> getRequestDraft();

  /// Persists the latest editor draft so future loads resume from the same state.
  Future<void> saveRequestDraft(RequestDraft draft);

  /// Returns the latest active editing session if one was autosaved.
  Future<RequestDraftSession?> getCurrentRequestDraftSession();

  /// Persists the active editing session so unfinished edits can be restored.
  Future<void> saveCurrentRequestDraftSession(RequestDraftSession session);

  /// Clears the autosaved editing session after the user explicitly discards it.
  Future<void> clearCurrentRequestDraftSession();

  /// Returns the saved request list with each item's full draft payload.
  Future<List<SavedRequestDraft>> getSavedRequestDrafts();

  /// Persists the saved request list with each item's full draft payload.
  Future<void> saveSavedRequestDrafts(List<SavedRequestDraft> requests);

  /// Returns the global and environment variables available to the request editor.
  Future<RequestVariableStore> getRequestVariableStore();

  /// Persists the latest global/environment variable selection state for the editor.
  Future<void> saveRequestVariableStore(RequestVariableStore store);
}
