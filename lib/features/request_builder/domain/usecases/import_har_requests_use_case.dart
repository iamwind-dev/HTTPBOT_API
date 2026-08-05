import '../entities/har_request_import_outcome.dart';
import '../repositories/har_request_decoder.dart';

/// Decodes one HAR document into the requests that can be persisted by the Cubit.
class ImportHarRequestsUseCase {
  /// Creates the use case with the request-builder HAR decoder contract.
  const ImportHarRequestsUseCase(this._decoder);

  final HarRequestDecoder _decoder;

  /// Returns a safe outcome for the selected HAR content.
  HarRequestImportOutcome call(String content) => _decoder.decode(content);
}
