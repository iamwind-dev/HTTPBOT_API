import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/digest_http_client.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/ntlm_http_client.dart';
import '../helpers/request_transport_inputs.dart';
import '../../domain/helpers/http_cookie_utils.dart';
import '../../domain/helpers/implicit_request_headers.dart';
import '../../domain/entities/auth_applied_request.dart';
import '../../domain/entities/executed_request_snapshot.dart';
import '../../domain/entities/http_exchange.dart';
import '../../domain/entities/request_auth_draft.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_execution_result.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/helpers/request_auth_validator.dart';
import '../../domain/repositories/http_cookie_repository.dart';
import '../../domain/repositories/request_execution_repository.dart';

class RequestExecutionRepositoryImpl implements RequestExecutionRepository {
  RequestExecutionRepositoryImpl(
    this._dioClient, {
    required HttpCookieRepository httpCookieRepository,
    NtlmHttpClient? ntlmHttpClient,
    DigestHttpClient? digestHttpClient,
  }) : _httpCookieRepository = httpCookieRepository,
       _ntlmHttpClient = ntlmHttpClient ?? NtlmHttpClient(),
       _digestHttpClient =
           digestHttpClient ?? DigestHttpClient(dioClient: _dioClient);

  final DioClient _dioClient;
  final HttpCookieRepository _httpCookieRepository;
  final NtlmHttpClient _ntlmHttpClient;
  final DigestHttpClient _digestHttpClient;

  /// Sends the prepared request with Dio and maps raw transport data into a domain execution result.
  @override
  Future<RequestExecutionResult> executeRequest(
    AuthAppliedRequest request,
  ) async {
    if (request.appliedAuthType == AuthType.ntlm) {
      final authValidation = validateAuthBeforeSend(request.request.auth);
      if (!authValidation.isValid) {
        return RequestExecutionResult(
          request: request.request,
          errorType: RequestExecutionErrorType.blocked,
          errorMessage: authValidation.errorMessage ?? '',
          resolutionIssues: request.resolutionIssues,
          authIssues: request.authIssues,
        );
      }

      return _ntlmHttpClient.execute(request);
    }

    if (request.appliedAuthType == AuthType.digest) {
      final authValidation = validateAuthBeforeSend(request.request.auth);
      if (!authValidation.isValid) {
        return RequestExecutionResult(
          request: request.request,
          errorType: RequestExecutionErrorType.blocked,
          errorMessage: authValidation.errorMessage ?? '',
          resolutionIssues: request.resolutionIssues,
          authIssues: request.authIssues,
        );
      }

      return _digestHttpClient.execute(request);
    }

    final stopwatch = Stopwatch()..start();
    final draft = request.request;
    final settings = draft.settings;
    final connectionMetadata = ConnectionMetadata();
    final dio = _dioClient.create(
      timeout: Duration(seconds: settings.timeoutSeconds),
      followRedirects: settings.followRedirects,
      verifySsl: settings.verifySsl,
      metadata: connectionMetadata,
    );
    final inputs = await buildRequestTransportInputs(draft);
    final headersWithUserAgent = _injectSettingsUserAgent(
      headers: inputs.headers,
      userAgent: settings.normalizedUserAgent,
    );
    final requestHeaders = settings.sendCookies
        ? mergeCookieHeader(
            headers: headersWithUserAgent,
            cookies: await _httpCookieRepository.getCookiesForRequestUrl(
              inputs.url,
            ),
          )
        : headersWithUserAgent;
    final requestBodyPreview = _buildRequestBodyPreview(inputs);
    final startAt = DateTime.now().toUtc();

    try {
      final response = await dio.request<List<int>>(
        inputs.url,
        data: inputs.canSendBody ? inputs.payload.data : null,
        options: Options(
          method: draft.method.wireName,
          headers: requestHeaders,
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
      );
      stopwatch.stop();
      final endAt = DateTime.now().toUtc();
      final protocol = _resolveProtocol(response.headers.map);
      final executedRequestSnapshot = _buildSnapshot(
        draft: draft,
        url: inputs.url,
        headers: requestHeaders,
        body: requestBodyPreview,
        protocol: protocol,
        startAt: startAt,
        endAt: endAt,
      );

      if (settings.storeCookies) {
        await _ingestSetCookieHeaders(
          requestUrl: inputs.url,
          headers: response.headers.map,
        );
      }

      final bodyBytes = _extractBodyBytes(response.data);
      final responseCookies = await _httpCookieRepository.getCookiesForRequestUrl(
        inputs.url,
      );

      return RequestExecutionResult(
        request: draft,
        statusCode: response.statusCode,
        statusMessage: _resolveStatusMessage(
          response.statusCode,
          response.statusMessage,
        ),
        headers: _flattenHeaders(response.headers.map),
        bodyBytes: bodyBytes,
        bodyText: _decodeBodyBytes(bodyBytes),
        duration: stopwatch.elapsed,
        executedRequestSnapshot: executedRequestSnapshot,
        exchanges: _buildExchanges(
          response: response,
          snapshot: executedRequestSnapshot,
          metadata: connectionMetadata,
          protocol: protocol,
          responseBodySizeBytes: bodyBytes.length,
          startAt: startAt,
          endAt: endAt,
        ),
        responseCookies: responseCookies,
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final endAt = DateTime.now().toUtc();
      final errorSnapshot = _buildSnapshot(
        draft: draft,
        url: inputs.url,
        headers: requestHeaders,
        body: requestBodyPreview,
        protocol: _resolveProtocol(
          error.response?.headers.map ?? const <String, List<String>>{},
        ),
        startAt: startAt,
        endAt: endAt,
      );
      if (settings.storeCookies) {
        await _ingestSetCookieHeaders(
          requestUrl: inputs.url,
          headers: error.response?.headers.map ?? const <String, List<String>>{},
        );
      }
      final bodyBytes = _extractBodyBytes(error.response?.data);
      final responseCookies = await _httpCookieRepository.getCookiesForRequestUrl(
        inputs.url,
      );

      return RequestExecutionResult(
        request: draft,
        statusCode: error.response?.statusCode,
        statusMessage: _resolveStatusMessage(
          error.response?.statusCode,
          error.response?.statusMessage,
        ),
        headers: _flattenHeaders(error.response?.headers.map ?? const {}),
        bodyBytes: bodyBytes,
        bodyText: _decodeBodyBytes(bodyBytes),
        duration: stopwatch.elapsed,
        executedRequestSnapshot: errorSnapshot,
        exchanges: _buildExchanges(
          response: error.response,
          snapshot: errorSnapshot,
          metadata: connectionMetadata,
          protocol: errorSnapshot.protocol,
          responseBodySizeBytes: bodyBytes.length,
          startAt: startAt,
          endAt: endAt,
          reasonPhrase: _resolveStatusMessage(
            error.response?.statusCode,
            error.response?.statusMessage,
          ),
        ),
        errorType: _mapErrorType(error),
        errorMessage: _buildErrorMessage(error),
        responseCookies: responseCookies,
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on Object catch (error) {
      stopwatch.stop();
      final endAt = DateTime.now().toUtc();
      final errorSnapshot = _buildSnapshot(
        draft: draft,
        url: inputs.url,
        headers: requestHeaders,
        body: requestBodyPreview,
        protocol: null,
        startAt: startAt,
        endAt: endAt,
      );

      return RequestExecutionResult(
        request: draft,
        duration: stopwatch.elapsed,
        executedRequestSnapshot: errorSnapshot,
        exchanges: _buildExchanges(
          response: null,
          snapshot: errorSnapshot,
          metadata: connectionMetadata,
          protocol: null,
          responseBodySizeBytes: 0,
          startAt: startAt,
          endAt: endAt,
        ),
        errorType: RequestExecutionErrorType.unknown,
        errorMessage: error.toString(),
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    }
  }

  /// Builds the executed request snapshot with byte sizes computed from headers and body.
  ExecutedRequestSnapshot _buildSnapshot({
    required RequestDraft draft,
    required String url,
    required Map<String, String> headers,
    required String? body,
    required String? protocol,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    final wireHeaders = withImplicitRequestHeaders(
      url: url,
      headers: headers,
      protocol: protocol,
    );
    return ExecutedRequestSnapshot(
      method: draft.method.wireName,
      url: url,
      headers: wireHeaders,
      body: body,
      protocol: protocol,
      headerSizeBytes: _headerSizeBytes(wireHeaders),
      bodySizeBytes: body == null ? 0 : utf8.encode(body).length,
      startAt: startAt,
      endAt: endAt,
    );
  }

  /// Builds the list of exchanges (one per attempt) for the Metrics tab.
  List<HttpExchange> _buildExchanges({
    required Response<dynamic>? response,
    required ExecutedRequestSnapshot snapshot,
    required ConnectionMetadata metadata,
    required String? protocol,
    required int responseBodySizeBytes,
    required DateTime startAt,
    required DateTime endAt,
    String? reasonPhrase,
  }) {
    final responseHeaders = response?.headers.map;
    final finalExchange = HttpExchange(
      index: 1,
      request: snapshot,
      statusCode: response?.statusCode,
      reasonPhrase: reasonPhrase ??
          (response == null
              ? null
              : _resolveStatusMessage(
                  response.statusCode,
                  response.statusMessage,
                )),
      protocol: protocol,
      remoteAddress: metadata.remoteAddress,
      tlsProtocol: metadata.tlsProtocol,
      tlsCipher: metadata.tlsCipher,
      responseHeaderSizeBytes:
          responseHeaders == null ? null : _responseHeaderSizeBytes(responseHeaders),
      responseBodySizeBytes: response == null ? null : responseBodySizeBytes,
      responseStartAt: startAt,
      responseEndAt: endAt,
    );

    return List<HttpExchange>.unmodifiable([finalExchange]);
  }

  /// Sums the wire size of request headers as `key: value\r\n` segments.
  int _headerSizeBytes(Map<String, String> headers) {
    var total = 0;
    headers.forEach((key, value) {
      total += utf8.encode('$key: $value\r\n').length;
    });
    return total;
  }

  /// Sums the wire size of response headers across all values.
  int _responseHeaderSizeBytes(Map<String, List<String>> headers) {
    var total = 0;
    headers.forEach((key, values) {
      for (final value in values) {
        total += utf8.encode('$key: $value\r\n').length;
      }
    });
    return total;
  }

  /// Best-effort protocol label from a response; Dio does not expose the
  /// negotiated HTTP version, so default to HTTP/1.1.
  String _resolveProtocol(Map<String, List<String>> responseHeaders) =>
      'HTTP/1.1';

  /// Flattens response headers into reusable key/value entities for downstream parsing and UI.
  List<KeyValueItem> _flattenHeaders(Map<String, List<String>> headers) {
    final items = <KeyValueItem>[];

    headers.forEach((key, values) {
      for (final value in values) {
        items.add(KeyValueItem(key: key, value: value));
      }
    });

    return List<KeyValueItem>.unmodifiable(items);
  }

  Future<void> _ingestSetCookieHeaders({
    required String requestUrl,
    required Map<String, List<String>> headers,
  }) async {
    final setCookieHeaders = <String>[];
    headers.forEach((key, values) {
      if (key.trim().toLowerCase() == 'set-cookie') {
        setCookieHeaders.addAll(values);
      }
    });

    if (setCookieHeaders.isEmpty) {
      return;
    }

    try {
      await _httpCookieRepository.upsertCookiesFromSetCookieHeaders(
        requestUrl,
        setCookieHeaders,
      );
    } catch (_) {
      // Cookie persistence should never fail the main request flow.
    }
  }

  /// Extracts response bytes regardless of whether Dio surfaced bytes, strings, or other payload types.
  List<int> _extractBodyBytes(Object? data) {
    if (data == null) {
      return const <int>[];
    }

    if (data is List<int>) {
      return List<int>.unmodifiable(data);
    }

    if (data is String) {
      return List<int>.unmodifiable(utf8.encode(data));
    }

    return List<int>.unmodifiable(utf8.encode(data.toString()));
  }

  /// Decodes bytes into text using UTF-8 with malformed input tolerated for raw inspector views.
  String _decodeBodyBytes(List<int> bodyBytes) =>
      utf8.decode(bodyBytes, allowMalformed: true);

  Map<String, String> _injectSettingsUserAgent({
    required Map<String, String> headers,
    required String? userAgent,
  }) {
    if (userAgent == null) {
      return headers;
    }

    // Manual User-Agent headers entered by the user always win; settings only
    // inject a fallback header when the request does not already define one.
    final hasManualUserAgent = headers.keys.any(
      (key) => key.trim().toLowerCase() == 'user-agent',
    );
    if (hasManualUserAgent) {
      return headers;
    }

    return <String, String>{...headers, 'User-Agent': userAgent};
  }

  String? _buildRequestBodyPreview(RequestTransportInputs inputs) {
    if (!inputs.canSendBody) {
      return null;
    }

    final data = inputs.payload.data;
    if (data == null) {
      return null;
    }

    if (data is String) {
      return data;
    }

    if (data is Map) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    }

    return data.toString();
  }

  /// Maps Dio transport failures into stable execution error categories.
  RequestExecutionErrorType _mapErrorType(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RequestExecutionErrorType.timeout;
      case DioExceptionType.badCertificate:
        return RequestExecutionErrorType.ssl;
      case DioExceptionType.cancel:
        return RequestExecutionErrorType.cancelled;
      case DioExceptionType.connectionError:
        return RequestExecutionErrorType.connection;
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return RequestExecutionErrorType.unknown;
    }
  }

  /// Produces a compact non-throwing error message for UI and logging.
  String _buildErrorMessage(DioException error) {
    if (error.message?.trim().isNotEmpty ?? false) {
      return error.message!.trim();
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out.',
      DioExceptionType.sendTimeout => 'Request body send timed out.',
      DioExceptionType.receiveTimeout => 'Response receive timed out.',
      DioExceptionType.badCertificate => 'SSL certificate validation failed.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.connectionError => 'Network connection failed.',
      DioExceptionType.badResponse => 'Server returned an unexpected response.',
      DioExceptionType.unknown => 'Request execution failed unexpectedly.',
    };
  }

  /// Returns a readable HTTP status message when Dio does not provide one.
  String _resolveStatusMessage(int? statusCode, String? statusMessage) {
    if (statusMessage?.trim().isNotEmpty ?? false) {
      return statusMessage!.trim();
    }

    return switch (statusCode) {
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      204 => 'No Content',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      409 => 'Conflict',
      422 => 'Unprocessable Entity',
      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      _ => '',
    };
  }
}
