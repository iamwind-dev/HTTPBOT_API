import 'package:equatable/equatable.dart';

import '../models/request_list_item.dart';

enum RequestBuilderStatus { initial, ready }

enum RequestBottomTab { requests, websockets, collections, postman, settings }

class RequestBuilderState extends Equatable {
  const RequestBuilderState({
    required this.status,
    required this.requests,
    required this.searchQuery,
    required this.selectedTab,
    required this.placeholderTab,
  });

  const RequestBuilderState.initial()
    : status = RequestBuilderStatus.initial,
      requests = const <RequestListItem>[],
      searchQuery = '',
      selectedTab = RequestBottomTab.requests,
      placeholderTab = null;

  final RequestBuilderStatus status;
  final List<RequestListItem> requests;
  final String searchQuery;
  final RequestBottomTab selectedTab;
  final RequestBottomTab? placeholderTab;

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
    RequestBottomTab? selectedTab,
    RequestBottomTab? placeholderTab,
    bool clearPlaceholderTab = false,
  }) => RequestBuilderState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedTab: selectedTab ?? this.selectedTab,
    placeholderTab: clearPlaceholderTab
        ? null
        : placeholderTab ?? this.placeholderTab,
  );

  @override
  List<Object?> get props => [
    status,
    requests,
    searchQuery,
    selectedTab,
    placeholderTab,
  ];
}
