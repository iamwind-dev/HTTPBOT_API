import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';
import '../models/request_list_item.dart';

enum RequestBuilderStatus { initial, ready }

class RequestBuilderState extends Equatable {
  const RequestBuilderState({
    required this.status,
    required this.requests,
    required this.searchQuery,
    required this.initialDraft,
  });

  const RequestBuilderState.initial()
    : status = RequestBuilderStatus.initial,
      requests = const <RequestListItem>[],
      searchQuery = '',
      initialDraft = null;

  final RequestBuilderStatus status;
  final List<RequestListItem> requests;
  final String searchQuery;
  final RequestDraft? initialDraft;

  /// Returns the request list filtered by the active search query.
  List<RequestListItem> get visibleRequests => requests
      .where((request) => request.matches(searchQuery))
      .toList(growable: false);

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;
  bool get hasRequests => requests.isNotEmpty;
  bool get isEmptyState => !hasRequests;
  bool get isNoResultsState => hasRequests && visibleRequests.isEmpty;

  /// Creates a new immutable state with any updated request list values.
  RequestBuilderState copyWith({
    RequestBuilderStatus? status,
    List<RequestListItem>? requests,
    String? searchQuery,
    RequestDraft? initialDraft,
  }) => RequestBuilderState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    searchQuery: searchQuery ?? this.searchQuery,
    initialDraft: initialDraft ?? this.initialDraft,
  );

  @override
  List<Object?> get props => [status, requests, searchQuery, initialDraft];
}
