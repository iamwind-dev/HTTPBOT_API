import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';
import '../../domain/usecases/get_postman_authenticated_user_usecase.dart';
import '../../domain/usecases/get_postman_collection_detail_usecase.dart';
import '../../domain/usecases/get_postman_collections_usecase.dart';
import '../../domain/usecases/get_postman_workspace_detail_usecase.dart';
import '../../domain/usecases/get_postman_workspaces_usecase.dart';
import '../../domain/usecases/save_postman_account_usecase.dart';
import '../../domain/usecases/save_postman_api_key_usecase.dart';
import 'postman_state.dart';

class PostmanCubit extends Cubit<PostmanState> {
  final GetPostmanWorkspacesUseCase getPostmanWorkspacesUseCase;
  final GetPostmanWorkspaceDetailUseCase getPostmanWorkspaceDetailUseCase;
  final GetPostmanCollectionsUseCase getPostmanCollectionsUseCase;
  final GetPostmanCollectionDetailUseCase getPostmanCollectionDetailUseCase;
  final GetPostmanAuthenticatedUserUseCase getPostmanAuthenticatedUserUseCase;
  final SavePostmanAccountUseCase savePostmanAccountUseCase;
  final SavePostmanApiKeyUseCase savePostmanApiKeyUseCase;

  PostmanCubit({
    required this.getPostmanWorkspacesUseCase,
    required this.getPostmanWorkspaceDetailUseCase,
    required this.getPostmanCollectionsUseCase,
    required this.getPostmanCollectionDetailUseCase,
    required this.getPostmanAuthenticatedUserUseCase,
    required this.savePostmanAccountUseCase,
    required this.savePostmanApiKeyUseCase,
  }) : super(const PostmanState());

  Future<bool> linkPostman({
    required String apiKey,
  }) async {
    emit(
      state.copyWith(
        isLoadingCollections: true,
        apiKey: apiKey,
        clearErrorMessage: true,
        workspaces: [],
        clearSelectedWorkspace: true,
        clearPickerSelection: true,
        clearSelectedCollection: true,
        collections: [],
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
          workspaces: workspacesWithCollections,
          selectedWorkspaceId: initialWorkspaceId,
        ),
      );

      await savePostmanAccountUseCase(account);
      await savePostmanApiKeyUseCase(apiKey);

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

      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          selectedCollection: result,
        ),
      );
    } catch (e) {
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

      emit(
        state.copyWith(
          isLoadingCollectionDetail: false,
          collections: _upsertImportedCollection(result),
          selectedCollection: result,
          clearPickerSelection: true,
        ),
      );

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
    final nextCollections = List<PostmanCollectionEntity>.from(
      state.collections,
    );

    final existingIndex = nextCollections.indexWhere(
      (item) => item.id == collection.id,
    );

    if (existingIndex >= 0) {
      nextCollections[existingIndex] = collection;
      return nextCollections;
    }

    return [...nextCollections, collection];
  }
}