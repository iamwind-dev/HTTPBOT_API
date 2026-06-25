import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/requests_method.dart';

class SimpleCurlRequestParser {
  const SimpleCurlRequestParser();

  RequestDraft parse(String input) {
    final tokens = _tokenize(input);
    if (tokens.isEmpty) {
      return const RequestDraft();
    }

    var method = HttpMethod.get;
    var url = '';
    final headers = <KeyValueItem>[];
    final queryParameters = <KeyValueItem>[];
    var rawBody = '';
    var auth = const RequestAuthDraft.none();

    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];

      if (token == 'curl') {
        continue;
      }

      if ((token == '-X' || token == '--request') && index + 1 < tokens.length) {
        method = _methodFromToken(tokens[++index]);
        continue;
      }

      if ((token == '-H' || token == '--header') && index + 1 < tokens.length) {
        final header = tokens[++index];
        final separatorIndex = header.indexOf(':');
        if (separatorIndex > 0) {
          headers.add(
            KeyValueItem(
              key: header.substring(0, separatorIndex).trim(),
              value: header.substring(separatorIndex + 1).trim(),
            ),
          );
        }
        continue;
      }

      if ((token == '-d' ||
              token == '--data' ||
              token == '--data-raw' ||
              token == '--data-binary') &&
          index + 1 < tokens.length) {
        rawBody = tokens[++index];
        if (method == HttpMethod.get) {
          method = HttpMethod.post;
        }
        continue;
      }

      if ((token == '-u' || token == '--user') && index + 1 < tokens.length) {
        final credentials = tokens[++index];
        final separatorIndex = credentials.indexOf(':');
        if (separatorIndex >= 0) {
          auth = RequestAuthDraft(
            type: AuthType.basic,
            basic: BasicAuthDraft(
              username: credentials.substring(0, separatorIndex),
              password: credentials.substring(separatorIndex + 1),
            ),
          );
        }
        continue;
      }

      if (!token.startsWith('-') && url.isEmpty) {
        url = token;
      }
    }

    final uri = Uri.tryParse(url);
    if (uri != null && uri.queryParameters.isNotEmpty) {
      queryParameters.addAll(
        uri.queryParameters.entries.map(
          (entry) => KeyValueItem(key: entry.key, value: entry.value),
        ),
      );
    }

    return RequestDraft(
      method: method,
      url: url,
      queryParameters: queryParameters,
      headers: headers,
      body: _bodyFromRaw(rawBody, headers),
      auth: auth,
    );
  }

  RequestBodyDraft _bodyFromRaw(String rawBody, List<KeyValueItem> headers) {
    if (rawBody.trim().isEmpty) {
      return const RequestBodyDraft.none();
    }

    final contentType = headers
        .where((item) => item.key.toLowerCase() == 'content-type')
        .map((item) => item.value.toLowerCase())
        .cast<String?>()
        .firstWhere((value) => value != null && value.trim().isNotEmpty,
            orElse: () => null);

    final subtype = switch (contentType) {
      final value when value != null && value.contains('json') =>
        RawBodySubtype.json,
      final value when value != null && value.contains('xml') =>
        RawBodySubtype.xml,
      final value when value != null && value.contains('html') =>
        RawBodySubtype.html,
      _ => RawBodySubtype.text,
    };

    return RequestBodyDraft(
      type: RequestBodyType.raw,
      raw: RawBodyDraft(subtype: subtype, content: rawBody),
    );
  }

  HttpMethod _methodFromToken(String token) {
    final normalized = token.trim().toUpperCase();
    for (final method in HttpMethod.values) {
      if (method.wireName == normalized || method.label == normalized) {
        return method;
      }
    }
    return HttpMethod.get;
  }

  List<String> _tokenize(String input) {
    final matches = RegExp(r'''"([^"\\]|\\.)*"|'([^'\\]|\\.)*'|\S+''')
        .allMatches(input);
    return matches
        .map((match) => _stripQuotes(match.group(0) ?? ''))
        .where((token) => token.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _stripQuotes(String value) {
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
