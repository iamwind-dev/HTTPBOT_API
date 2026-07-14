import '../../domain/entities/response_filter.dart';

class ResponseFilterModel {
  const ResponseFilterModel({
    required this.id,
    required this.name,
    required this.filterType,
    required this.query,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final ResponseFilterType filterType;
  final String query;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ResponseFilterModel.fromEntity(ResponseFilter entity) =>
      ResponseFilterModel(
        id: entity.id,
        name: entity.name,
        filterType: entity.filterType,
        query: entity.query,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );

  factory ResponseFilterModel.fromJson(Map<String, dynamic> json) =>
      ResponseFilterModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        filterType:
            ResponseFilterTypePresentation.fromStorage(
              json['filterType'] as String?,
            ) ??
            ResponseFilterType.jq,
        query: json['query'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  ResponseFilter toEntity() => ResponseFilter(
    id: id,
    name: name,
    filterType: filterType,
    query: query,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'filterType': filterType.label,
    'query': query,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
