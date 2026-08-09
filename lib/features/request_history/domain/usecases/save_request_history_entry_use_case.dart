import '../../../request_builder/domain/entities/parsed_response.dart';
import '../../../request_builder/domain/entities/request_execution_result.dart';
import '../entities/request_history_entry.dart';
import '../entities/request_history_response_snapshot.dart';
import '../repositories/request_history_repository.dart';

class SaveRequestHistoryEntryUseCase {
  const SaveRequestHistoryEntryUseCase(this._repository);

  final RequestHistoryRepository _repository;

  /// Stores a completed request execution in history and returns the saved entry snapshot.
  Future<RequestHistoryEntry> call({
    required RequestExecutionResult executionResult,
    required ParsedResponse parsedResponse,
    DateTime? sentAt,
  }) async {
    final timestamp = sentAt ?? DateTime.now();
    final entry = RequestHistoryEntry(
      id: _buildEntryId(timestamp, executionResult),
      sentAt: timestamp,
      request: executionResult.request,
      response: RequestHistoryResponseSnapshot(
        statusCode: executionResult.statusCode,
        statusMessage: executionResult.statusMessage,
        headers: executionResult.headers,
        payloadSizeBytes: executionResult.payloadSizeBytes,
        duration: executionResult.duration,
        errorType: executionResult.errorType,
        errorMessage: executionResult.errorMessage,
        rawBody: executionResult.bodyText,
        formattedBody: parsedResponse.formattedBody,
        contentType: parsedResponse.contentType,
        bodyType: parsedResponse.bodyType,
      ),
      executionResult: executionResult,
      parsedResponse: parsedResponse,
    );

    await _repository.saveRequestHistoryEntry(entry);
    return entry;
  }

  /// Builds a stable-enough in-memory identifier until a persistent data source is added.
  String _buildEntryId(
    DateTime sentAt,
    RequestExecutionResult executionResult,
  ) =>
      '${sentAt.microsecondsSinceEpoch}_${executionResult.request.method.wireName}';
}
