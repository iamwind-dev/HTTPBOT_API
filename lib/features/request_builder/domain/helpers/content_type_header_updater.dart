import '../entities/request_body_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';
import 'body_content_type_policy.dart';
import 'header_method_policy.dart';

/// Synchronizes the visible Content-Type header with the current body mode.
List<KeyValueItem> syncContentTypeHeaderWithBodyType({
  required List<KeyValueItem> headers,
  required RequestBodyType bodyType,
  required HttpMethod method,
}) {
  final targetContentType = contentTypeForBodyType(bodyType);
  final canAutoAttachContentType =
      shouldAutoAttachContentTypeForMethod(method) && targetContentType != null;
  final hasUserDefinedContentType = headers.any(
    _isUserDefinedContentTypeHeader,
  );
  final systemHeaderIndex = headers.indexWhere(
    (header) => header.isSystemGeneratedContentTypeHeader,
  );

  if (!canAutoAttachContentType || hasUserDefinedContentType) {
    return _removeSystemGeneratedContentTypeHeaders(headers);
  }

  if (systemHeaderIndex == -1) {
    return List<KeyValueItem>.unmodifiable(<KeyValueItem>[
      ...headers,
      KeyValueItem(
        key: 'Content-Type',
        value: targetContentType,
        description: bodyContentTypeSystemGeneratedHeaderDescription,
      ),
    ]);
  }

  final nextHeaders = <KeyValueItem>[];
  var keptSystemHeader = false;

  for (var index = 0; index < headers.length; index++) {
    final header = headers[index];

    if (!header.isSystemGeneratedContentTypeHeader) {
      nextHeaders.add(header);
      continue;
    }

    if (index == systemHeaderIndex && !keptSystemHeader) {
      nextHeaders.add(
        header.copyWith(
          key: 'Content-Type',
          value: targetContentType,
          isEnabled: true,
          description: bodyContentTypeSystemGeneratedHeaderDescription,
        ),
      );
      keptSystemHeader = true;
    }
  }

  return List<KeyValueItem>.unmodifiable(nextHeaders);
}

/// Returns a user-owned version of a generated Content-Type header after edits.
KeyValueItem promoteContentTypeHeaderToUserDefined(KeyValueItem header) {
  if (header.description != bodyContentTypeSystemGeneratedHeaderDescription) {
    return header;
  }

  return header.copyWith(description: '');
}

/// Returns true when a row targets Content-Type without being app-managed.
bool _isUserDefinedContentTypeHeader(KeyValueItem header) =>
    header.key.trim().toLowerCase() == 'content-type' &&
    !header.isSystemGeneratedContentTypeHeader;

/// Removes every app-managed Content-Type row while keeping user headers intact.
List<KeyValueItem> _removeSystemGeneratedContentTypeHeaders(
  List<KeyValueItem> headers,
) => List<KeyValueItem>.unmodifiable(
  headers
      .where((header) => !header.isSystemGeneratedContentTypeHeader)
      .toList(growable: false),
);
