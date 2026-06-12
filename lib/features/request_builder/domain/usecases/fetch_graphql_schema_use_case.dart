import '../entities/graphql_schema_view_entity.dart';
import '../entities/request_draft.dart';
import '../entities/request_variable_store.dart';
import '../repositories/graphql_repository.dart';

class FetchGraphQlSchemaUseCase {
  const FetchGraphQlSchemaUseCase(this._repository);

  final GraphQlRepository _repository;

  Future<GraphQlSchemaViewEntity> call({
    required RequestDraft draft,
    required RequestVariableStore variableStore,
  }) => _repository.fetchSchema(draft: draft, variableStore: variableStore);
}
