import '../entities/request_draft.dart';
import '../helpers/request_har_export_payload.dart';

/// Builds the in-memory HAR payload used by every explicit request export.
class BuildRequestHarExportUseCase {
  /// Creates the use case with the shared request HAR payload builder.
  const BuildRequestHarExportUseCase();

  /// Returns a valid single-entry HAR document for the supplied request draft.
  RequestHarExportPayload call({
    required String title,
    required RequestDraft draft,
  }) => RequestHarExportPayload.fromDraft(title: title, draft: draft);
}
