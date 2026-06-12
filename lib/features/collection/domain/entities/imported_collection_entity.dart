import 'collection_import_type.dart';

class ImportedCollectionVariableEntity {
  const ImportedCollectionVariableEntity({
    required this.name,
    required this.value,
    this.isEnabled = true,
  });

  final String name;
  final String value;
  final bool isEnabled;

  ImportedCollectionVariableEntity copyWith({
    String? name,
    String? value,
    bool? isEnabled,
  }) => ImportedCollectionVariableEntity(
    name: name ?? this.name,
    value: value ?? this.value,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}

class ImportedRequestFieldEntity {
  const ImportedRequestFieldEntity({
    required this.name,
    this.value = '',
    this.description = '',
  });

  final String name;
  final String value;
  final String description;
}

class ImportedCollectionRequestEntity {
  const ImportedCollectionRequestEntity({
    required this.method,
    required this.title,
    required this.url,
    this.baseUrlValue = '',
    this.queryParameters = const <ImportedRequestFieldEntity>[],
    this.headers = const <ImportedRequestFieldEntity>[],
    this.bodyContent = '',
    this.bodyContentType = '',
  });

  final String method;
  final String title;
  final String url;
  final String baseUrlValue;
  final List<ImportedRequestFieldEntity> queryParameters;
  final List<ImportedRequestFieldEntity> headers;
  final String bodyContent;
  final String bodyContentType;
}

class ImportedCollectionFolderEntity {
  const ImportedCollectionFolderEntity({
    required this.name,
    this.folders = const <ImportedCollectionFolderEntity>[],
    this.requests = const <ImportedCollectionRequestEntity>[],
  });

  final String name;
  final List<ImportedCollectionFolderEntity> folders;
  final List<ImportedCollectionRequestEntity> requests;

  int get requestCount {
    final childFolderRequests = folders.fold<int>(
      0,
      (sum, folder) => sum + folder.requestCount,
    );

    return childFolderRequests + requests.length;
  }
}

class ImportedCollectionEntity {
  const ImportedCollectionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.importType,
    this.variables = const <ImportedCollectionVariableEntity>[],
    this.authLabel = 'No Auth',
    this.folders = const [],
    this.rootRequests = const [],
  });

  final String id;
  final String name;
  final String description;
  final CollectionImportType importType;
  final List<ImportedCollectionVariableEntity> variables;
  final String authLabel;
  final List<ImportedCollectionFolderEntity> folders;
  final List<ImportedCollectionRequestEntity> rootRequests;

  ImportedCollectionEntity copyWith({
    String? name,
    String? description,
    List<ImportedCollectionVariableEntity>? variables,
    String? authLabel,
    List<ImportedCollectionFolderEntity>? folders,
    List<ImportedCollectionRequestEntity>? rootRequests,
  }) => ImportedCollectionEntity(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    importType: importType,
    variables: variables ?? this.variables,
    authLabel: authLabel ?? this.authLabel,
    folders: folders ?? this.folders,
    rootRequests: rootRequests ?? this.rootRequests,
  );

  int get itemCount {
    if (folders.isNotEmpty) {
      return folders.length;
    }

    return rootRequests.length;
  }

  int get requestCount {
    final folderRequests = folders.fold<int>(
      0,
      (sum, folder) => sum + folder.requestCount,
    );

    return folderRequests + rootRequests.length;
  }
}
