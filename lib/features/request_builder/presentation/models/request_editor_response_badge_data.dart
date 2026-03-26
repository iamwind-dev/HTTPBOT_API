import 'package:equatable/equatable.dart';

class RequestEditorResponseBadgeData extends Equatable {
  const RequestEditorResponseBadgeData({
    required this.statusCode,
    required this.payloadSizeBytes,
    required this.durationMs,
  });

  final int? statusCode;
  final int? payloadSizeBytes;
  final int? durationMs;

  /// Provides demo badge data until the editor is connected to real responses.
  const RequestEditorResponseBadgeData.demo()
    : statusCode = 200,
      payloadSizeBytes = 3072,
      durationMs = 279;

  /// Formats the response status code for compact badge display.
  String get statusLabel => statusCode?.toString() ?? '--';

  /// Formats payload size using compact kilobyte output when appropriate.
  String get sizeLabel {
    final size = payloadSizeBytes;

    if (size == null) {
      return '--';
    }

    if (size >= 1024) {
      final kiloBytes = size / 1024;
      final rounded = kiloBytes == kiloBytes.roundToDouble()
          ? kiloBytes.round().toString()
          : kiloBytes.toStringAsFixed(1);

      return '${rounded}KB';
    }

    return '${size}B';
  }

  /// Formats duration as milliseconds for the badge footer.
  String get durationLabel => durationMs == null ? '--' : '${durationMs}ms';

  /// Combines all formatted badge segments into the footer display string.
  String get displayLabel => '$statusLabel | $sizeLabel | $durationLabel';

  @override
  List<Object?> get props => [statusCode, payloadSizeBytes, durationMs];
}
