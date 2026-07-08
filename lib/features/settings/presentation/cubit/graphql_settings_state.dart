import 'package:equatable/equatable.dart';

import '../../../request_builder/domain/entities/saved_graphql_query_entity.dart';
import '../../../request_builder/domain/entities/saved_graphql_variable_entity.dart';

enum GraphQlSettingsTab { queries, variables }

enum GraphQlSettingsStatus { initial, loading, loaded, saving, error }

class GraphQlSettingsState extends Equatable {
  const GraphQlSettingsState({
    this.status = GraphQlSettingsStatus.initial,
    this.selectedTab = GraphQlSettingsTab.queries,
    this.queries = const <SavedGraphQlQueryEntity>[],
    this.variables = const <SavedGraphQlVariableEntity>[],
    this.errorMessage,
  });

  final GraphQlSettingsStatus status;
  final GraphQlSettingsTab selectedTab;
  final List<SavedGraphQlQueryEntity> queries;
  final List<SavedGraphQlVariableEntity> variables;
  final String? errorMessage;

  GraphQlSettingsState copyWith({
    GraphQlSettingsStatus? status,
    GraphQlSettingsTab? selectedTab,
    List<SavedGraphQlQueryEntity>? queries,
    List<SavedGraphQlVariableEntity>? variables,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) => GraphQlSettingsState(
    status: status ?? this.status,
    selectedTab: selectedTab ?? this.selectedTab,
    queries: queries ?? this.queries,
    variables: variables ?? this.variables,
    errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    selectedTab,
    queries,
    variables,
    errorMessage,
  ];
}
