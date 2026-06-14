import '../../domain/entities/saved_graphql_query_entity.dart';

class SavedGraphQlQueryModel {
  const SavedGraphQlQueryModel({
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

  factory SavedGraphQlQueryModel.fromEntity(SavedGraphQlQueryEntity entity) =>
      SavedGraphQlQueryModel(
        id: entity.id,
        name: entity.name,
        query: entity.query,
        filterType: entity.filterType,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  factory SavedGraphQlQueryModel.fromJson(Map<String, dynamic> json) =>
      SavedGraphQlQueryModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        query: json['query'] as String? ?? '',
        filterType: _normalizeFilterType(json['filterType'] as String?),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  SavedGraphQlQueryEntity toEntity() => SavedGraphQlQueryEntity(
    id: id,
    name: name,
    query: query,
    filterType: filterType,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'query': query,
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
