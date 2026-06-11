import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/collection_file_importer.dart';
import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/imported_collection_entity.dart';
import '../../domain/entities/openapi_directory_entry.dart';
import 'collection_state.dart';

class CollectionCubit extends Cubit<CollectionState> {
  CollectionCubit({CollectionFileImporter? importer})
    : _importer = importer ?? CollectionFileImporter(),
      super(const CollectionState());

  final CollectionFileImporter _importer;

  Future<ImportedCollectionEntity?> importFile(
    CollectionImportType type,
  ) async {
    if (state.isImporting) {
      return null;
    }

    emit(state.copyWith(isImporting: true));

    try {
      final imported = await _importer.pickAndImport(type);
      if (imported == null) {
        emit(state.copyWith(isImporting: false));
        return null;
      }

      emit(
        state.copyWith(
          isImporting: false,
          items: [imported, ...state.items],
          selectedCollectionId: imported.id,
        ),
      );
      return imported;
    } catch (_) {
      emit(state.copyWith(isImporting: false));
      rethrow;
    }
  }

  Future<ImportedCollectionEntity?> importFromUrl(
    String url, {
    String? fallbackName,
  }) async {
    if (state.isImporting) {
      return null;
    }

    emit(state.copyWith(isImporting: true));

    try {
      final imported = await _importer.importOpenApiSpecUrl(
        url,
        fallbackName: fallbackName,
      );
      emit(
        state.copyWith(
          isImporting: false,
          items: [imported, ...state.items],
          selectedCollectionId: imported.id,
        ),
      );
      return imported;
    } catch (_) {
      emit(state.copyWith(isImporting: false));
      rethrow;
    }
  }

  Future<List<OpenApiDirectoryEntry>> loadDirectoryEntries() {
    return _importer.fetchOpenApiDirectoryEntries();
  }

  void selectCollection(String collectionId) {
    if (collectionId == state.selectedCollectionId) {
      return;
    }

    emit(state.copyWith(selectedCollectionId: collectionId));
  }

  void clearSelectedCollection() {
    emit(state.copyWith(clearSelectedCollection: true));
  }
}
