import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/imported_collection_entity.dart';

class PersistedCollectionsSnapshot {
  const PersistedCollectionsSnapshot({
    required this.items,
    required this.selectedCollectionId,
  });

  final List<ImportedCollectionEntity> items;
  final String? selectedCollectionId;
}

class CollectionLocalStore {
  static const _collectionsStorageKey = 'collections_persisted_items';
  static const _selectedCollectionIdStorageKey =
      'collections_selected_collection_id';

  Future<PersistedCollectionsSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCollections = preferences.getString(_collectionsStorageKey);
    final selectedCollectionId = preferences.getString(
      _selectedCollectionIdStorageKey,
    );

    if (rawCollections == null || rawCollections.trim().isEmpty) {
      return PersistedCollectionsSnapshot(
        items: const <ImportedCollectionEntity>[],
        selectedCollectionId: selectedCollectionId,
      );
    }

    try {
      final decoded = jsonDecode(rawCollections);
      final items = _collectionListFromJson(decoded);
      final selectedId = items.any((item) => item.id == selectedCollectionId)
          ? selectedCollectionId
          : null;

      return PersistedCollectionsSnapshot(
        items: items,
        selectedCollectionId: selectedId,
      );
    } catch (_) {
      return const PersistedCollectionsSnapshot(
        items: <ImportedCollectionEntity>[],
        selectedCollectionId: null,
      );
    }
  }

  Future<void> save({
    required List<ImportedCollectionEntity> items,
    required String? selectedCollectionId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _collectionsStorageKey,
      jsonEncode(items.map(_collectionToJson).toList(growable: false)),
    );

    if (selectedCollectionId == null || selectedCollectionId.trim().isEmpty) {
      await preferences.remove(_selectedCollectionIdStorageKey);
      return;
    }

    await preferences.setString(
      _selectedCollectionIdStorageKey,
      selectedCollectionId,
    );
  }

  Map<String, Object?> _collectionToJson(
    ImportedCollectionEntity collection,
  ) => {
    'id': collection.id,
    'name': collection.name,
    'description': collection.description,
    'importType': collection.importType.name,
    'authLabel': collection.authLabel,
    'variables': collection.variables
        .map(_variableToJson)
        .toList(growable: false),
    'folders': collection.folders.map(_folderToJson).toList(growable: false),
    'rootRequests': collection.rootRequests
        .map(_requestToJson)
        .toList(growable: false),
  };

  Map<String, Object?> _variableToJson(
    ImportedCollectionVariableEntity variable,
  ) => {
    'name': variable.name,
    'value': variable.value,
    'isEnabled': variable.isEnabled,
  };

  Map<String, Object?> _folderToJson(ImportedCollectionFolderEntity folder) => {
    'name': folder.name,
    'folders': folder.folders.map(_folderToJson).toList(growable: false),
    'requests': folder.requests.map(_requestToJson).toList(growable: false),
  };

  Map<String, Object?> _requestToJson(
    ImportedCollectionRequestEntity request,
  ) => {
    'method': request.method,
    'title': request.title,
    'url': request.url,
    'baseUrlValue': request.baseUrlValue,
    'queryParameters': request.queryParameters
        .map(_fieldToJson)
        .toList(growable: false),
    'headers': request.headers.map(_fieldToJson).toList(growable: false),
    'bodyContent': request.bodyContent,
    'bodyContentType': request.bodyContentType,
  };

  Map<String, Object?> _fieldToJson(ImportedRequestFieldEntity field) => {
    'name': field.name,
    'value': field.value,
    'description': field.description,
  };

  List<ImportedCollectionEntity> _collectionListFromJson(Object? value) {
    if (value is! List) {
      return const <ImportedCollectionEntity>[];
    }

    return value
        .whereType<Map>()
        .map((item) => _collectionFromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  ImportedCollectionEntity _collectionFromJson(Map<String, dynamic> json) {
    return ImportedCollectionEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Imported Collection',
      description: json['description'] as String? ?? '',
      importType: _importTypeFromName(json['importType'] as String?),
      authLabel: json['authLabel'] as String? ?? 'No Auth',
      variables: _listFromJson(
        json['variables'],
        (item) => _variableFromJson(item),
      ),
      folders: _listFromJson(json['folders'], (item) => _folderFromJson(item)),
      rootRequests: _listFromJson(
        json['rootRequests'],
        (item) => _requestFromJson(item),
      ),
    );
  }

  ImportedCollectionVariableEntity _variableFromJson(
    Map<String, dynamic> json,
  ) {
    return ImportedCollectionVariableEntity(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  ImportedCollectionFolderEntity _folderFromJson(Map<String, dynamic> json) {
    return ImportedCollectionFolderEntity(
      name: json['name'] as String? ?? '',
      folders: _listFromJson(json['folders'], (item) => _folderFromJson(item)),
      requests: _listFromJson(
        json['requests'],
        (item) => _requestFromJson(item),
      ),
    );
  }

  ImportedCollectionRequestEntity _requestFromJson(Map<String, dynamic> json) {
    return ImportedCollectionRequestEntity(
      method: json['method'] as String? ?? 'GET',
      title: json['title'] as String? ?? 'Imported Request',
      url: json['url'] as String? ?? '',
      baseUrlValue: json['baseUrlValue'] as String? ?? '',
      queryParameters: _listFromJson(
        json['queryParameters'],
        (item) => _fieldFromJson(item),
      ),
      headers: _listFromJson(json['headers'], (item) => _fieldFromJson(item)),
      bodyContent: json['bodyContent'] as String? ?? '',
      bodyContentType: json['bodyContentType'] as String? ?? '',
    );
  }

  ImportedRequestFieldEntity _fieldFromJson(Map<String, dynamic> json) {
    return ImportedRequestFieldEntity(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  CollectionImportType _importTypeFromName(String? name) {
    for (final value in CollectionImportType.values) {
      if (value.name == name) {
        return value;
      }
    }

    return CollectionImportType.openApiSpec;
  }

  List<T> _listFromJson<T>(
    Object? value,
    T Function(Map<String, dynamic> json) builder,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map((item) => builder(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
