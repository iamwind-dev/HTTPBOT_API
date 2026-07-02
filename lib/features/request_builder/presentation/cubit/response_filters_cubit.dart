import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/response_filter_entity.dart';
import '../../domain/helpers/filter_response_mode.dart';
import '../../domain/repositories/response_filter_repository.dart';
import 'response_filters_state.dart';

class ResponseFiltersCubit extends Cubit<ResponseFiltersState> {
  ResponseFiltersCubit(this._repository) : super(const ResponseFiltersState());

  final ResponseFilterRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ResponseFiltersStatus.loading));
    final filters = await _repository.getFilters();
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(status: ResponseFiltersStatus.ready, filters: filters),
    );
  }

  /// Creates a new saved filter and refreshes the list.
  Future<void> create({
    required String name,
    required String query,
    required FilterResponseMode mode,
  }) async {
    final now = DateTime.now();
    await _repository.saveFilter(
      ResponseFilterEntity(
        id: now.microsecondsSinceEpoch.toString(),
        name: name.trim(),
        query: query.trim(),
        mode: mode,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
  }

  Future<void> update(ResponseFilterEntity filter) async {
    await _repository.updateFilter(
      filter.copyWith(updatedAt: DateTime.now()),
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.deleteFilter(id);
    await load();
  }
}
