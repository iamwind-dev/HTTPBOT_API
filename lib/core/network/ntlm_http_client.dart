import 'dart:convert';
import 'dart:io';

import '../../features/request_builder/data/helpers/request_transport_inputs.dart';
import '../../features/request_builder/domain/entities/auth_applied_request.dart';
import '../../features/request_builder/domain/entities/request_draft.dart';
import '../../features/request_builder/domain/entities/request_execution_result.dart';
import '../../features/request_builder/domain/entities/request_key_value.dart';
import 'ntlm/ntlm_messages.dart';

typedef HttpClientFactory = HttpClient Function();

class NtlmHttpClient {
  NtlmHttpClient({HttpClientFactory? httpClientFactory})
      : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  final HttpClientFactory _httpClientFactory;

  /// Executes [request] using an NTLMv2 handshake over a persisted connection.
  Future<RequestExecutionResult> execute(AuthAppliedRequest request) async {
    final stopwatch = Stopwatch()..start();
    final draft = request.request;
    final ntlm = draft.auth.ntlm;
    final inputs = await buildRequestTransportInputs(draft);
    final uri = Uri.parse(inputs.url);
    final bodyBytes = _encodeBody(inputs);

    final client = _httpClientFactory();
    client.idleTimeout = const Duration(seconds: 30);
    client.connectionTimeout = draft.timeout;

    try {
      final type1Response = await _send(
        client,
        uri,
        draft.method.wireName,
        headers: inputs.headers,
        authorization: 'NTLM ${createType1Message()}',
        bodyBytes: const <int>[],
      );
      await type1Response.drain<void>();

      final challengeHeader = type1Response.headers['www-authenticate'];
      final challengeToken = _extractNtlmChallenge(challengeHeader);
      if (challengeToken == null) {
        stopwatch.stop();
        return _errorResult(
          draft: draft,
          request: request,
          duration: stopwatch.elapsed,
          errorType: RequestExecutionErrorType.unknown,
          message: 'Server did not request NTLM authentication.',
        );
      }

      final type3 = createType3Message(
        type2: parseType2Message(challengeToken),
        username: ntlm.username.trim(),
        password: ntlm.password,
        domain: ntlm.domain.trim(),
        workstation: ntlm.workstation.trim(),
      );
      final finalResponse = await _send(
        client,
        uri,
        draft.method.wireName,
        headers: inputs.headers,
        authorization: 'NTLM $type3',
        bodyBytes: bodyBytes,
      );

      final responseBytes = await _readBytes(finalResponse);
      stopwatch.stop();

      final statusCode = finalResponse.statusCode;
      if (statusCode == HttpStatus.unauthorized) {
        return RequestExecutionResult(
          request: draft,
          statusCode: statusCode,
          statusMessage: 'Unauthorized',
          headers: _flattenHeaders(finalResponse.headers),
          bodyBytes: responseBytes,
          bodyText: utf8.decode(responseBytes, allowMalformed: true),
          duration: stopwatch.elapsed,
          errorType: RequestExecutionErrorType.unknown,
          errorMessage:
              'NTLM authentication failed. Check username, password, and domain.',
          resolutionIssues: request.resolutionIssues,
          authIssues: request.authIssues,
        );
      }

      return RequestExecutionResult(
        request: draft,
        statusCode: statusCode,
        statusMessage: finalResponse.reasonPhrase,
        headers: _flattenHeaders(finalResponse.headers),
        bodyBytes: responseBytes,
        bodyText: utf8.decode(responseBytes, allowMalformed: true),
        duration: stopwatch.elapsed,
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on SocketException {
      stopwatch.stop();
      return _errorResult(
        draft: draft,
        request: request,
        duration: stopwatch.elapsed,
        errorType: RequestExecutionErrorType.connection,
        message: 'Network request failed.',
      );
    } on Object catch (error) {
      stopwatch.stop();
      return _errorResult(
        draft: draft,
        request: request,
        duration: stopwatch.elapsed,
        errorType: RequestExecutionErrorType.unknown,
        message: error.toString(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<HttpClientResponse> _send(
    HttpClient client,
    Uri uri,
    String method, {
    required Map<String, String> headers,
    required String authorization,
    required List<int> bodyBytes,
  }) async {
    final httpRequest = await client.openUrl(method, uri);
    httpRequest.persistentConnection = true;
    headers.forEach(httpRequest.headers.set);
    httpRequest.headers.set(HttpHeaders.authorizationHeader, authorization);
    if (bodyBytes.isNotEmpty) {
      httpRequest.add(bodyBytes);
    }
    return httpRequest.close();
  }

  List<int> _encodeBody(RequestTransportInputs inputs) {
    if (!inputs.canSendBody) {
      return const <int>[];
    }
    final data = inputs.payload.data;
    if (data == null) {
      return const <int>[];
    }
    if (data is List<int>) {
      return data;
    }
    if (data is String) {
      return utf8.encode(data);
    }
    if (data is Map) {
      return utf8.encode(jsonEncode(data));
    }
    return utf8.encode(data.toString());
  }

  String? _extractNtlmChallenge(List<String>? headerValues) {
    if (headerValues == null) {
      return null;
    }
    for (final value in headerValues) {
      final trimmed = value.trim();
      if (trimmed.toUpperCase().startsWith('NTLM ')) {
        return trimmed.substring(5).trim();
      }
    }
    return null;
  }

  Future<List<int>> _readBytes(HttpClientResponse response) async {
    final chunks = <int>[];
    await for (final chunk in response) {
      chunks.addAll(chunk);
    }
    return List<int>.unmodifiable(chunks);
  }

  List<KeyValueItem> _flattenHeaders(HttpHeaders headers) {
    final items = <KeyValueItem>[];
    headers.forEach((name, values) {
      for (final value in values) {
        items.add(KeyValueItem(key: name, value: value));
      }
    });
    return List<KeyValueItem>.unmodifiable(items);
  }

  RequestExecutionResult _errorResult({
    required RequestDraft draft,
    required AuthAppliedRequest request,
    required Duration duration,
    required RequestExecutionErrorType errorType,
    required String message,
  }) =>
      RequestExecutionResult(
        request: draft,
        duration: duration,
        errorType: errorType,
        errorMessage: message,
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
}
