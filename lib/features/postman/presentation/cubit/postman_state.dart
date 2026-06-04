import '../../domain/entities/postman_collection_entity.dart';
import '../../domain/entities/postman_workspace_entity.dart';

class PostmanState {
  final bool isLoadingCollections;
  final bool isLoadingCollectionDetail;
  final String apiKey;
  final String? errorMessage;
  final List<PostmanWorkspaceEntity> workspaces;
  final String? selectedWorkspaceId;
  final List<PostmanCollectionEntity> collections;
  final String? pickerSelectedCollectionId;
  final PostmanCollectionEntity? selectedCollection;

  const PostmanState({
    this.isLoadingCollections = false,
    this.isLoadingCollectionDetail = false,
    this.apiKey = '',
    this.errorMessage,
    this.workspaces = const [],
    this.selectedWorkspaceId,
    this.collections = const [],
    this.pickerSelectedCollectionId,
    this.selectedCollection,
  });

  bool get hasLinkedApi => apiKey.isNotEmpty;
  bool get hasCollections => collections.isNotEmpty;
  bool get hasWorkspaces => workspaces.isNotEmpty;
  bool get canImportSelectedCollection => pickerSelectedCollectionId != null;

  PostmanWorkspaceEntity? get selectedWorkspace {
    final workspaceId = selectedWorkspaceId;
    if (workspaceId == null) {
      return null;
    }

    for (final workspace in workspaces) {
      if (workspace.id == workspaceId) {
        return workspace;
      }
    }

    return null;
  }

  List<PostmanCollectionEntity> get selectedWorkspaceCollections {
    return selectedWorkspace?.collections ?? const [];
  }

  PostmanCollectionEntity? get pickerSelectedCollection {
    final collectionId = pickerSelectedCollectionId;
    if (collectionId == null) {
      return null;
    }

    for (final collection in selectedWorkspaceCollections) {
      if (collection.id == collectionId) {
        return collection;
      }
    }

    return null;
  }

  PostmanState copyWith({
    bool? isLoadingCollections,
    bool? isLoadingCollectionDetail,
    String? apiKey,
    String? errorMessage,
    List<PostmanWorkspaceEntity>? workspaces,
    String? selectedWorkspaceId,
    List<PostmanCollectionEntity>? collections,
    String? pickerSelectedCollectionId,
    PostmanCollectionEntity? selectedCollection,
    bool clearErrorMessage = false,
    bool clearSelectedWorkspace = false,
    bool clearPickerSelection = false,
    bool clearSelectedCollection = false,
  }) {
    return PostmanState(
      isLoadingCollections:
          isLoadingCollections ?? this.isLoadingCollections,
      isLoadingCollectionDetail:
          isLoadingCollectionDetail ?? this.isLoadingCollectionDetail,
      apiKey: apiKey ?? this.apiKey,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspaceId: clearSelectedWorkspace
          ? null
          : (selectedWorkspaceId ?? this.selectedWorkspaceId),
      collections: collections ?? this.collections,
      pickerSelectedCollectionId: clearPickerSelection
          ? null
          : (pickerSelectedCollectionId ?? this.pickerSelectedCollectionId),
      selectedCollection: clearSelectedCollection
          ? null
          : (selectedCollection ?? this.selectedCollection),
    );
  }
}
