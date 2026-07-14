import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../request_builder/domain/entities/saved_graphql_query_entity.dart';
import '../../../request_builder/domain/entities/saved_graphql_variable_entity.dart';
import '../../../request_builder/domain/usecases/get_saved_graphql_queries_use_case.dart';
import '../../../request_builder/domain/usecases/get_saved_graphql_variables_use_case.dart';
import '../../../request_builder/domain/usecases/save_saved_graphql_queries_use_case.dart';
import '../../../request_builder/domain/usecases/save_saved_graphql_variables_use_case.dart';
import 'graphql_settings_state.dart';

class GraphQlSettingsCubit extends Cubit<GraphQlSettingsState> {
  GraphQlSettingsCubit({
    required GetSavedGraphQlQueriesUseCase getSavedGraphQlQueriesUseCase,
    required SaveSavedGraphQlQueriesUseCase saveSavedGraphQlQueriesUseCase,
    required GetSavedGraphQlVariablesUseCase getSavedGraphQlVariablesUseCase,
    required SaveSavedGraphQlVariablesUseCase saveSavedGraphQlVariablesUseCase,
  }) : _getSavedGraphQlQueriesUseCase = getSavedGraphQlQueriesUseCase,
       _saveSavedGraphQlQueriesUseCase = saveSavedGraphQlQueriesUseCase,
       _getSavedGraphQlVariablesUseCase = getSavedGraphQlVariablesUseCase,
       _saveSavedGraphQlVariablesUseCase = saveSavedGraphQlVariablesUseCase,
       super(const GraphQlSettingsState());

  final GetSavedGraphQlQueriesUseCase _getSavedGraphQlQueriesUseCase;
  final SaveSavedGraphQlQueriesUseCase _saveSavedGraphQlQueriesUseCase;
  final GetSavedGraphQlVariablesUseCase _getSavedGraphQlVariablesUseCase;
  final SaveSavedGraphQlVariablesUseCase _saveSavedGraphQlVariablesUseCase;

  Future<void> load() async {
    emit(state.copyWith(status: GraphQlSettingsStatus.loading));

    try {
      final queries = await _getSavedGraphQlQueriesUseCase();
      final variables = await _getSavedGraphQlVariablesUseCase();

      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.loaded,
          queries: queries.reversed.toList(growable: false),
          variables: variables.reversed.toList(growable: false),
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void switchTab(GraphQlSettingsTab tab) {
    emit(
      state.copyWith(
        selectedTab: tab,
        status: state.status == GraphQlSettingsStatus.initial
            ? GraphQlSettingsStatus.loading
            : state.status,
      ),
    );
  }

  Future<void> saveQuery(SavedGraphQlQueryEntity query) async {
    final queries = List<SavedGraphQlQueryEntity>.from(state.queries);
    final index = queries.indexWhere((item) => item.id == query.id);
    if (index >= 0) {
      queries[index] = query;
    } else {
      queries.insert(0, query);
    }

    await _persistQueries(queries);
  }

  Future<void> deleteQuery(String id) async {
    final queries = state.queries
        .where((item) => item.id != id)
        .toList(growable: false);
    await _persistQueries(queries);
  }

  Future<void> saveVariables(SavedGraphQlVariableEntity variables) async {
    final allVariables = List<SavedGraphQlVariableEntity>.from(state.variables);
    final index = allVariables.indexWhere((item) => item.id == variables.id);
    if (index >= 0) {
      allVariables[index] = variables;
    } else {
      allVariables.insert(0, variables);
    }

    await _persistVariables(allVariables);
  }

  Future<void> deleteVariables(String id) async {
    final variables = state.variables
        .where((item) => item.id != id)
        .toList(growable: false);
    await _persistVariables(variables);
  }

  Future<void> _persistQueries(List<SavedGraphQlQueryEntity> queries) async {
    emit(state.copyWith(status: GraphQlSettingsStatus.saving));

    try {
      await _saveSavedGraphQlQueriesUseCase(
        queries.reversed.toList(growable: false),
      );
      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.loaded,
          queries: queries,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _persistVariables(
    List<SavedGraphQlVariableEntity> variables,
  ) async {
    emit(state.copyWith(status: GraphQlSettingsStatus.saving));

    try {
      await _saveSavedGraphQlVariablesUseCase(
        variables.reversed.toList(growable: false),
      );
      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.loaded,
          variables: variables,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: GraphQlSettingsStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
