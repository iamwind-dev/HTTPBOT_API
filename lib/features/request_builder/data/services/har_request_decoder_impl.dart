import 'dart:convert';

import '../../domain/entities/har_request_import_outcome.dart';
import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/entities/saved_request_draft.dart';
import '../../domain/repositories/har_request_decoder.dart';

/// Decodes the supported HAR 1.2 request fields at the data boundary.
class HarRequestDecoderImpl implements HarRequestDecoder {
  const HarRequestDecoderImpl();

  @override
  HarRequestImportOutcome decode(String content) {
    try {
      final root = _asMap(jsonDecode(content));
      final entries = _asMap(root['log'])['entries'];
      if (entries is! List) {
        return const HarRequestImportFailure();
      }

      final requests = entries
          .map(_decodeEntry)
          .whereType<SavedRequestDraft>()
          .toList(growable: false);
      if (requests.isEmpty) {
        return const HarRequestImportFailure();
      }
      return HarRequestImportSuccess(
        requests: requests,
        skippedCount: entries.length - requests.length,
      );
    } catch (_) {
      return const HarRequestImportFailure();
    }
  }

  SavedRequestDraft? _decodeEntry(Object? entry) {
    final request = _asMap(_asMap(entry)['request']);
    final method = _method(request['method']);
    final url = request['url'] as String?;
    if (method == null || url == null || !_isHttpUrl(url)) {
      return null;
    }

    return SavedRequestDraft(
      title: '${method.wireName} $url',
      draft: RequestDraft(
        method: method,
        url: url,
        headers: _keyValues(request['headers']),
        queryParameters: _keyValues(request['queryString']),
        body: _body(request['postData']),
      ),
    );
  }

  RequestBodyDraft _body(Object? value) {
    final postData = _asMap(value);
    final mimeType = (postData['mimeType'] as String? ?? '').toLowerCase();
    final parameters = _keyValues(postData['params']);
    if (parameters.isNotEmpty) {
      return RequestBodyDraft(
        type: mimeType.contains('multipart/form-data')
            ? RequestBodyType.formData
            : RequestBodyType.xWwwFormUrlEncoded,
        formData: mimeType.contains('multipart/form-data')
            ? parameters
            : const <KeyValueItem>[],
        urlEncoded: mimeType.contains('multipart/form-data')
            ? const <KeyValueItem>[]
            : parameters,
      );
    }
    final text = postData['text'] as String? ?? '';
    if (text.isEmpty) {
      return const RequestBodyDraft.none();
    }
    final subtype = mimeType.contains('json')
        ? RawBodySubtype.json
        : mimeType.contains('xml')
        ? RawBodySubtype.xml
        : mimeType.contains('html')
        ? RawBodySubtype.html
        : RawBodySubtype.text;
    return RequestBodyDraft(
      type: RequestBodyType.raw,
      raw: RawBodyDraft(subtype: subtype, content: text),
    );
  }

  List<KeyValueItem> _keyValues(Object? value) {
    if (value is! List) {
      return const <KeyValueItem>[];
    }
    return value
        .map(_asMap)
        .map(
          (item) => KeyValueItem(
            key: item['name'] as String? ?? '',
            value: item['value'] as String? ?? '',
          ),
        )
        .where((item) => item.hasKey)
        .toList(growable: false);
  }

  HttpMethod? _method(Object? value) {
    final wireName = (value as String?)?.trim().toUpperCase();
    for (final method in HttpMethod.values) {
      if (method.wireName == wireName) {
        return method;
      }
    }
    return null;
  }

  Map<String, Object?> _asMap(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : const <String, Object?>{};

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }
}
