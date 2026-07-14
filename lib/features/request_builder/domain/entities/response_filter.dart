import 'package:equatable/equatable.dart';

enum ResponseFilterType { jq, jsonPath, xPath }

extension ResponseFilterTypePresentation on ResponseFilterType {
  String get label => switch (this) {
    ResponseFilterType.jq => 'jq',
    ResponseFilterType.jsonPath => 'JSONPath',
    ResponseFilterType.xPath => 'XPath',
  };

  static ResponseFilterType? fromStorage(String? value) => switch (value?.trim()) {
    'jq' => ResponseFilterType.jq,
    'JSONPath' => ResponseFilterType.jsonPath,
    'XPath' => ResponseFilterType.xPath,
    _ => null,
  };
}

class ResponseFilter extends Equatable {
  const ResponseFilter({
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

  ResponseFilter copyWith({
    String? id,
    String? name,
    ResponseFilterType? filterType,
    String? query,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ResponseFilter(
    id: id ?? this.id,
    name: name ?? this.name,
    filterType: filterType ?? this.filterType,
    query: query ?? this.query,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object> get props => [id, name, filterType, query, createdAt, updatedAt];
}
