import '../entities/request_variable_store.dart';
import '../repositories/request_builder_repository.dart';

class SaveRequestVariableStoreUseCase {
  const SaveRequestVariableStoreUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Persists the variable store so environment selection and globals survive restarts.
  Future<void> call(RequestVariableStore store) =>
      _repository.saveRequestVariableStore(store);
}
