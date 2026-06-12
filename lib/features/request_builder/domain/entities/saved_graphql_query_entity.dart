import 'package:equatable/equatable.dart';

class SavedGraphQlQueryEntity extends Equatable {
  const SavedGraphQlQueryEntity({
    required this.id,
    required this.name,
    required this.query,
    this.filterType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String query;
  final String? filterType;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedGraphQlQueryEntity copyWith({
    String? id,
    String? name,
    String? query,
    String? filterType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearFilterType = false,
  }) => SavedGraphQlQueryEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    query: query ?? this.query,
    filterType: clearFilterType ? null : filterType ?? this.filterType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    query,
    filterType,
    createdAt,
    updatedAt,
  ];
}
