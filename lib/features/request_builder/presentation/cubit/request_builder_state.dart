import 'package:equatable/equatable.dart';

import '../models/request_list_item.dart';

enum RequestBuilderStatus { initial, ready }

class RequestBuilderState extends Equatable {
  const RequestBuilderState({
    required this.status,
    required this.requests,
    required this.searchQuery,
  });

  const RequestBuilderState.initial()
    : status = RequestBuilderStatus.initial,
      requests = const <RequestListItem>[],
      searchQuery = '';

  final RequestBuilderStatus status;
  final List<RequestListItem> requests;
  final String searchQuery;

  List<RequestListItem> get visibleRequests => requests
      .where((request) => request.matches(searchQuery))
      .toList(growable: false);

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;
  bool get hasRequests => requests.isNotEmpty;
  bool get isEmptyState => !hasRequests;
  bool get isNoResultsState => hasRequests && visibleRequests.isEmpty;

  RequestBuilderState copyWith({
    RequestBuilderStatus? status,
    List<RequestListItem>? requests,
    String? searchQuery,
  }) => RequestBuilderState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [status, requests, searchQuery];
}
