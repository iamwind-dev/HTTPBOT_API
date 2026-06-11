import 'collection_import_type.dart';

class ImportedCollectionRequestEntity {
  const ImportedCollectionRequestEntity({
    required this.method,
    required this.title,
    required this.url,
  });

  final String method;
  final String title;
  final String url;
}

class ImportedCollectionFolderEntity {
  const ImportedCollectionFolderEntity({
    required this.name,
    required this.requests,
  });

  final String name;
  final List<ImportedCollectionRequestEntity> requests;
}

class ImportedCollectionEntity {
  const ImportedCollectionEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.importType,
    this.folders = const [],
    this.rootRequests = const [],
  });

  final String id;
  final String name;
  final String description;
  final CollectionImportType importType;
  final List<ImportedCollectionFolderEntity> folders;
  final List<ImportedCollectionRequestEntity> rootRequests;

  int get itemCount {
    if (folders.isNotEmpty) {
      return folders.length;
    }

    return rootRequests.length;
  }

  int get requestCount {
    final folderRequests = folders.fold<int>(
      0,
      (sum, folder) => sum + folder.requests.length,
    );

    return folderRequests + rootRequests.length;
  }
}
