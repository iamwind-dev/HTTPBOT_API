import 'package:equatable/equatable.dart';

import '../../domain/entities/response_filter.dart';

enum ManageResponseFiltersStatus { initial, loading, ready, saving, failure }

class ManageResponseFiltersState extends Equatable {
  const ManageResponseFiltersState({
    this.status = ManageResponseFiltersStatus.initial,
    this.filters = const <ResponseFilter>[],
    this.errorMessage = '',
  });

  final ManageResponseFiltersStatus status;
  final List<ResponseFilter> filters;
  final String errorMessage;

  ManageResponseFiltersState copyWith({
    ManageResponseFiltersStatus? status,
    List<ResponseFilter>? filters,
    String? errorMessage,
  }) => ManageResponseFiltersState(
    status: status ?? this.status,
    filters: filters ?? this.filters,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object> get props => [status, filters, errorMessage];
}
