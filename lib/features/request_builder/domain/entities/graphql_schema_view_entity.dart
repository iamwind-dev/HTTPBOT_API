import 'package:equatable/equatable.dart';

class GraphQlSchemaViewEntity extends Equatable {
  const GraphQlSchemaViewEntity({
    required this.rawJson,
    required this.formattedSchema,
    this.errorMessage,
  });

  final String rawJson;
  final String formattedSchema;
  final String? errorMessage;

  bool get hasError => (errorMessage?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [rawJson, formattedSchema, errorMessage];
}
