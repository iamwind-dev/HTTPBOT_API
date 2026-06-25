import 'dart:convert';

import '../entities/request_auth_draft.dart';
import '../entities/request_body_draft.dart';
import '../entities/request_draft.dart';
import '../entities/request_key_value.dart';
import '../entities/request_variable_store.dart';
import '../usecases/apply_request_auth_use_case.dart';
import '../usecases/resolve_request_use_case.dart';

class CurlCommandBuilder {
  const CurlCommandBuilder({
    ResolveRequestUseCase resolveRequestUseCase = const ResolveRequestUseCase(),
    ApplyRequestAuthUseCase applyRequestAuthUseCase =
        const ApplyRequestAuthUseCase(),
  }) : _resolveRequestUseCase = resolveRequestUseCase,
       _applyRequestAuthUseCase = applyRequestAuthUseCase;

  final ResolveRequestUseCase _resolveRequestUseCase;
  final ApplyRequestAuthUseCase _applyRequestAuthUseCase;

  /// Builds a shell-ready cURL command from the current request draft.
  String build({
    required RequestDraft draft,
    RequestVariableStore variableStore = const RequestVariableStore(),
  }) {
    final resolvedRequest = _resolveRequestUseCase(
      draft: draft,
      variableStore: variableStore,
    );
    final authAppliedRequest = _applyRequestAuthUseCase(
      resolvedRequest: resolvedRequest,
    );
    final request = authAppliedRequest.request;
    final finalUrl = _buildFinalUrl(request);

    if (finalUrl.isEmpty) {
      return '';
    }

    final lines = <String>[
      'curl -v',
      ..._buildNativeAuthFlags(request.auth),
      '-X ${request.method.wireName}',
      ..._buildHeaderFlags(request.headers),
      ..._buildBodyFlags(request.body),
      _doubleQuoted(finalUrl),
    ];

    return lines
        .asMap()
        .entries
        .map(
          (entry) => entry.key == lines.length - 1
              ? '  ${entry.value}'
              : '${entry.key == 0 ? '' : '  '}${entry.value} \\',
        )
        .join('\n');
  }

  /// Rebuilds the request URL with enabled query rows appended.
  String _buildFinalUrl(RequestDraft request) {
    final uri = Uri.tryParse(request.url.trim());
    if (uri == null || !uri.hasScheme || !_isHttpScheme(uri.scheme)) {
      return '';
    }

    final querySegments = <String>[
      if (uri.query.isNotEmpty) uri.query,
      for (final item in request.queryParameters)
        if (item.isEnabled && item.key.trim().isNotEmpty)
          '${Uri.encodeQueryComponent(item.key.trim())}='
              '${Uri.encodeQueryComponent(item.value)}',
    ];

    return uri
        .replace(query: querySegments.isEmpty ? null : querySegments.join('&'))
        .toString();
  }

  /// Returns true when the URL scheme can be represented by cURL HTTP flags.
  bool _isHttpScheme(String scheme) {
    final normalizedScheme = scheme.toLowerCase();

    return normalizedScheme == 'http' || normalizedScheme == 'https';
  }

  /// Converts connection-level auth modes into native cURL flags.
  List<String> _buildNativeAuthFlags(RequestAuthDraft auth) =>
      switch (auth.type) {
        AuthType.ntlm => _buildNtlmFlags(auth.ntlm),
        AuthType.digest => _buildDigestFlags(auth.digest),
        _ => const <String>[],
      };

  /// Builds NTLM flags when the draft has enough credentials to authenticate.
  List<String> _buildNtlmFlags(NtlmAuthDraft ntlm) {
    if (ntlm.username.trim().isEmpty || ntlm.password.isEmpty) {
      return const <String>[];
    }

    final username = ntlm.domain.trim().isEmpty
        ? ntlm.username.trim()
        : '${ntlm.domain.trim()}\\${ntlm.username.trim()}';

    return <String>[
      '--ntlm',
      '-u ${_doubleQuoted('$username:${ntlm.password}')}',
    ];
  }

  /// Builds Digest flags when the draft has enough credentials to authenticate.
  List<String> _buildDigestFlags(DigestAuthDraft digest) {
    if (digest.username.trim().isEmpty || digest.password.isEmpty) {
      return const <String>[];
    }

    return <String>[
      '--digest',
      '-u ${_doubleQuoted('${digest.username.trim()}:${digest.password}')}',
    ];
  }

  /// Converts enabled headers into cURL header flags.
  List<String> _buildHeaderFlags(List<KeyValueItem> headers) => headers
      .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
      .map(
        (item) =>
            '-H ${_doubleQuoted('${item.key.trim()}: ${item.value.trim()}')}',
      )
      .toList(growable: false);

  /// Converts the active body mode into cURL data or multipart flags.
  List<String> _buildBodyFlags(RequestBodyDraft body) => switch (body.type) {
    RequestBodyType.none => const <String>[],
    RequestBodyType.raw =>
      body.raw.content.trim().isEmpty
          ? const <String>[]
          : <String>['-d ${_singleQuoted(body.raw.content)}'],
    RequestBodyType.xWwwFormUrlEncoded => <String>[
      '-d ${_doubleQuoted(_buildUrlEncodedBody(body.urlEncoded))}',
    ],
    RequestBodyType.formData => _buildFormDataFlags(body.formData),
    RequestBodyType.graphql => _buildGraphQlFlags(body.graphQl),
  };

  /// Encodes enabled URL-encoded form rows into a request body string.
  String _buildUrlEncodedBody(List<KeyValueItem> items) => items
      .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
      .map(
        (item) =>
            '${Uri.encodeQueryComponent(item.key.trim())}='
            '${Uri.encodeQueryComponent(item.value)}',
      )
      .join('&');

  /// Converts enabled multipart form rows into cURL form flags.
  List<String> _buildFormDataFlags(List<KeyValueItem> items) => items
      .where((item) => item.isEnabled && item.key.trim().isNotEmpty)
      .map((item) {
        final key = item.key.trim();
        final value = item.type == KeyValueItemType.file
            ? '@${item.value.trim().isEmpty ? key : item.value.trim()}'
            : item.value;

        return '-F ${_doubleQuoted('$key=$value')}';
      })
      .toList(growable: false);

  /// Converts GraphQL query and variables into a JSON request body.
  List<String> _buildGraphQlFlags(GraphQlBodyDraft graphQl) {
    if (!graphQl.hasContent) {
      return const <String>[];
    }

    final payload = <String, Object?>{
      'query': graphQl.query,
      if (_decodeGraphQlVariables(graphQl.variables) case final variables?)
        'variables': variables,
    };

    return <String>['-d ${_singleQuoted(jsonEncode(payload))}'];
  }

  /// Decodes GraphQL variables JSON and falls back to raw text when invalid.
  Object? _decodeGraphQlVariables(String variables) {
    final trimmedVariables = variables.trim();
    if (trimmedVariables.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(trimmedVariables);
    } on FormatException {
      return trimmedVariables;
    }
  }

  /// Wraps a value in double quotes with shell-sensitive characters escaped.
  String _doubleQuoted(String value) {
    final escapedValue = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`')
        .replaceAll('\n', r'\n');

    return '"$escapedValue"';
  }

  /// Wraps a value in single quotes using the POSIX-safe quote escape sequence.
  String _singleQuoted(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
