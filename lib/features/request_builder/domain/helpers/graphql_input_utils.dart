import 'dart:convert';

Map<String, dynamic> parseGraphQlVariablesJson(String variables) {
  final trimmed = variables.trim();
  if (trimmed.isEmpty) {
    return <String, dynamic>{};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException {
    throw const FormatException(
      'GraphQL variables must be a valid JSON object',
    );
  }

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  throw const FormatException('GraphQL variables must be a JSON object');
}

String? validateGraphQlVariablesInput(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  try {
    parseGraphQlVariablesJson(trimmed);
    return null;
  } on FormatException catch (error) {
    return '${error.message}.';
  }
}

String buildSavedGraphQlQueryName({
  required String? proposedName,
  required String query,
}) {
  final explicitName = proposedName?.trim() ?? '';
  if (explicitName.isNotEmpty) {
    return explicitName;
  }

  final compact = query
      .split('\n')
      .map((line) => line.trim())
      .firstWhere(
        (line) =>
            line.isNotEmpty &&
            line != '{' &&
            line != '}' &&
            !line.startsWith('#'),
        orElse: () => '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (compact.isEmpty) {
    return 'Query';
  }

  return compact.length <= 36 ? compact : '${compact.substring(0, 33)}...';
}

String buildSavedGraphQlVariablesName({
  required String? proposedName,
  required String variablesJson,
}) {
  final explicitName = proposedName?.trim() ?? '';
  if (explicitName.isNotEmpty) {
    return explicitName;
  }

  try {
    final variables = parseGraphQlVariablesJson(variablesJson);
    if (variables.isEmpty) {
      return 'Variables';
    }

    final firstKey = variables.keys.first.trim();
    return firstKey.isEmpty ? 'Variables' : firstKey;
  } on FormatException {
    return 'Variables';
  }
}
