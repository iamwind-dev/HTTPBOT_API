import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:yaml/yaml.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/imported_collection_entity.dart';
import '../../domain/entities/openapi_directory_entry.dart';

class CollectionImportException implements Exception {
  const CollectionImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CollectionFileImporter {
  CollectionFileImporter({DioClient? dioClient})
    : _dioClient = dioClient ?? const DioClient();

  final DioClient _dioClient;

  Future<ImportedCollectionEntity?> pickAndImport(
    CollectionImportType type,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensionsFor(type),
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final content = await _readFileAsString(file);

    return switch (type) {
      CollectionImportType.har => _importHar(
        content: content,
        fallbackName: _basenameWithoutExtension(file.name),
      ),
      CollectionImportType.openApiSpec => _importOpenApiSpec(
        content: content,
        fallbackName: _basenameWithoutExtension(file.name),
      ),
      CollectionImportType.postmanCollection => _importPostmanCollection(
        content: content,
        fallbackName: _basenameWithoutExtension(file.name),
      ),
    };
  }

  bool isValidImportSpecUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    if (!uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.host.isEmpty) return false;
    return true;
  }

  Future<ImportedCollectionEntity> importOpenApiSpecUrl(
    String url, {
    String? fallbackName,
  }) async {
    final trimmedUrl = url.trim();
    if (!isValidImportSpecUrl(trimmedUrl)) {
      throw const CollectionImportException(
        'Please enter a valid http or https URL.',
      );
    }

    final content = await _fetchText(trimmedUrl);

    return importOpenApiSpecContent(
      content: content,
      fallbackName: fallbackName ?? trimmedUrl,
    );
  }

  ImportedCollectionEntity importOpenApiSpecContent({
    required String content,
    required String fallbackName,
  }) => _importOpenApiSpec(content: content, fallbackName: fallbackName);

  Future<List<OpenApiDirectoryEntry>> fetchOpenApiDirectoryEntries() async {
    final content = await _fetchText('https://api.apis.guru/v2/list.json');
    final root = _parseJsonMap(
      content,
      invalidMessage: 'Unable to read the OpenAPI directory.',
    );
    final entries = <OpenApiDirectoryEntry>[];

    for (final rawEntry in root.entries) {
      try {
        final apiId = rawEntry.key;
        final apiMeta = _asMap(
          rawEntry.value,
          'Invalid OpenAPI directory item.',
        );
        final preferredVersionName = _asNonEmptyString(
          apiMeta['preferred'],
          'OpenAPI directory item is missing "preferred".',
        );
        final versionsMap = _asMap(
          apiMeta['versions'],
          'OpenAPI directory item is missing "versions".',
        );
        final preferred = _asMap(
          versionsMap[preferredVersionName],
          'OpenAPI directory item is missing the preferred version details.',
        );
        final info = _asMap(
          _infoOrEmpty(preferred['info']),
          'Invalid directory info.',
        );
        final providerLabel = (info['x-providerName'] as String?)?.trim();
        final title = ((info['title'] as String?)?.trim().isNotEmpty ?? false)
            ? (info['title'] as String).trim()
            : _fallbackDirectoryTitle(apiId, providerLabel);
        final description = (info['description'] as String?)?.trim() ?? '';
        final logoUrl = preferred['info'] is Map
            ? _tryReadLogoUrl(
                Map<String, dynamic>.from(preferred['info'] as Map),
              )
            : null;
        final versions = _extractDirectoryVersions(versionsMap);

        if (versions.isEmpty) {
          continue;
        }

        entries.add(
          OpenApiDirectoryEntry(
            apiId: apiId,
            title: title,
            providerLabel: providerLabel == null || providerLabel.isEmpty
                ? apiId.split(':').first
                : providerLabel,
            description: description,
            logoUrl: logoUrl,
            versions: versions,
            preferredVersionName: 'v$preferredVersionName',
          ),
        );
      } catch (_) {
        continue;
      }
    }

    entries.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return entries;
  }

  List<String> allowedExtensionsFor(CollectionImportType type) {
    switch (type) {
      case CollectionImportType.har:
        return ['har'];
      case CollectionImportType.openApiSpec:
        return ['json', 'yaml', 'yml'];
      case CollectionImportType.postmanCollection:
        return ['json'];
    }
  }

  Future<String> _readFileAsString(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }

    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      throw const CollectionImportException(
        'Unable to read the selected file.',
      );
    }

    return File(path).readAsString();
  }

  ImportedCollectionEntity _importHar({
    required String content,
    required String fallbackName,
  }) {
    final root = _parseJsonMap(content, invalidMessage: 'Invalid HAR file.');
    final log = _asMap(root['log'], 'HAR file is missing "log".');
    final entries = _asList(
      log['entries'],
      'HAR file is missing "log.entries".',
    );

    if (entries.isEmpty) {
      throw const CollectionImportException('HAR file has no request entries.');
    }

    final requests = <ImportedCollectionRequestEntity>[];

    for (final entry in entries) {
      final entryMap = _asMap(entry, 'HAR contains an invalid entry.');
      final request = _asMap(
        entryMap['request'],
        'Each HAR entry must contain "request".',
      );
      final method = _asNonEmptyString(
        request['method'],
        'Each HAR request must contain "method".',
      );
      final url = _asNonEmptyString(
        request['url'],
        'Each HAR request must contain "url".',
      );

      requests.add(
        ImportedCollectionRequestEntity(
          method: method.toUpperCase(),
          title: '$method $url',
          url: url,
        ),
      );
    }

    return ImportedCollectionEntity(
      id: _buildImportedCollectionId(
        name: fallbackName,
        importType: CollectionImportType.har,
      ),
      name: fallbackName,
      description: '',
      importType: CollectionImportType.har,
      authLabel: 'No Auth',
      rootRequests: requests,
    );
  }

  ImportedCollectionEntity _importOpenApiSpec({
    required String content,
    required String fallbackName,
  }) {
    final root = _parseStructuredMap(
      content,
      invalidMessage: 'Invalid OpenAPI or Swagger spec.',
    );
    final hasOpenApi3 =
        (root['openapi'] as String?)?.trim().startsWith('3.') ?? false;
    final hasSwagger2 = (root['swagger'] as String?)?.trim() == '2.0';

    if (!hasOpenApi3 && !hasSwagger2) {
      throw const CollectionImportException(
        'Spec must contain openapi 3.x or swagger 2.0.',
      );
    }

    final paths = _asMap(root['paths'], 'Spec must contain "paths".');
    if (_countSpecOperations(paths) == 0) {
      throw const CollectionImportException(
        'Spec does not contain any supported HTTP operations.',
      );
    }

    final info = root['info'] is Map
        ? Map<String, dynamic>.from(root['info'] as Map)
        : <String, dynamic>{};
    final name = ((info['title'] as String?)?.trim().isNotEmpty ?? false)
        ? (info['title'] as String).trim()
        : fallbackName;
    final description = (info['description'] as String?)?.trim() ?? '';
    final (folders, rootRequests) = _extractOpenApiRequests(root);

    return ImportedCollectionEntity(
      id: _buildImportedCollectionId(
        name: name,
        importType: CollectionImportType.openApiSpec,
      ),
      name: name,
      description: description,
      importType: CollectionImportType.openApiSpec,
      variables: _buildOpenApiCollectionVariables(root),
      authLabel: 'No Auth',
      folders: folders,
      rootRequests: rootRequests,
    );
  }

  Future<String> _fetchText(String url) async {
    final dio = _dioClient.create(timeout: const Duration(seconds: 30));

    final response = await dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: const {
          'Accept': 'application/json, application/yaml, text/yaml, text/plain',
          'User-Agent': 'HTTPBot API',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const CollectionImportException(
        'The URL returned an empty response.',
      );
    }

    return body;
  }

  ImportedCollectionEntity _importPostmanCollection({
    required String content,
    required String fallbackName,
  }) {
    final root = _parseJsonMap(
      content,
      invalidMessage: 'Invalid Postman Collection file.',
    );
    final info = _asMap(
      root['info'],
      'Postman Collection must contain "info".',
    );
    final schema = _asNonEmptyString(
      info['schema'],
      'Postman Collection must contain "info.schema".',
    );

    if (schema !=
        'https://schema.getpostman.com/json/collection/v2.1.0/collection.json') {
      throw const CollectionImportException(
        'Only Postman Collection schema v2.1.0 is supported.',
      );
    }

    final item = _asList(
      root['item'],
      'Postman Collection must contain an "item" list.',
    );
    final requestCount = _countPostmanRequests(item);

    if (requestCount == 0) {
      throw const CollectionImportException(
        'Postman Collection does not contain any requests.',
      );
    }

    final name = _asNonEmptyString(
      info['name'],
      'Postman Collection must contain "info.name".',
    );

    return ImportedCollectionEntity(
      id: _buildImportedCollectionId(
        name: name,
        importType: CollectionImportType.postmanCollection,
      ),
      name: name,
      description: '',
      importType: CollectionImportType.postmanCollection,
      authLabel: 'No Auth',
      rootRequests: List<ImportedCollectionRequestEntity>.generate(
        requestCount,
        (index) => ImportedCollectionRequestEntity(
          method: 'REQ',
          title: 'Imported Request ${index + 1}',
          url: '',
        ),
      ),
    );
  }

  Map<String, dynamic> _parseJsonMap(
    String content, {
    required String invalidMessage,
  }) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    throw CollectionImportException(invalidMessage);
  }

  Map<String, dynamic> _parseStructuredMap(
    String content, {
    required String invalidMessage,
  }) {
    try {
      return _parseJsonMap(content, invalidMessage: invalidMessage);
    } on CollectionImportException {
      try {
        final yaml = loadYaml(content);
        final normalized = _normalizeYaml(yaml);
        if (normalized is Map<String, dynamic>) {
          return normalized;
        }
        if (normalized is Map) {
          return Map<String, dynamic>.from(normalized);
        }
      } catch (_) {}

      throw CollectionImportException(invalidMessage);
    }
  }

  dynamic _normalizeYaml(dynamic value) {
    if (value is YamlMap) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), _normalizeYaml(entry)),
      );
    }

    if (value is YamlList) {
      return value.map(_normalizeYaml).toList(growable: false);
    }

    return value;
  }

  Map<String, dynamic> _asMap(dynamic value, String message) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw CollectionImportException(message);
  }

  List<dynamic> _asList(dynamic value, String message) {
    if (value is List) {
      return value;
    }
    throw CollectionImportException(message);
  }

  String _asNonEmptyString(dynamic value, String message) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw CollectionImportException(message);
  }

  Map<String, dynamic> _infoOrEmpty(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  String? _tryReadLogoUrl(Map<String, dynamic> info) {
    final logo = info['x-logo'];
    if (logo is Map) {
      final url = logo['url'];
      if (url is String && url.trim().isNotEmpty) {
        return url.trim();
      }
    }
    return null;
  }

  String _fallbackDirectoryTitle(String apiId, String? providerLabel) {
    final serviceName = apiId.contains(':') ? apiId.split(':').last.trim() : '';
    if (serviceName.isNotEmpty) {
      return serviceName;
    }

    if (providerLabel != null && providerLabel.trim().isNotEmpty) {
      return providerLabel.trim();
    }

    return apiId.trim();
  }

  List<OpenApiDirectoryVersion> _extractDirectoryVersions(
    Map<String, dynamic> versions,
  ) {
    final entries = <OpenApiDirectoryVersion>[];

    for (final versionEntry in versions.entries) {
      if (versionEntry.value is! Map) {
        continue;
      }

      final version = Map<String, dynamic>.from(versionEntry.value as Map);
      final yamlUrl = (version['swaggerYamlUrl'] as String?)?.trim();
      final jsonUrl = (version['swaggerUrl'] as String?)?.trim();
      final specUrl = (yamlUrl != null && yamlUrl.isNotEmpty)
          ? yamlUrl
          : (jsonUrl ?? '');

      if (specUrl.isEmpty) {
        continue;
      }

      entries.add(
        OpenApiDirectoryVersion(name: 'v${versionEntry.key}', specUrl: specUrl),
      );
    }

    entries.sort((a, b) => a.name.compareTo(b.name));
    return entries;
  }

  int _countSpecOperations(Map<String, dynamic> paths) {
    var count = 0;

    for (final pathEntry in paths.entries) {
      if (pathEntry.value is! Map) {
        continue;
      }

      final operations = Map<String, dynamic>.from(pathEntry.value as Map);
      for (final operation in operations.entries) {
        if (!_isSupportedHttpMethod(operation.key.toLowerCase())) {
          continue;
        }
        if (operation.value is Map) {
          count += 1;
        }
      }
    }

    return count;
  }

  (List<ImportedCollectionFolderEntity>, List<ImportedCollectionRequestEntity>)
  _extractOpenApiRequests(Map<String, dynamic> root) {
    final paths = _asMap(root['paths'], 'Spec must contain "paths".');
    final folderRoots = <_FolderBuilder>[];
    final rootRequests = <ImportedCollectionRequestEntity>[];
    final baseUrl = _extractBaseUrl(root);
    final baseUrlValue = _extractConcreteBaseUrl(root);

    for (final pathEntry in paths.entries) {
      if (pathEntry.value is! Map) {
        continue;
      }

      final path = pathEntry.key;
      final pathItem = Map<String, dynamic>.from(pathEntry.value as Map);
      final operations = pathItem;

      for (final operationEntry in operations.entries) {
        final method = operationEntry.key.toLowerCase();
        if (!_isSupportedHttpMethod(method) || operationEntry.value is! Map) {
          continue;
        }

        final operation = Map<String, dynamic>.from(
          operationEntry.value as Map,
        );
        final resolvedParameters = _mergeResolvedParameters(
          root: root,
          pathItem: pathItem,
          operation: operation,
        );
        final request = ImportedCollectionRequestEntity(
          method: method.toUpperCase(),
          title: _operationTitle(
            operation: operation,
            method: method,
            path: path,
          ),
          url: '$baseUrl$path',
          baseUrlValue: baseUrlValue,
          queryParameters: _extractImportedFields(
            resolvedParameters,
            location: 'query',
          ),
          headers: _extractImportedFields(
            resolvedParameters,
            location: 'header',
          ),
          bodyContent: _extractBodyContent(root: root, operation: operation),
          bodyContentType: _extractBodyContentType(
            root: root,
            operation: operation,
          ),
        );
        final folderSegments = _folderSegmentsForPath(path);

        if (folderSegments.isEmpty) {
          rootRequests.add(request);
          continue;
        }

        final folder = _ensureFolderPath(folderRoots, folderSegments);
        folder.requests.add(request);
      }
    }

    final folders = folderRoots
        .map((folder) => folder.build())
        .toList(growable: false);

    return (folders, rootRequests);
  }

  bool _isSupportedHttpMethod(String method) {
    return const {
      'get',
      'post',
      'put',
      'delete',
      'patch',
      'head',
      'options',
      'trace',
      'connect',
    }.contains(method);
  }

  String _operationTitle({
    required Map<String, dynamic> operation,
    required String method,
    required String path,
  }) {
    final summary = (operation['summary'] as String?)?.trim();
    if (summary != null && summary.isNotEmpty) {
      return summary;
    }

    final operationId = (operation['operationId'] as String?)?.trim();
    if (operationId != null && operationId.isNotEmpty) {
      return operationId;
    }

    return '${method.toUpperCase()} $path';
  }

  List<String> _folderSegmentsForPath(String path) {
    return path
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .map((segment) => segment.trim())
        .toList(growable: false);
  }

  String _extractBaseUrl(Map<String, dynamic> root) {
    final servers = root['servers'];
    if (servers is List && servers.isNotEmpty) {
      return '{{baseUrl}}';
    }

    final host = (root['host'] as String?)?.trim();
    if (host != null && host.isNotEmpty) {
      final basePath = (root['basePath'] as String?)?.trim() ?? '';
      return '{{baseUrl}}$basePath';
    }

    return '{{baseUrl}}';
  }

  String _extractConcreteBaseUrl(Map<String, dynamic> root) {
    final servers = root['servers'];
    if (servers is List && servers.isNotEmpty) {
      final first = servers.first;
      if (first is Map) {
        final url = first['url'];
        if (url is String && url.trim().isNotEmpty) {
          return url.trim();
        }
      }
    }

    final host = (root['host'] as String?)?.trim();
    if (host != null && host.isNotEmpty) {
      final schemes = root['schemes'];
      final scheme =
          schemes is List && schemes.isNotEmpty && schemes.first is String
          ? (schemes.first as String).trim()
          : 'https';
      final basePath = (root['basePath'] as String?)?.trim() ?? '';
      return '$scheme://$host$basePath';
    }

    return '';
  }

  List<ImportedCollectionVariableEntity> _buildOpenApiCollectionVariables(
    Map<String, dynamic> root,
  ) {
    final baseUrlValue = _extractConcreteBaseUrl(root);
    if (baseUrlValue.trim().isEmpty) {
      return const <ImportedCollectionVariableEntity>[];
    }

    return <ImportedCollectionVariableEntity>[
      ImportedCollectionVariableEntity(name: 'baseUrl', value: baseUrlValue),
    ];
  }

  int _countPostmanRequests(List<dynamic> items) {
    var count = 0;

    for (final rawItem in items) {
      if (rawItem is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(rawItem);
      if (item['request'] is Map) {
        final request = Map<String, dynamic>.from(item['request'] as Map);
        final method = request['method'];
        final url = request['url'];

        final hasMethod = method is String && method.trim().isNotEmpty;
        final hasUrl = switch (url) {
          String value => value.trim().isNotEmpty,
          Map value => (value['raw'] as String?)?.trim().isNotEmpty ?? false,
          _ => false,
        };

        if (hasMethod && hasUrl) {
          count += 1;
        }
      }

      if (item['item'] is List) {
        count += _countPostmanRequests(
          List<dynamic>.from(item['item'] as List),
        );
      }
    }

    return count;
  }

  String _basenameWithoutExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName.trim().isEmpty ? 'Imported Collection' : fileName.trim();
    }

    final name = fileName.substring(0, dotIndex).trim();
    return name.isEmpty ? 'Imported Collection' : name;
  }

  String _buildImportedCollectionId({
    required String name,
    required CollectionImportType importType,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${importType.name}_${timestamp}_${name.hashCode}';
  }

  _FolderBuilder _ensureFolderPath(
    List<_FolderBuilder> roots,
    List<String> segments,
  ) {
    _FolderBuilder? current;
    var currentLevel = roots;

    for (final segment in segments) {
      final existingIndex = currentLevel.indexWhere(
        (folder) => folder.name == segment,
      );
      if (existingIndex >= 0) {
        current = currentLevel[existingIndex];
      } else {
        final created = _FolderBuilder(name: segment);
        currentLevel.add(created);
        current = created;
      }
      currentLevel = current.folders;
    }

    return current!;
  }

  List<Map<String, dynamic>> _mergeResolvedParameters({
    required Map<String, dynamic> root,
    required Map<String, dynamic> pathItem,
    required Map<String, dynamic> operation,
  }) {
    final resolved = <Map<String, dynamic>>[];

    void addParameters(dynamic rawValue) {
      if (rawValue is! List) {
        return;
      }

      for (final item in rawValue) {
        final parameter = _resolveReferencedMap(root, item);
        if (parameter != null) {
          resolved.add(parameter);
        }
      }
    }

    addParameters(pathItem['parameters']);
    addParameters(operation['parameters']);
    return resolved;
  }

  List<ImportedRequestFieldEntity> _extractImportedFields(
    List<Map<String, dynamic>> parameters, {
    required String location,
  }) {
    final fields = <ImportedRequestFieldEntity>[];

    for (final parameter in parameters) {
      final parameterLocation = (parameter['in'] as String?)?.trim();
      final name = (parameter['name'] as String?)?.trim();
      if (parameterLocation != location || name == null || name.isEmpty) {
        continue;
      }

      fields.add(
        ImportedRequestFieldEntity(
          name: name,
          value: _parameterDefaultValue(parameter),
          description: (parameter['description'] as String?)?.trim() ?? '',
        ),
      );
    }

    return fields;
  }

  String _parameterDefaultValue(Map<String, dynamic> parameter) {
    final schemaValue = _extractSchemaValue(parameter['schema']);
    if (schemaValue.isNotEmpty) {
      return schemaValue;
    }

    final example = _stringifyExampleValue(parameter['example']);
    if (example.isNotEmpty) {
      return example;
    }

    final examples = parameter['examples'];
    if (examples is Map) {
      for (final value in examples.values) {
        if (value is Map) {
          final candidate = _stringifyExampleValue(value['value']);
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
    }

    final directDefault = _stringifyExampleValue(parameter['default']);
    return directDefault;
  }

  String _extractSchemaValue(dynamic schema) {
    if (schema is! Map) {
      return '';
    }

    final map = Map<String, dynamic>.from(schema);
    final defaultValue = _stringifyExampleValue(map['default']);
    if (defaultValue.isNotEmpty) {
      return defaultValue;
    }

    final exampleValue = _stringifyExampleValue(map['example']);
    if (exampleValue.isNotEmpty) {
      return exampleValue;
    }

    return '';
  }

  String _extractBodyContent({
    required Map<String, dynamic> root,
    required Map<String, dynamic> operation,
  }) {
    final requestBody = _resolveRequestBody(root, operation);
    if (requestBody == null) {
      return '';
    }

    final content = requestBody['content'];
    if (content is Map) {
      final mediaTypeMap = _preferredMediaTypeMap(
        Map<String, dynamic>.from(content),
      );
      if (mediaTypeMap != null) {
        final example = _stringifyExampleValue(mediaTypeMap['example']);
        if (example.isNotEmpty) {
          return example;
        }

        final examples = mediaTypeMap['examples'];
        if (examples is Map) {
          for (final value in examples.values) {
            if (value is Map) {
              final candidate = _stringifyExampleValue(value['value']);
              if (candidate.isNotEmpty) {
                return candidate;
              }
            }
          }
        }
      }
    }

    final bodyParameter = _resolveSwaggerBodyParameter(root, operation);
    if (bodyParameter != null) {
      final schemaValue = _extractSchemaValue(bodyParameter['schema']);
      if (schemaValue.isNotEmpty) {
        return schemaValue;
      }
      return _stringifyExampleValue(bodyParameter['example']);
    }

    return '';
  }

  String _extractBodyContentType({
    required Map<String, dynamic> root,
    required Map<String, dynamic> operation,
  }) {
    final requestBody = _resolveRequestBody(root, operation);
    if (requestBody != null) {
      final content = requestBody['content'];
      if (content is Map) {
        final mediaType = _preferredMediaTypeName(
          Map<String, dynamic>.from(content),
        );
        if (mediaType.isNotEmpty) {
          return mediaType;
        }
      }
    }

    final consumes = operation['consumes'] ?? root['consumes'];
    if (consumes is List && consumes.isNotEmpty) {
      final first = consumes.first;
      if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }

    return '';
  }

  Map<String, dynamic>? _resolveRequestBody(
    Map<String, dynamic> root,
    Map<String, dynamic> operation,
  ) {
    final requestBody = operation['requestBody'];
    return _resolveReferencedMap(root, requestBody);
  }

  Map<String, dynamic>? _resolveSwaggerBodyParameter(
    Map<String, dynamic> root,
    Map<String, dynamic> operation,
  ) {
    final parameters = operation['parameters'];
    if (parameters is! List) {
      return null;
    }

    for (final parameter in parameters) {
      final resolved = _resolveReferencedMap(root, parameter);
      if (resolved == null) {
        continue;
      }

      if ((resolved['in'] as String?)?.trim() == 'body') {
        return resolved;
      }
    }

    return null;
  }

  Map<String, dynamic>? _preferredMediaTypeMap(Map<String, dynamic> content) {
    final preferredKeys = <String>[
      'application/json',
      'application/*+json',
      'application/x-www-form-urlencoded',
      'multipart/form-data',
      'text/plain',
    ];

    for (final key in preferredKeys) {
      final value = content[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    for (final value in content.values) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return null;
  }

  String _preferredMediaTypeName(Map<String, dynamic> content) {
    final preferredKeys = <String>[
      'application/json',
      'application/*+json',
      'application/x-www-form-urlencoded',
      'multipart/form-data',
      'text/plain',
    ];

    for (final key in preferredKeys) {
      if (content[key] is Map) {
        return key;
      }
    }

    for (final entry in content.entries) {
      if (entry.value is Map) {
        return entry.key;
      }
    }

    return '';
  }

  Map<String, dynamic>? _resolveReferencedMap(
    Map<String, dynamic> root,
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      final ref = value[r'$ref'];
      if (ref is String) {
        return _resolveRef(root, ref);
      }
      return value;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final ref = map[r'$ref'];
      if (ref is String) {
        return _resolveRef(root, ref);
      }
      return map;
    }
    return null;
  }

  Map<String, dynamic>? _resolveRef(Map<String, dynamic> root, String ref) {
    if (!ref.startsWith('#/')) {
      return null;
    }

    dynamic current = root;
    for (final segment in ref.substring(2).split('/')) {
      if (current is! Map) {
        return null;
      }

      final map = current is Map<String, dynamic>
          ? current
          : Map<String, dynamic>.from(current);
      current = map[segment];
    }

    if (current is Map<String, dynamic>) {
      return current;
    }
    if (current is Map) {
      return Map<String, dynamic>.from(current);
    }
    return null;
  }

  String _stringifyExampleValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value.trim();
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class _FolderBuilder {
  _FolderBuilder({required this.name});

  final String name;
  final List<_FolderBuilder> folders = <_FolderBuilder>[];
  final List<ImportedCollectionRequestEntity> requests =
      <ImportedCollectionRequestEntity>[];

  ImportedCollectionFolderEntity build() => ImportedCollectionFolderEntity(
    name: name,
    folders: folders.map((folder) => folder.build()).toList(growable: false),
    requests: List<ImportedCollectionRequestEntity>.unmodifiable(requests),
  );
}
