import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/graphql_schema_view_entity.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/entities/saved_graphql_query_entity.dart';
import '../../domain/entities/saved_graphql_variable_entity.dart';
import '../../domain/repositories/graphql_repository.dart';
import '../../domain/usecases/apply_request_auth_use_case.dart';
import '../../domain/usecases/resolve_request_use_case.dart';
import '../mappers/request_body_mapper.dart';
import '../models/saved_graphql_query_model.dart';
import '../models/saved_graphql_variable_model.dart';

class GraphQlRepositoryImpl implements GraphQlRepository {
  GraphQlRepositoryImpl(
    this._dioClient,
    this._resolveRequestUseCase,
    this._applyRequestAuthUseCase,
  );

  static const _savedQueriesStorageKey =
      'request_builder_saved_graphql_queries';
  static const _savedVariablesStorageKey =
      'request_builder_saved_graphql_variables';
  static const _introspectionQuery = r'''
query IntrospectionQuery {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          name
          description
          type {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
          defaultValue
        }
        type {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
        isDeprecated
      }
      inputFields {
        name
        description
        type {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
            }
          }
        }
        defaultValue
      }
      interfaces {
        kind
        name
        ofType {
          kind
          name
        }
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
      }
      possibleTypes {
        kind
        name
        ofType {
          kind
          name
        }
      }
    }
  }
}
''';

  final ApplyRequestAuthUseCase _applyRequestAuthUseCase;
  final DioClient _dioClient;
  final ResolveRequestUseCase _resolveRequestUseCase;

  List<SavedGraphQlQueryEntity>? _queriesCache;
  List<SavedGraphQlVariableEntity>? _variablesCache;

  @override
  Future<GraphQlSchemaViewEntity> fetchSchema({
    required RequestDraft draft,
    required RequestVariableStore variableStore,
  }) async {
    final schemaDraft = draft.copyWith(
      method: HttpMethod.post,
      headers: _upsertContentTypeHeader(draft.headers),
      body: const RequestBodyDraft(
        type: RequestBodyType.graphql,
        graphQl: GraphQlBodyDraft(query: _introspectionQuery),
      ),
    );
    final resolvedRequest = _resolveRequestUseCase(
      draft: schemaDraft,
      variableStore: variableStore,
    );
    final authAppliedRequest = _applyRequestAuthUseCase(
      resolvedRequest: resolvedRequest,
    );
    final preparedRequest = authAppliedRequest.request;
    final payload = await buildRequestBodyPayload(preparedRequest.body);
    final dio = _dioClient.create(
      timeout: preparedRequest.timeout,
      verifySsl: preparedRequest.verifySsl,
    );

    try {
      final response = await dio.request<Object?>(
        preparedRequest.url,
        data: payload.data,
        options: Options(
          method: HttpMethod.post.wireName,
          headers: _headersToMap(preparedRequest.headers),
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
      final rawMap = _normalizeResponseBody(response.data);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(rawMap);
      final serverErrors = _extractGraphQlErrors(rawMap);

      return GraphQlSchemaViewEntity(
        rawJson: prettyJson,
        formattedSchema: _formatSchema(rawMap),
        errorMessage: serverErrors,
      );
    } on DioException catch (error) {
      throw Exception(_dioErrorMessage(error));
    }
  }

  @override
  Future<List<SavedGraphQlQueryEntity>> getSavedQueries() async {
    final cached = _queriesCache;
    if (cached != null) {
      return cached;
    }

    final restored = await _restoreQueries();
    _queriesCache = restored;
    return restored;
  }

  @override
  Future<List<SavedGraphQlVariableEntity>> getSavedVariables() async {
    final cached = _variablesCache;
    if (cached != null) {
      return cached;
    }

    final restored = await _restoreVariables();
    _variablesCache = restored;
    return restored;
  }

  @override
  Future<void> saveSavedQueries(List<SavedGraphQlQueryEntity> queries) async {
    _queriesCache = List<SavedGraphQlQueryEntity>.unmodifiable(queries);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedQueriesStorageKey,
      jsonEncode(
        queries
            .map(SavedGraphQlQueryModel.fromEntity)
            .map((model) => model.toJson())
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<void> saveSavedVariables(
    List<SavedGraphQlVariableEntity> variables,
  ) async {
    _variablesCache = List<SavedGraphQlVariableEntity>.unmodifiable(variables);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedVariablesStorageKey,
      jsonEncode(
        variables
            .map(SavedGraphQlVariableModel.fromEntity)
            .map((model) => model.toJson())
            .toList(growable: false),
      ),
    );
  }

  Future<List<SavedGraphQlQueryEntity>> _restoreQueries() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_savedQueriesStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <SavedGraphQlQueryEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedGraphQlQueryEntity>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedGraphQlQueryModel.fromJson(
              Map<String, dynamic>.from(item),
            ).toEntity(),
          )
          .toList(growable: false);
    } catch (_) {
      return const <SavedGraphQlQueryEntity>[];
    }
  }

  Future<List<SavedGraphQlVariableEntity>> _restoreVariables() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_savedVariablesStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <SavedGraphQlVariableEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedGraphQlVariableEntity>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedGraphQlVariableModel.fromJson(
              Map<String, dynamic>.from(item),
            ).toEntity(),
          )
          .toList(growable: false);
    } catch (_) {
      return const <SavedGraphQlVariableEntity>[];
    }
  }

  List<KeyValueItem> _upsertContentTypeHeader(List<KeyValueItem> headers) {
    final nextHeaders = <KeyValueItem>[];
    var updated = false;

    for (final header in headers) {
      if (header.key.trim().toLowerCase() == 'content-type') {
        if (!updated) {
          nextHeaders.add(
            header.copyWith(
              key: 'Content-Type',
              value: 'application/json',
              isEnabled: true,
              description: '',
            ),
          );
          updated = true;
        }
        continue;
      }

      nextHeaders.add(header);
    }

    if (!updated) {
      nextHeaders.add(
        const KeyValueItem(key: 'Content-Type', value: 'application/json'),
      );
    }

    return List<KeyValueItem>.unmodifiable(nextHeaders);
  }

  Map<String, String> _headersToMap(List<KeyValueItem> headers) {
    final mapped = <String, String>{};

    for (final header in headers.where(
      (item) => item.isEnabled && item.hasKey,
    )) {
      mapped[header.key] = header.value;
    }

    return mapped;
  }

  Map<String, dynamic> _normalizeResponseBody(Object? body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    if (body is String && body.trim().isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    return <String, dynamic>{'data': body};
  }

  String? _extractGraphQlErrors(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is! List || errors.isEmpty) {
      return null;
    }

    final messages = errors
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map((item) => item['message']?.toString().trim() ?? '')
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
    if (messages.isEmpty) {
      return 'GraphQL server returned errors.';
    }

    return messages.join('\n');
  }

  String _formatSchema(Map<String, dynamic> body) {
    final schema = body['data'];
    if (schema is! Map) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }

    final schemaMap = Map<String, dynamic>.from(schema);
    final root = schemaMap['__schema'];
    if (root is! Map) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }

    final rootMap = Map<String, dynamic>.from(root);
    final types = rootMap['types'];
    if (types is! List) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }

    final buffer = StringBuffer();

    for (final typeEntry in types.whereType<Map>()) {
      final type = Map<String, dynamic>.from(typeEntry);
      final kind = type['kind']?.toString() ?? '';
      final name = type['name']?.toString() ?? '';
      if (name.isEmpty || name.startsWith('__')) {
        continue;
      }

      switch (kind) {
        case 'OBJECT':
        case 'INPUT_OBJECT':
          final fieldsKey = kind == 'INPUT_OBJECT' ? 'inputFields' : 'fields';
          final fields = type[fieldsKey] as List?;
          buffer.writeln(
            '${kind == 'INPUT_OBJECT' ? 'input' : 'type'} $name {',
          );
          if (fields != null) {
            for (final fieldEntry in fields.whereType<Map>()) {
              final field = Map<String, dynamic>.from(fieldEntry);
              final fieldName = field['name']?.toString() ?? '';
              final fieldType = _renderType(field['type']);
              if (fieldName.isNotEmpty) {
                buffer.writeln('  $fieldName: $fieldType');
              }
            }
          }
          buffer.writeln('}\n');
        case 'ENUM':
          final values = type['enumValues'] as List?;
          buffer.writeln('enum $name {');
          if (values != null) {
            for (final value in values.whereType<Map>()) {
              final enumName = value['name']?.toString() ?? '';
              if (enumName.isNotEmpty) {
                buffer.writeln('  $enumName');
              }
            }
          }
          buffer.writeln('}\n');
        case 'SCALAR':
          buffer.writeln('scalar $name\n');
      }
    }

    final formatted = buffer.toString().trim();
    if (formatted.isEmpty) {
      return const JsonEncoder.withIndent('  ').convert(body);
    }

    return formatted;
  }

  String _renderType(Object? value) {
    if (value is! Map) {
      return 'Unknown';
    }

    final map = Map<String, dynamic>.from(value);
    final kind = map['kind']?.toString() ?? '';
    final name = map['name']?.toString();
    final nested = map['ofType'];

    return switch (kind) {
      'NON_NULL' => '${_renderType(nested)}!',
      'LIST' => '[${_renderType(nested)}]',
      _ => (name == null || name.isEmpty) ? _renderType(nested) : name,
    };
  }

  String _dioErrorMessage(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Network timeout while loading GraphQL schema.';
    }
    if (error.response?.data != null) {
      return 'Schema request failed: ${error.response?.data}';
    }
    return error.message ?? 'Schema request failed.';
  }
}
