import '../entities/request_draft.dart';
import '../entities/request_variable_store.dart';

abstract interface class RequestBuilderRepository {
  /// Returns the active editor draft, restoring persisted state when available.
  Future<RequestDraft> getRequestDraft();

  /// Persists the latest editor draft so future loads resume from the same state.
  Future<void> saveRequestDraft(RequestDraft draft);

  /// Returns the global and environment variables available to the request editor.
  Future<RequestVariableStore> getRequestVariableStore();

  /// Persists the latest global/environment variable selection state for the editor.
  Future<void> saveRequestVariableStore(RequestVariableStore store);
}
