import 'package:equatable/equatable.dart';

class SavedGraphQlVariableEntity extends Equatable {
  const SavedGraphQlVariableEntity({
    required this.id,
    required this.name,
    required this.variables,
    this.filterType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String variables;
  final String? filterType;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedGraphQlVariableEntity copyWith({
    String? id,
    String? name,
    String? variables,
    String? filterType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearFilterType = false,
  }) => SavedGraphQlVariableEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    variables: variables ?? this.variables,
    filterType: clearFilterType ? null : filterType ?? this.filterType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    variables,
    filterType,
    createdAt,
    updatedAt,
  ];
}
