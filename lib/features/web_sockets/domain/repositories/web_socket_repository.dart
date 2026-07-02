import '../../domain/entities/web_socket_request_entity.dart';

abstract class WebSocketRepository {
  /// Loads all saved WebSocket requests from the local storage.
  Future<List<WebSocketRequestEntity>> getRequests();

  /// Persists a new WebSocket request.
  Future<WebSocketRequestEntity> createRequest(WebSocketRequestEntity request);

  /// Updates an existing WebSocket request.
  Future<WebSocketRequestEntity> updateRequest(WebSocketRequestEntity request);

  /// Deletes a WebSocket request by its unique identifier.
  Future<void> deleteRequest(String id);
}
