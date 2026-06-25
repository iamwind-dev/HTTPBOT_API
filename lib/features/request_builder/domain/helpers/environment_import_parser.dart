import 'dart:convert';

import '../entities/request_environment.dart';
import '../entities/request_variable.dart';

class EnvironmentImportResult {
  const EnvironmentImportResult.success(RequestEnvironment this.environment)
    : errorMessage = null;

  const EnvironmentImportResult.failure(String this.errorMessage)
    : environment = null;

  final RequestEnvironment? environment;
  final String? errorMessage;

  bool get isSuccess => environment != null;
}

abstract final class EnvironmentImportParser {
  static const _invalidFileMessage = 'Invalid environment file.';

  /// Parses a Postman environment export or simple variables JSON document.
  ///
  /// Supported formats:
  /// - Postman: `{"name": "Dev", "values": [{"key", "value", "enabled"}]}`
  /// - Simple: `{"name": "Dev", "variables": {"key": "value"}}`
  static EnvironmentImportResult parse(
    String content, {
    required String environmentId,
    String fallbackName = '',
  }) {
    Object? decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      return const EnvironmentImportResult.failure(_invalidFileMessage);
    }

    if (decoded is! Map) {
      return const EnvironmentImportResult.failure(_invalidFileMessage);
    }

    final json = Map<String, dynamic>.from(decoded);
    // Postman full exports wrap the payload in an "environment" object.
    final payload = json['environment'] is Map
        ? Map<String, dynamic>.from(json['environment'] as Map)
        : json;

    final name = _stringOrEmpty(payload['name']).trim().isNotEmpty
        ? _stringOrEmpty(payload['name']).trim()
        : fallbackName.trim();
    if (name.isEmpty) {
      return const EnvironmentImportResult.failure(_invalidFileMessage);
    }

    final variables = payload['values'] is List
        ? _variablesFromPostmanValues(payload['values'] as List)
        : payload['variables'] is Map
        ? _variablesFromSimpleMap(payload['variables'] as Map)
        : const <RequestVariable>[];

    return EnvironmentImportResult.success(
      RequestEnvironment(id: environmentId, name: name, variables: variables),
    );
  }

  /// Appends " (n)" until the name no longer clashes with an existing one.
  static String resolveUniqueName(String name, Iterable<String> existingNames) {
    final existing = existingNames.toSet();
    if (!existing.contains(name)) {
      return name;
    }

    var suffix = 1;
    while (existing.contains('$name ($suffix)')) {
      suffix++;
    }

    return '$name ($suffix)';
  }

  static List<RequestVariable> _variablesFromPostmanValues(List values) =>
      values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => _stringOrEmpty(item['key']).trim().isNotEmpty)
          .map(
            (item) => RequestVariable(
              key: _stringOrEmpty(item['key']).trim(),
              currentValue: _stringOrEmpty(item['value']),
              scope: RequestVariableScope.environment,
              isEnabled: item['enabled'] is bool
                  ? item['enabled'] as bool
                  : true,
            ),
          )
          .toList(growable: false);

  static List<RequestVariable> _variablesFromSimpleMap(Map variables) =>
      variables.entries
          .where((entry) => entry.key.toString().trim().isNotEmpty)
          .map(
            (entry) => RequestVariable(
              key: entry.key.toString().trim(),
              currentValue: _stringOrEmpty(entry.value),
              scope: RequestVariableScope.environment,
            ),
          )
          .toList(growable: false);

  static String _stringOrEmpty(Object? value) =>
      value is String ? value : value?.toString() ?? '';
}
