import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/web_socket_request_entity.dart';
import '../../domain/repositories/web_socket_repository.dart';

class WebSocketListState extends Equatable {
  const WebSocketListState({
    this.requests = const <WebSocketRequestEntity>[],
    this.searchQuery = '',
  });

  final List<WebSocketRequestEntity> requests;
  final String searchQuery;

  /// Returns the requests filtered by the search query.
  List<WebSocketRequestEntity> get filteredRequests {
    if (searchQuery.trim().isEmpty) {
      return requests;
    }
    final query = searchQuery.toLowerCase();
    return requests
        .where((r) =>
            r.name.toLowerCase().contains(query) ||
            r.url.toLowerCase().contains(query))
        .toList(growable: false);
  }

  bool get isEmptyState => requests.isEmpty;
  bool get isNoResultsState => requests.isNotEmpty && filteredRequests.isEmpty;

  WebSocketListState copyWith({
    List<WebSocketRequestEntity>? requests,
    String? searchQuery,
  }) =>
      WebSocketListState(
        requests: requests ?? this.requests,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props => [requests, searchQuery];
}

class WebSocketListCubit extends Cubit<WebSocketListState> {
  WebSocketListCubit(this._repository) : super(const WebSocketListState());

  final WebSocketRepository _repository;

  /// Loads all persisted WebSocket requests.
  Future<void> load() async {
    final requests = await _repository.getRequests();
    emit(state.copyWith(requests: requests));
  }

  /// Creates a new default WebSocket request and persists it.
  Future<WebSocketRequestEntity> createRequest() async {
    final newRequest = WebSocketRequestEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: 'Untitled Request',
      url: 'wss://',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final saved = await _repository.createRequest(newRequest);
    await load();
    return saved;
  }

  /// Updates a WebSocket request.
  Future<void> updateRequest(WebSocketRequestEntity request) async {
    await _repository.updateRequest(request.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  /// Deletes a WebSocket request.
  Future<void> deleteRequest(String id) async {
    await _repository.deleteRequest(id);
    await load();
  }

  /// Updates the search query filter.
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
