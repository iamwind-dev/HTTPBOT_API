import 'package:equatable/equatable.dart';

import '../helpers/filter_response_mode.dart';

/// A saved Filter Response query the user can reapply across responses.
///
/// Only the query definition is stored — never response data or results.
class ResponseFilterEntity extends Equatable {
  const ResponseFilterEntity({
    required this.id,
    required this.name,
    required this.query,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String query;
  final FilterResponseMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResponseFilterEntity copyWith({
    String? name,
    String? query,
    FilterResponseMode? mode,
    DateTime? updatedAt,
  }) => ResponseFilterEntity(
    id: id,
    name: name ?? this.name,
    query: query ?? this.query,
    mode: mode ?? this.mode,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [id, name, query, mode, createdAt, updatedAt];
}
