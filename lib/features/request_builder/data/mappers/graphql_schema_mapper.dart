import '../../domain/entities/graphql_schema_view_entity.dart';

GraphQlSchemaEntity? parseGraphQlSchemaFromResponse(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is! Map) {
    return null;
  }

  final schemaRoot = data['__schema'];
  if (schemaRoot is! Map) {
    return null;
  }

  final schemaMap = Map<String, dynamic>.from(schemaRoot);
  final rawTypes = schemaMap['types'];
  if (rawTypes is! List) {
    return null;
  }

  return GraphQlSchemaEntity(
    types: rawTypes
        .whereType<Map>()
        .map((type) => _parseType(Map<String, dynamic>.from(type)))
        .where((type) => type.name.isNotEmpty && !type.name.startsWith('__'))
        .toList(growable: false),
    queryTypeName: _extractNamedRootType(schemaMap['queryType']),
    mutationTypeName: _extractNamedRootType(schemaMap['mutationType']),
    subscriptionTypeName: _extractNamedRootType(schemaMap['subscriptionType']),
  );
}

GraphQlTypeEntity _parseType(Map<String, dynamic> json) => GraphQlTypeEntity(
  kind: json['kind']?.toString() ?? '',
  name: json['name']?.toString() ?? '',
  description: _normalizeNullableText(json['description']?.toString()),
  fields: (json['fields'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((field) => _parseField(Map<String, dynamic>.from(field)))
      .toList(growable: false),
  inputFields: (json['inputFields'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((field) => _parseInputValue(Map<String, dynamic>.from(field)))
      .toList(growable: false),
  interfaces: (json['interfaces'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((item) => _parseTypeRef(Map<String, dynamic>.from(item)))
      .toList(growable: false),
  enumValues: (json['enumValues'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((item) => _parseEnumValue(Map<String, dynamic>.from(item)))
      .toList(growable: false),
  possibleTypes: (json['possibleTypes'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((item) => _parseTypeRef(Map<String, dynamic>.from(item)))
      .toList(growable: false),
);

GraphQlFieldEntity _parseField(Map<String, dynamic> json) => GraphQlFieldEntity(
  name: json['name']?.toString() ?? '',
  description: _normalizeNullableText(json['description']?.toString()),
  arguments: (json['args'] as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((item) => _parseInputValue(Map<String, dynamic>.from(item)))
      .toList(growable: false),
  type: _parseTypeRef(Map<String, dynamic>.from(json['type'] as Map? ?? {})),
  isDeprecated: json['isDeprecated'] == true,
);

GraphQlInputValueEntity _parseInputValue(Map<String, dynamic> json) =>
    GraphQlInputValueEntity(
      name: json['name']?.toString() ?? '',
      description: _normalizeNullableText(json['description']?.toString()),
      type: _parseTypeRef(Map<String, dynamic>.from(json['type'] as Map? ?? {})),
      defaultValue: _normalizeNullableText(json['defaultValue']?.toString()),
    );

GraphQlEnumValueEntity _parseEnumValue(Map<String, dynamic> json) =>
    GraphQlEnumValueEntity(
      name: json['name']?.toString() ?? '',
      description: _normalizeNullableText(json['description']?.toString()),
      isDeprecated: json['isDeprecated'] == true,
    );

GraphQlTypeRefEntity _parseTypeRef(Map<String, dynamic> json) =>
    GraphQlTypeRefEntity(
      kind: json['kind']?.toString() ?? '',
      name: _normalizeNullableText(json['name']?.toString()),
      ofType: json['ofType'] is Map
          ? _parseTypeRef(Map<String, dynamic>.from(json['ofType'] as Map))
          : null,
    );

String? _extractNamedRootType(Object? value) {
  if (value is! Map) {
    return null;
  }

  return _normalizeNullableText(value['name']?.toString());
}

String? _normalizeNullableText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
