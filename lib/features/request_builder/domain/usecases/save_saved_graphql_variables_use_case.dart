import '../entities/saved_graphql_variable_entity.dart';
import '../repositories/graphql_repository.dart';

class SaveSavedGraphQlVariablesUseCase {
  const SaveSavedGraphQlVariablesUseCase(this._repository);

  final GraphQlRepository _repository;

  Future<void> call(List<SavedGraphQlVariableEntity> variables) =>
      _repository.saveSavedVariables(variables);
}
