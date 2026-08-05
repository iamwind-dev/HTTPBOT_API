import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_variable_store.dart';
import '../../domain/entities/saved_request_draft.dart';
import '../models/request_list_item.dart';

enum RequestBuilderStatus { initial, ready }

class RequestBuilderState extends Equatable {
  const RequestBuilderState({
    required this.status,
    required this.requests,
    required this.searchQuery,
    required this.initialDraft,
    required this.initialVariableStore,
    required this.savedRequests,
    this.showFavouritesOnly = false,
  });

  const RequestBuilderState.initial()
    : status = RequestBuilderStatus.initial,
      requests = const <RequestListItem>[],
      searchQuery = '',
      initialDraft = null,
      initialVariableStore = null,
      savedRequests = const <SavedRequestDraft>[],
      showFavouritesOnly = false;

  final RequestBuilderStatus status;
  final List<RequestListItem> requests;
  final String searchQuery;
  final RequestDraft? initialDraft;
  final RequestVariableStore? initialVariableStore;
  final List<SavedRequestDraft> savedRequests;
  final bool showFavouritesOnly;

  /// Returns requests that match both the active text and favourite filters.
  List<RequestListItem> get visibleRequests =>
      requests.where(matches).toList(growable: false);

  /// Reports whether an item is permitted by the active Requests filters.
  bool matches(RequestListItem request) =>
      (!showFavouritesOnly || request.isFavourite) &&
      request.matches(searchQuery);

  bool get hasSearchQuery => searchQuery.trim().isNotEmpty;
  bool get hasRequests => requests.isNotEmpty;
  bool get isEmptyState => !hasRequests;
  bool get isFavouritesEmptyState =>
      hasRequests &&
      showFavouritesOnly &&
      !hasSearchQuery &&
      visibleRequests.isEmpty;
  bool get isNoResultsState => hasRequests && visibleRequests.isEmpty;

  /// Creates a new immutable state with any updated request list values.
  RequestBuilderState copyWith({
    RequestBuilderStatus? status,
    List<RequestListItem>? requests,
    String? searchQuery,
    RequestDraft? initialDraft,
    RequestVariableStore? initialVariableStore,
    List<SavedRequestDraft>? savedRequests,
    bool? showFavouritesOnly,
  }) => RequestBuilderState(
    status: status ?? this.status,
    requests: requests ?? this.requests,
    searchQuery: searchQuery ?? this.searchQuery,
    initialDraft: initialDraft ?? this.initialDraft,
    initialVariableStore: initialVariableStore ?? this.initialVariableStore,
    savedRequests: savedRequests ?? this.savedRequests,
    showFavouritesOnly: showFavouritesOnly ?? this.showFavouritesOnly,
  );

  @override
  List<Object?> get props => [
    status,
    requests,
    searchQuery,
    initialDraft,
    initialVariableStore,
    savedRequests,
    showFavouritesOnly,
  ];
}
