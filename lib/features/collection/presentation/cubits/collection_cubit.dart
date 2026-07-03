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
        clearValidationMessage: true,
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
          clearValidationMessage: true,
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
          clearValidationMessage: true,
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

    emit(
      state.copyWith(
        selectedCollectionId: collectionId,
        clearValidationMessage: true,
      ),
    );
    _persistState();
  }

  void clearSelectedCollection() {
    emit(
      state.copyWith(
        clearSelectedCollection: true,
        clearValidationMessage: true,
      ),
    );
    _persistState();
  }

  void updateSearchQuery(String value) {
    emit(
      state.copyWith(
        searchQuery: value,
      ),
    );
  }

  void updateCollection(ImportedCollectionEntity updatedCollection) {
    final updatedItems = state.items
        .map(
          (item) => item.id == updatedCollection.id
              ? updatedCollection.copyWith(updatedAt: DateTime.now())
              : item,
        )
        .toList(growable: false);

    emit(state.copyWith(items: updatedItems, clearValidationMessage: true));
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
        clearValidationMessage: true,
      ),
    );
    _persistState();
  }

  bool createCollection(ImportedCollectionEntity draft) {
    final trimmedName = draft.name.trim();
    if (trimmedName.isEmpty) {
      emit(
        state.copyWith(
          validationMessage: 'Collection name is required.',
        ),
      );
      return false;
    }

    final now = DateTime.now();
    final collection = draft.copyWith(
      name: trimmedName,
      updatedAt: now,
      createdAt: draft.createdAt ?? now,
    );

    emit(
      state.copyWith(
        items: [collection, ...state.items],
        selectedCollectionId: collection.id,
        clearValidationMessage: true,
      ),
    );
    _persistState();
    return true;
  }

  bool createFolder({
    required String collectionId,
    required String name,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      emit(
        state.copyWith(
          validationMessage: 'Folder name is required.',
        ),
      );
      return false;
    }

    ImportedCollectionEntity? collection;
    for (final item in state.items) {
      if (item.id == collectionId) {
        collection = item;
        break;
      }
    }
    if (collection == null) {
      emit(
        state.copyWith(
          validationMessage: 'Collection not found.',
        ),
      );
      return false;
    }

    updateCollection(
      collection.copyWith(
        folders: [
          ...collection.folders,
          ImportedCollectionFolderEntity(name: trimmedName),
        ],
      ),
    );
    return true;
  }

  Future<void> _persistState() {
    return _localStore.save(
      items: state.items,
      selectedCollectionId: state.selectedCollectionId,
    );
  }
}
