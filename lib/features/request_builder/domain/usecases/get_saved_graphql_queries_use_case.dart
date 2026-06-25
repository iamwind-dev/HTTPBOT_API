import '../entities/saved_graphql_query_entity.dart';
import '../repositories/graphql_repository.dart';

class GetSavedGraphQlQueriesUseCase {
  const GetSavedGraphQlQueriesUseCase(this._repository);

  final GraphQlRepository _repository;

  Future<List<SavedGraphQlQueryEntity>> call() => _repository.getSavedQueries();
}
