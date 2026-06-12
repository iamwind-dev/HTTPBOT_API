import 'package:equatable/equatable.dart';

class GraphQlBodyEntity extends Equatable {
  const GraphQlBodyEntity({
    this.query = '',
    this.variables = '',
    this.operationName,
  });

  final String query;
  final String variables;
  final String? operationName;

  GraphQlBodyEntity copyWith({
    String? query,
    String? variables,
    String? operationName,
    bool clearOperationName = false,
  }) => GraphQlBodyEntity(
    query: query ?? this.query,
    variables: variables ?? this.variables,
    operationName: clearOperationName
        ? null
        : operationName ?? this.operationName,
  );

  @override
  List<Object?> get props => [query, variables, operationName];
}
