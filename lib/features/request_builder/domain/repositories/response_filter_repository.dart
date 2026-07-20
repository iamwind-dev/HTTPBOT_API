import '../entities/response_filter_entity.dart';

abstract class ResponseFilterRepository {
  Future<List<ResponseFilterEntity>> getFilters();

  Future<ResponseFilterEntity> saveFilter(ResponseFilterEntity filter);

  Future<ResponseFilterEntity> updateFilter(ResponseFilterEntity filter);

  Future<void> deleteFilter(String id);
}
