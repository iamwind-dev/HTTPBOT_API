import '../helpers/request_har_export_payload.dart';

/// Abstracts user-initiated file selection and HAR sharing for request transfer.
abstract interface class RequestTransferGateway {
  /// Lets the user select one HAR file and returns a non-sensitive outcome.
  Future<HarSelectionResult> selectHar();

  /// Shares one in-memory HAR payload without retaining an export copy.
  Future<HarShareResult> shareHar(RequestHarExportPayload payload);
}

/// Describes a HAR file selection outcome without exposing platform details.
sealed class HarSelectionResult {
  const HarSelectionResult();
}

/// Indicates that the picker was dismissed without selecting a file.
final class HarSelectionCancelled extends HarSelectionResult {
  const HarSelectionCancelled();
}

/// Carries the selected HAR text only for the active import flow.
final class HarSelectionSuccess extends HarSelectionResult {
  const HarSelectionSuccess(this.content);

  final String content;
}

/// Reports a file-selection failure with a generic presentation-safe message.
final class HarSelectionFailure extends HarSelectionResult {
  const HarSelectionFailure();
}

/// Describes a HAR share/save outcome without retaining the payload.
sealed class HarShareResult {
  const HarShareResult();
}

/// Indicates that the user completed or platform accepted the share action.
final class HarShareSuccess extends HarShareResult {
  const HarShareSuccess();
}

/// Indicates that the user dismissed the share surface.
final class HarShareCancelled extends HarShareResult {
  const HarShareCancelled();
}

/// Reports a platform share failure without exposing request content.
final class HarShareFailure extends HarShareResult {
  const HarShareFailure();
}
