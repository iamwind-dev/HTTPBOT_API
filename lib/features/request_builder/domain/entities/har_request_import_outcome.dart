import 'saved_request_draft.dart';

/// Represents the safe result of decoding one user-selected HAR document.
sealed class HarRequestImportOutcome {
  const HarRequestImportOutcome();
}

/// Carries valid requests in source order and the number of skipped entries.
final class HarRequestImportSuccess extends HarRequestImportOutcome {
  const HarRequestImportSuccess({
    required this.requests,
    required this.skippedCount,
  });

  final List<SavedRequestDraft> requests;
  final int skippedCount;
}

/// Indicates an invalid or unsupported HAR document without exposing its content.
final class HarRequestImportFailure extends HarRequestImportOutcome {
  const HarRequestImportFailure();
}
