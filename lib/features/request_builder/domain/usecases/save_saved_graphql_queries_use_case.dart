import '../entities/saved_graphql_query_entity.dart';
import '../repositories/graphql_repository.dart';

class SaveSavedGraphQlQueriesUseCase {
  const SaveSavedGraphQlQueriesUseCase(this._repository);

  final GraphQlRepository _repository;

  Future<void> call(List<SavedGraphQlQueryEntity> queries) =>
      _repository.saveSavedQueries(queries);
}
