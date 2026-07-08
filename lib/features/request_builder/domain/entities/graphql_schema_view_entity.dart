import 'package:equatable/equatable.dart';

class GraphQlSchemaViewEntity extends Equatable {
  const GraphQlSchemaViewEntity({
    required this.rawJson,
    required this.formattedSchema,
    this.schema,
    this.errorMessage,
  });

  final String rawJson;
  final String formattedSchema;
  final GraphQlSchemaEntity? schema;
  final String? errorMessage;

  bool get hasError => (errorMessage?.trim().isNotEmpty ?? false);
  bool get hasSchema => schema != null;

  @override
  List<Object?> get props => [rawJson, formattedSchema, schema, errorMessage];
}

class GraphQlSchemaEntity extends Equatable {
  const GraphQlSchemaEntity({
    required this.types,
    this.queryTypeName,
    this.mutationTypeName,
    this.subscriptionTypeName,
  });

  final List<GraphQlTypeEntity> types;
  final String? queryTypeName;
  final String? mutationTypeName;
  final String? subscriptionTypeName;

  GraphQlTypeEntity? findType(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    for (final type in types) {
      if (type.name == name) {
        return type;
      }
    }

    return null;
  }

  List<GraphQlTypeEntity> get rootTypes => [
    if (findType(queryTypeName) case final query?) query,
    if (findType(mutationTypeName) case final mutation?) mutation,
    if (findType(subscriptionTypeName) case final subscription?) subscription,
  ];

  @override
  List<Object?> get props => [
    types,
    queryTypeName,
    mutationTypeName,
    subscriptionTypeName,
  ];
}

class GraphQlTypeEntity extends Equatable {
  const GraphQlTypeEntity({
    required this.kind,
    required this.name,
    this.description,
    this.fields = const <GraphQlFieldEntity>[],
    this.inputFields = const <GraphQlInputValueEntity>[],
    this.interfaces = const <GraphQlTypeRefEntity>[],
    this.enumValues = const <GraphQlEnumValueEntity>[],
    this.possibleTypes = const <GraphQlTypeRefEntity>[],
  });

  final String kind;
  final String name;
  final String? description;
  final List<GraphQlFieldEntity> fields;
  final List<GraphQlInputValueEntity> inputFields;
  final List<GraphQlTypeRefEntity> interfaces;
  final List<GraphQlEnumValueEntity> enumValues;
  final List<GraphQlTypeRefEntity> possibleTypes;

  @override
  List<Object?> get props => [
    kind,
    name,
    description,
    fields,
    inputFields,
    interfaces,
    enumValues,
    possibleTypes,
  ];
}

class GraphQlFieldEntity extends Equatable {
  const GraphQlFieldEntity({
    required this.name,
    required this.type,
    this.description,
    this.arguments = const <GraphQlInputValueEntity>[],
    this.isDeprecated = false,
  });

  final String name;
  final String? description;
  final List<GraphQlInputValueEntity> arguments;
  final GraphQlTypeRefEntity type;
  final bool isDeprecated;

  @override
  List<Object?> get props => [name, description, arguments, type, isDeprecated];
}

class GraphQlInputValueEntity extends Equatable {
  const GraphQlInputValueEntity({
    required this.name,
    required this.type,
    this.description,
    this.defaultValue,
  });

  final String name;
  final String? description;
  final GraphQlTypeRefEntity type;
  final String? defaultValue;

  @override
  List<Object?> get props => [name, description, type, defaultValue];
}

class GraphQlEnumValueEntity extends Equatable {
  const GraphQlEnumValueEntity({
    required this.name,
    this.description,
    this.isDeprecated = false,
  });

  final String name;
  final String? description;
  final bool isDeprecated;

  @override
  List<Object?> get props => [name, description, isDeprecated];
}

class GraphQlTypeRefEntity extends Equatable {
  const GraphQlTypeRefEntity({
    required this.kind,
    this.name,
    this.ofType,
  });

  final String kind;
  final String? name;
  final GraphQlTypeRefEntity? ofType;

  String get displayName => switch (kind) {
    'NON_NULL' => '${ofType?.displayName ?? 'Unknown'}!',
    'LIST' => '[${ofType?.displayName ?? 'Unknown'}]',
    _ => (name == null || name!.trim().isEmpty)
        ? (ofType?.displayName ?? 'Unknown')
        : name!,
  };

  String? get namedTypeName {
    if (name != null && name!.trim().isNotEmpty) {
      return name;
    }

    return ofType?.namedTypeName;
  }

  @override
  List<Object?> get props => [kind, name, ofType];
}
