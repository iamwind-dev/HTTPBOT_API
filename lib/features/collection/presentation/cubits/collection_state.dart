import 'package:equatable/equatable.dart';

import '../../domain/entities/imported_collection_entity.dart';

class CollectionState extends Equatable {
  const CollectionState({
    this.items = const [],
    this.isImporting = false,
    this.selectedCollectionId,
  });

  final List<ImportedCollectionEntity> items;
  final bool isImporting;
  final String? selectedCollectionId;

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
    bool clearSelectedCollection = false,
  }) => CollectionState(
    items: items ?? this.items,
    isImporting: isImporting ?? this.isImporting,
    selectedCollectionId: clearSelectedCollection
        ? null
        : (selectedCollectionId ?? this.selectedCollectionId),
  );

  @override
  List<Object?> get props => [items, isImporting, selectedCollectionId];
}
