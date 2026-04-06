import '../../domain/entities/requests_method.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/repositories/request_builder_repository.dart';

class RequestBuilderRepositoryImpl implements RequestBuilderRepository {
  RequestBuilderRepositoryImpl({RequestDraft? initialDraft})
    : _draft = initialDraft;

  static const RequestDraft _defaultDraft = RequestDraft(
    method: HttpMethod.get,
    url: 'https://api.example.com',
  );
  static const RequestVariableStore _defaultVariableStore =
      RequestVariableStore();

  RequestDraft? _draft;
  RequestVariableStore? _variableStore;

  /// Returns the latest in-memory draft until a real local data source is added.
  @override
  Future<RequestDraft> getRequestDraft() async => _draft ?? _defaultDraft;

  /// Stores the active draft in memory so the editor can restore recent edits.
  @override
  Future<void> saveRequestDraft(RequestDraft draft) async {
    _draft = draft;
  }

  /// Returns the latest variable store until a real local data source is added.
  @override
  Future<RequestVariableStore> getRequestVariableStore() async =>
      _variableStore ?? _defaultVariableStore;

  /// Stores the active variable state in memory so the editor can restore it later.
  @override
  Future<void> saveRequestVariableStore(RequestVariableStore store) async {
    _variableStore = store;
  }
}
