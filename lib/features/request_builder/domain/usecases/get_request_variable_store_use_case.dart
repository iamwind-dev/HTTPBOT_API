import '../entities/request_variable_store.dart';
import '../repositories/request_builder_repository.dart';

class GetRequestVariableStoreUseCase {
  const GetRequestVariableStoreUseCase(this._repository);

  final RequestBuilderRepository _repository;

  /// Returns the active variable store so request sending can resolve globals and environments.
  Future<RequestVariableStore> call() => _repository.getRequestVariableStore();
}
