import '../entities/saved_graphql_variable_entity.dart';
import '../repositories/graphql_repository.dart';

class GetSavedGraphQlVariablesUseCase {
  const GetSavedGraphQlVariablesUseCase(this._repository);

  final GraphQlRepository _repository;

  Future<List<SavedGraphQlVariableEntity>> call() =>
      _repository.getSavedVariables();
}
