import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/helpers/request_har_export_payload.dart';
import '../../domain/repositories/request_transfer_gateway.dart';

/// Uses the installed picker and share plugins for explicit HAR transfers.
class PlatformRequestTransferGateway implements RequestTransferGateway {
  PlatformRequestTransferGateway({
    Future<FilePickerResult?> Function()? pickFiles,
    Future<ShareResult> Function(ShareParams)? share,
  }) : _pickFiles = pickFiles ?? _defaultPickFiles,
       _share = share ?? _defaultShare;

  final Future<FilePickerResult?> Function() _pickFiles;
  final Future<ShareResult> Function(ShareParams) _share;

  /// Invokes the installed file picker with the HAR-only selection contract.
  static Future<FilePickerResult?> _defaultPickFiles() => FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['har', 'json'],
    withData: true,
  );

  /// Invokes the installed platform share surface for one prepared payload.
  static Future<ShareResult> _defaultShare(ShareParams params) =>
      SharePlus.instance.share(params);

  /// Opens a HAR file picker and reads only the currently selected file bytes.
  @override
  Future<HarSelectionResult> selectHar() async {
    try {
      final selected = await _pickFiles();
      if (selected == null || selected.files.isEmpty) {
        return const HarSelectionCancelled();
      }
      final bytes = selected.files.single.bytes;
      if (bytes == null) {
        return const HarSelectionFailure();
      }
      return HarSelectionSuccess(utf8.decode(bytes, allowMalformed: true));
    } catch (_) {
      return const HarSelectionFailure();
    }
  }

  /// Shares a temporary in-memory HAR file and maps platform cancellation.
  @override
  Future<HarShareResult> shareHar(RequestHarExportPayload payload) async {
    try {
      final result = await _share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              Uint8List.fromList(utf8.encode(payload.content)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: <String>[payload.fileName],
        ),
      );
      return result.status == ShareResultStatus.dismissed
          ? const HarShareCancelled()
          : const HarShareSuccess();
    } catch (_) {
      return const HarShareFailure();
    }
  }

  /// Shares plain text through the platform surface and maps its outcome.
  @override
  Future<TextShareResult> shareText(String text) async {
    try {
      final result = await _share(ShareParams(text: text));
      return result.status == ShareResultStatus.dismissed
          ? const TextShareCancelled()
          : const TextShareSuccess();
    } catch (_) {
      return const TextShareFailure();
    }
  }
}
