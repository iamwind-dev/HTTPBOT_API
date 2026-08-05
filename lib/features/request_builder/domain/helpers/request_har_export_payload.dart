import '../entities/request_draft.dart';
import 'har_request_codec.dart';

/// Contains the in-memory HAR document and a safe filename for platform export.
class RequestHarExportPayload {
  const RequestHarExportPayload({
    required this.fileName,
    required this.content,
  });

  final String fileName;
  final String content;

  /// Builds one HAR request-entry payload without persisting the source draft.
  factory RequestHarExportPayload.fromDraft({
    required String title,
    required RequestDraft draft,
  }) {
    final normalizedTitle = title.trim().isEmpty ? 'request' : title.trim();
    return RequestHarExportPayload(
      fileName: '${_safeFileName(normalizedTitle)}.har',
      content: const HarRequestCodec().encode(
        title: normalizedTitle,
        draft: draft,
      ),
    );
  }

  /// Converts a title to a portable filename segment.
  static String _safeFileName(String title) {
    final normalized = title
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'request' : normalized;
  }
}
