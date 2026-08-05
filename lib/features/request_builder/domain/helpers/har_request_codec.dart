import 'dart:convert';

import '../entities/request_body_draft.dart';
import '../entities/request_draft.dart';

/// Converts the supported HAR 1.2 request fields to and from request drafts.
class HarRequestCodec {
  const HarRequestCodec();

  /// Encodes one request draft as a self-contained HAR 1.2 document.
  String encode({required String title, required RequestDraft draft}) {
    final uri = Uri.tryParse(draft.url.trim());
    if (uri == null || !uri.hasScheme || !_isHttpScheme(uri.scheme)) {
      throw const FormatException('A valid HTTP or HTTPS URL is required.');
    }

    final queryString = <Map<String, String>>[
      ...uri.queryParametersAll.entries.expand(
        (entry) => entry.value.map(
          (value) => <String, String>{'name': entry.key, 'value': value},
        ),
      ),
      for (final item in draft.queryParameters)
        if (item.isEnabled && item.hasKey)
          <String, String>{'name': item.key.trim(), 'value': item.value},
    ];
    final headers = draft.headers
        .where((item) => item.isEnabled && item.hasKey)
        .map(
          (item) => <String, String>{
            'name': item.key.trim(),
            'value': item.value,
          },
        )
        .toList(growable: false);

    final request = <String, Object?>{
      'method': draft.method.wireName,
      'url': uri.toString(),
      'httpVersion': 'HTTP/1.1',
      'headers': headers,
      'queryString': queryString,
      'cookies': const <Object>[],
      'headersSize': -1,
      'bodySize': -1,
      if (_postData(draft.body) case final postData?) 'postData': postData,
    };
    final safeTitle = title.trim().isEmpty ? 'request' : title.trim();
    return jsonEncode(<String, Object?>{
      'log': <String, Object?>{
        'version': '1.2',
        'creator': <String, String>{'name': 'HTTPBot API', 'version': '1.0'},
        'pages': <Object>[
          <String, Object?>{
            'startedDateTime': DateTime.now().toUtc().toIso8601String(),
            'id': safeTitle,
            'title': safeTitle,
            'pageTimings': const <String, int>{},
          },
        ],
        'entries': <Object>[
          <String, Object?>{
            'startedDateTime': DateTime.now().toUtc().toIso8601String(),
            'time': 0,
            'request': request,
            'response': <String, Object?>{
              'status': 0,
              'statusText': '',
              'httpVersion': 'HTTP/1.1',
              'headers': const <Object>[],
              'cookies': const <Object>[],
              'content': const <String, Object?>{'size': 0, 'mimeType': ''},
              'redirectURL': '',
              'headersSize': -1,
              'bodySize': -1,
            },
            'cache': const <String, Object?>{},
            'timings': const <String, int>{'send': 0, 'wait': 0, 'receive': 0},
          },
        ],
      },
    });
  }

  Map<String, Object?>? _postData(RequestBodyDraft body) {
    if (!body.hasContent) {
      return null;
    }
    return switch (body.type) {
      RequestBodyType.raw => <String, Object?>{
        'mimeType': body.raw.subtype.contentType,
        'text': body.raw.content,
      },
      RequestBodyType.xWwwFormUrlEncoded => <String, Object?>{
        'mimeType': 'application/x-www-form-urlencoded',
        'text': body.urlEncoded
            .where((item) => item.isEnabled && item.hasKey)
            .map((item) => '${item.key}=${item.value}')
            .join('&'),
      },
      RequestBodyType.formData => <String, Object?>{
        'mimeType': 'multipart/form-data',
        'params': body.formData
            .where((item) => item.isEnabled && item.hasKey)
            .map(
              (item) => <String, String>{'name': item.key, 'value': item.value},
            )
            .toList(growable: false),
      },
      RequestBodyType.graphql => <String, Object?>{
        'mimeType': 'application/json',
        'text': jsonEncode(<String, String>{
          'query': body.graphQl.query,
          'variables': body.graphQl.variables,
        }),
      },
      RequestBodyType.none => null,
    };
  }

  bool _isHttpScheme(String scheme) =>
      scheme.toLowerCase() == 'http' || scheme.toLowerCase() == 'https';
}
