import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/collection_file_importer.dart';
import '../../data/services/collection_local_store.dart';
import '../../domain/entities/collection_import_type.dart';
import '../../domain/entities/imported_collection_entity.dart';
import '../../domain/entities/openapi_directory_entry.dart';
import 'collection_state.dart';

class CollectionCubit extends Cubit<CollectionState> {
  CollectionCubit({
    CollectionFileImporter? importer,
    CollectionLocalStore? localStore,
  }) : _importer = importer ?? CollectionFileImporter(),
       _localStore = localStore ?? CollectionLocalStore(),
       super(const CollectionState());

  final CollectionFileImporter _importer;
  final CollectionLocalStore _localStore;

  Future<void> load() async {
    final snapshot = await _localStore.load();
    emit(
      state.copyWith(
        items: snapshot.items,
        selectedCollectionId: snapshot.selectedCollectionId,
      ),
    );
  }

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
      await _persistState();
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
      await _persistState();
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
    _persistState();
  }

  void clearSelectedCollection() {
    emit(state.copyWith(clearSelectedCollection: true));
    _persistState();
  }

  void updateCollection(ImportedCollectionEntity updatedCollection) {
    final updatedItems = state.items
        .map(
          (item) => item.id == updatedCollection.id ? updatedCollection : item,
        )
        .toList(growable: false);

    emit(state.copyWith(items: updatedItems));
    _persistState();
  }

  void deleteCollection(String collectionId) {
    final updatedItems = state.items
        .where((item) => item.id != collectionId)
        .toList(growable: false);

    emit(
      state.copyWith(
        items: updatedItems,
        clearSelectedCollection: state.selectedCollectionId == collectionId,
      ),
    );
    _persistState();
  }

  Future<void> _persistState() {
    return _localStore.save(
      items: state.items,
      selectedCollectionId: state.selectedCollectionId,
    );
  }
}
