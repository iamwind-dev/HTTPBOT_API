import '../../domain/entities/saved_graphql_variable_entity.dart';

class SavedGraphQlVariableModel {
  const SavedGraphQlVariableModel({
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

  factory SavedGraphQlVariableModel.fromEntity(
    SavedGraphQlVariableEntity entity,
  ) => SavedGraphQlVariableModel(
    id: entity.id,
    name: entity.name,
    variables: entity.variables,
    filterType: entity.filterType,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );

  factory SavedGraphQlVariableModel.fromJson(Map<String, dynamic> json) =>
      SavedGraphQlVariableModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        variables: json['variables'] as String? ?? '',
        filterType: _normalizeFilterType(json['filterType'] as String?),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  SavedGraphQlVariableEntity toEntity() => SavedGraphQlVariableEntity(
    id: id,
    name: name,
    variables: variables,
    filterType: filterType,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'variables': variables,
    'filterType': filterType,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static const _allowedFilterTypes = <String>{'jq', 'JSONPath', 'XPath'};

  static String? _normalizeFilterType(String? value) {
    final trimmed = value?.trim() ?? '';
    if (!_allowedFilterTypes.contains(trimmed)) {
      return null;
    }

    return trimmed;
  }
}
