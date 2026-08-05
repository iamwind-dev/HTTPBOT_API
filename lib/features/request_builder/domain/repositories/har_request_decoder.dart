import '../entities/har_request_import_outcome.dart';

/// Defines the domain boundary for converting HAR text into saved requests.
abstract interface class HarRequestDecoder {
  /// Decodes a selected HAR document into a presentation-safe import outcome.
  HarRequestImportOutcome decode(String content);
}
