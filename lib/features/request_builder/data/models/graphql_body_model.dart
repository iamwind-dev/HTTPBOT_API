import '../../domain/entities/graphql_body_entity.dart';

class GraphQlBodyModel {
  const GraphQlBodyModel({
    this.query = '',
    this.variables = '',
    this.operationName,
  });

  final String query;
  final String variables;
  final String? operationName;

  factory GraphQlBodyModel.fromEntity(GraphQlBodyEntity entity) =>
      GraphQlBodyModel(
        query: entity.query,
        variables: entity.variables,
        operationName: entity.operationName,
      );

  factory GraphQlBodyModel.fromJson(Map<String, dynamic> json) =>
      GraphQlBodyModel(
        query: json['query'] as String? ?? '',
        variables: json['variables'] as String? ?? '',
        operationName: json['operationName'] as String?,
      );

  GraphQlBodyEntity toEntity() => GraphQlBodyEntity(
    query: query,
    variables: variables,
    operationName: operationName,
  );

  Map<String, Object?> toJson() => {
    'query': query,
    'variables': variables,
    'operationName': operationName,
  };
}
