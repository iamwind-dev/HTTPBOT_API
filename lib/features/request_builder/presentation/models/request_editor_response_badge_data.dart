import 'package:equatable/equatable.dart';

import '../../domain/entities/request_execution_result.dart';

class RequestEditorResponseBadgeData extends Equatable {
  const RequestEditorResponseBadgeData({
    required this.statusCode,
    required this.payloadSizeBytes,
    required this.durationMs,
  });

  final int? statusCode;
  final int? payloadSizeBytes;
  final int? durationMs;

  /// Creates compact badge data from a real request execution result.
  factory RequestEditorResponseBadgeData.fromExecutionResult(
    RequestExecutionResult executionResult,
  ) => RequestEditorResponseBadgeData(
    statusCode: executionResult.statusCode,
    payloadSizeBytes: executionResult.payloadSizeBytes,
    durationMs: executionResult.duration.inMilliseconds,
  );

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
