import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/postman_account_entity.dart';
import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import '../../domain/usecases/load_cached_postman_collections_usecase.dart';
import '../../domain/usecases/load_cached_postman_workspaces_usecase.dart';
import '../../domain/usecases/load_postman_api_key_usecase.dart';
import '../../domain/usecases/get_postman_authenticated_user_usecase.dart';
import '../../domain/usecases/save_cached_postman_collections_usecase.dart';
import '../../domain/usecases/save_cached_postman_workspaces_usecase.dart';
import '../../domain/usecases/save_postman_account_usecase.dart';
import '../../domain/usecases/save_postman_api_key_usecase.dart';
import '../../domain/usecases/get_postman_collection_detail_usecase.dart';
import '../../domain/usecases/get_postman_collections_usecase.dart';
import '../../domain/usecases/get_postman_workspace_detail_usecase.dart';
import '../../domain/usecases/get_postman_workspaces_usecase.dart';
import 'postman_state.dart';

class PostmanCubit extends Cubit<PostmanState> {
  final GetPostmanWorkspacesUseCase getPostmanWorkspacesUseCase;
  final GetPostmanWorkspaceDetailUseCase getPostmanWorkspaceDetailUseCase;
  final GetPostmanCollectionsUseCase getPostmanCollectionsUseCase;
  final GetPostmanCollectionDetailUseCase getPostmanCollectionDetailUseCase;
  final GetPostmanAuthenticatedUserUseCase
  getPostmanAuthenticatedUserUseCase;
  final LoadPostmanApiKeyUseCase loadPostmanApiKeyUseCase;
  final LoadCachedPostmanWorkspacesUseCase loadCachedPostmanWorkspacesUseCase;
  final LoadCachedPostmanCollectionsUseCase
      loadCachedPostmanCollectionsUseCase;
  final SavePostmanAccountUseCase savePostmanAccountUseCase;
  final SavePostmanApiKeyUseCase savePostmanApiKeyUseCase;
  final SaveCachedPostmanWorkspacesUseCase saveCachedPostmanWorkspacesUseCase;
  final SaveCachedPostmanCollectionsUseCase
      saveCachedPostmanCollectionsUseCase;

  PostmanCubit({
    required this.getPostmanWorkspacesUseCase,
    required this.getPostmanWorkspaceDetailUseCase,
    required this.getPostmanCollectionsUseCase,
    required this.getPostmanCollectionDetailUseCase,
    required this.getPostmanAuthenticatedUserUseCase,
    required this.loadPostmanApiKeyUseCase,
    required this.loadCachedPostmanWorkspacesUseCase,
    required this.loadCachedPostmanCollectionsUseCase,
    required this.savePostmanAccountUseCase,
    required this.savePostmanApiKeyUseCase,
    required this.saveCachedPostmanWorkspacesUseCase,
    required this.saveCachedPostmanCollectionsUseCase,
  }) : super(const PostmanState());

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoadingCollections: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final apiKey = await loadPostmanApiKeyUseCase() ?? '';
      final workspaces = await loadCachedPostmanWorkspacesUseCase();
      final collections = await loadCachedPostmanCollectionsUseCase();

      emit(
        state.copyWith(
          isLoadingCollections: false,
          apiKey: apiKey,
          workspaces: workspaces,
          collections: collections,
          selectedWorkspaceId: _resolveInitialWorkspaceId(workspaces),
          clearSelectedCollection: true,
          clearPickerSelection: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingCollections: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<bool> linkPostman({
    required String apiKey,
  }) async {
    final existingCollections = List<PostmanCollectionEntity>.from(
      state.collections,
    );

    emit(
      state.copyWith(
        isLoadingCollections: true,
        apiKey: apiKey,
        clearErrorMessage: true,
        workspaces: [],
        clearSelectedWorkspace: true,
        clearPickerSelection: true,
        clearSelectedCollection: true,
        collections: existingCollections,
      ),
    );

    try {
      final account = await getPostmanAuthenticatedUserUseCase(apiKey: apiKey);
      final workspaces = await getPostmanWorkspacesUseCase(apiKey: apiKey);
      var workspacesWithCollections = await Future.wait(
        workspaces.map((workspace) async {
          try {
            return await getPostmanWorkspaceDetailUseCase(
              apiKey: apiKey,
              workspaceId: workspace.id,
            );
          } catch (_) {
            // Keep workspace visible even if one detail request fails.
            return workspace;
          }
        }),
      );

      if (workspacesWithCollections.isEmpty) {
        final collections = await getPostmanCollectionsUseCase(apiKey: apiKey);
        if (collections.isNotEmpty) {
          workspacesWithCollections = [
            PostmanWorkspaceEntity(
              id: '__all_collections__',
              name: 'All Collections',
              type: 'fallback',
              collections: collections,
            ),
          ];
        }
      }

      final initialWorkspaceId =
          _resolveInitialWorkspaceId(workspacesWithCollections);

      emit(
        state.copyWith(
          isLoadingCollections: false,
          apiKey: apiKey,
          workspaces: workspacesWithCollections,
          collections: existingCollections,
          clearSelectedCollection: true,
          clearPickerSelection: true,
          selectedWorkspaceId: initialWorkspaceId,
        ),
      );
      await _persistLinkedSession(
        apiKey: apiKey,
        account: account,
        workspaces: workspacesWithCollections,
        collections: existingCollections,
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingCollections: false,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> loadCollectionDetail({
    required PostmanCollectionEntity collection,
  }) async {
    final hasCachedDetail =
        collection.folders.isNotEmpty ||
        collection.requests.isNotEmpty ||
        collection.variables.isNotEmpty ||
        collection.description.trim().isNotEmpty;

    if (state.apiKey.trim().isEmpty) {
      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          selectedCollection: collection,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoadingCollectionDetail: true,
        clearErrorMessage: true,
        clearSelectedCollection: true,
      ),
    );

    try {
      final result = await getPostmanCollectionDetailUseCase(
        apiKey: state.apiKey,
        collectionId: collection.id,
      );
      final nextCollections = _upsertImportedCollection(result);

      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          selectedCollection: result,
          collections: nextCollections,
        ),
      );
      await saveCachedPostmanCollectionsUseCase(nextCollections);
    } catch (e) {
      if (hasCachedDetail) {
        emit(
          state.copyWith(
            isLoadingCollectionDetail: false,
            selectedCollection: collection,
            errorMessage: 'Opened cached collection data.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(clearErrorMessage: true));
  }

  void selectWorkspace(String workspaceId) {
    if (workspaceId == state.selectedWorkspaceId) {
      return;
    }

    emit(
      state.copyWith(
        selectedWorkspaceId: workspaceId,
        clearPickerSelection: true,
        clearErrorMessage: true,
      ),
    );
  }

  void selectPickerCollection(String collectionId) {
    if (collectionId == state.pickerSelectedCollectionId) {
      emit(state.copyWith(clearPickerSelection: true));
      return;
    }

    emit(
      state.copyWith(
        pickerSelectedCollectionId: collectionId,
        clearErrorMessage: true,
      ),
    );
  }

  Future<bool> importSelectedCollection() async {
    final pickerCollection = state.pickerSelectedCollection;
    if (pickerCollection == null) {
      return false;
    }

    emit(
      state.copyWith(
        isLoadingCollectionDetail: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await getPostmanCollectionDetailUseCase(
        apiKey: state.apiKey,
        collectionId: pickerCollection.id,
      );
      final nextCollections = _upsertImportedCollection(result);

      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          collections: nextCollections,
          selectedCollection: result,
          clearPickerSelection: true,
        ),
      );
      await saveCachedPostmanCollectionsUseCase(nextCollections);

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  void clearSelectedCollection() {
    emit(state.copyWith(clearSelectedCollection: true));
  }

  Future<void> updateCollection(PostmanCollectionEntity collection) async {
    final nextCollections = _upsertImportedCollection(collection);

    emit(
      state.copyWith(
        collections: nextCollections,
        selectedCollection: state.selectedCollection?.id == collection.id
            ? collection
            : state.selectedCollection,
      ),
    );
    await saveCachedPostmanCollectionsUseCase(nextCollections);
  }

  Future<void> deleteCollection(String collectionId) async {
    final nextCollections = state.collections
        .where((collection) => collection.id != collectionId)
        .toList(growable: false);

    emit(
      state.copyWith(
        collections: nextCollections,
        clearSelectedCollection:
            state.selectedCollection?.id == collectionId,
      ),
    );
    await saveCachedPostmanCollectionsUseCase(nextCollections);
  }

  Future<void> _persistLinkedSession({
    required String apiKey,
    required PostmanAccountEntity account,
    required List<PostmanWorkspaceEntity> workspaces,
    required List<PostmanCollectionEntity> collections,
  }) async {
    await savePostmanAccountUseCase(account);
    await savePostmanApiKeyUseCase(apiKey);
    await saveCachedPostmanWorkspacesUseCase(workspaces);
    await saveCachedPostmanCollectionsUseCase(collections);
  }

  String? _resolveInitialWorkspaceId(List<PostmanWorkspaceEntity> workspaces) {
    if (workspaces.isEmpty) {
      return null;
    }

    for (final workspace in workspaces) {
      if (workspace.name.trim().toLowerCase() == 'my workspace') {
        return workspace.id;
      }
    }

    for (final workspace in workspaces) {
      if (workspace.hasCollections) {
        return workspace.id;
      }
    }

    return workspaces.first.id;
  }

  List<PostmanCollectionEntity> _upsertImportedCollection(
    PostmanCollectionEntity collection,
  ) {
    final nextCollections = List<PostmanCollectionEntity>.from(state.collections);
    final existingIndex =
        nextCollections.indexWhere((item) => item.id == collection.id);

    if (existingIndex >= 0) {
      nextCollections[existingIndex] = collection;
      return nextCollections;
    }

    return [...nextCollections, collection];
  }
}
