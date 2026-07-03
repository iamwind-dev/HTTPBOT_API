import 'package:equatable/equatable.dart';

import '../../domain/entities/imported_collection_entity.dart';

class CollectionState extends Equatable {
  const CollectionState({
    this.items = const [],
    this.isImporting = false,
    this.selectedCollectionId,
    this.validationMessage,
    this.searchQuery = '',
  });

  final List<ImportedCollectionEntity> items;
  final bool isImporting;
  final String? selectedCollectionId;
  final String? validationMessage;
  final String searchQuery;

  ImportedCollectionEntity? get selectedCollection {
    final id = selectedCollectionId;
    if (id == null) {
      return null;
    }

    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  CollectionState copyWith({
    List<ImportedCollectionEntity>? items,
    bool? isImporting,
    String? selectedCollectionId,
    String? validationMessage,
    String? searchQuery,
    bool clearValidationMessage = false,
    bool clearSelectedCollection = false,
  }) => CollectionState(
    items: items ?? this.items,
    isImporting: isImporting ?? this.isImporting,
    selectedCollectionId: clearSelectedCollection
        ? null
        : (selectedCollectionId ?? this.selectedCollectionId),
    validationMessage: clearValidationMessage
        ? null
        : (validationMessage ?? this.validationMessage),
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [
    items,
    isImporting,
    selectedCollectionId,
    validationMessage,
    searchQuery,
  ];
}
