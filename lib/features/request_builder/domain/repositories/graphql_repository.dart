import '../entities/graphql_schema_view_entity.dart';
import '../entities/request_draft.dart';
import '../entities/request_variable_store.dart';
import '../entities/saved_graphql_query_entity.dart';
import '../entities/saved_graphql_variable_entity.dart';

abstract interface class GraphQlRepository {
  Future<GraphQlSchemaViewEntity> fetchSchema({
    required RequestDraft draft,
    required RequestVariableStore variableStore,
  });

  Future<List<SavedGraphQlQueryEntity>> getSavedQueries();

  Future<void> saveSavedQueries(List<SavedGraphQlQueryEntity> queries);

  Future<List<SavedGraphQlVariableEntity>> getSavedVariables();

  Future<void> saveSavedVariables(List<SavedGraphQlVariableEntity> variables);
}
