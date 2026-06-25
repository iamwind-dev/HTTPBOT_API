import 'package:equatable/equatable.dart';

import '../../domain/entities/response_filter_entity.dart';

enum ResponseFiltersStatus { loading, ready }

class ResponseFiltersState extends Equatable {
  const ResponseFiltersState({
    this.status = ResponseFiltersStatus.loading,
    this.filters = const <ResponseFilterEntity>[],
  });

  final ResponseFiltersStatus status;
  final List<ResponseFilterEntity> filters;

  ResponseFiltersState copyWith({
    ResponseFiltersStatus? status,
    List<ResponseFilterEntity>? filters,
  }) => ResponseFiltersState(
    status: status ?? this.status,
    filters: filters ?? this.filters,
  );

  @override
  List<Object?> get props => [status, filters];
}
