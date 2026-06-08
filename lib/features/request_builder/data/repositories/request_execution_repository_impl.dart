import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../mappers/request_body_mapper.dart';
import '../../domain/entities/auth_applied_request.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_execution_result.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/entities/requests_method.dart';
import '../../domain/repositories/request_execution_repository.dart';

class RequestExecutionRepositoryImpl implements RequestExecutionRepository {
  const RequestExecutionRepositoryImpl(this._dioClient);

  final DioClient _dioClient;

  /// Sends the prepared request with Dio and maps raw transport data into a domain execution result.
  @override
  Future<RequestExecutionResult> executeRequest(
    AuthAppliedRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final draft = request.request;
    final dio = _dioClient.create(
      timeout: draft.timeout,
      verifySsl: draft.verifySsl,
    );
    final canSendBody = methodSupportsRequestBody(draft.method);
    final payload = canSendBody
        ? await buildRequestBodyPayload(draft.body)
        : const RequestBodyPayload();
    final headers = _buildHeaders(
      draft,
      payload: payload,
      canSendBody: canSendBody,
    );

    try {
      final response = await dio.request<List<int>>(
        _buildExecutionUrl(draft.url, draft.queryParameters),
        data: canSendBody ? payload.data : null,
        options: Options(
          method: draft.method.wireName,
          headers: headers,
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
      );
      stopwatch.stop();

      final bodyBytes = _extractBodyBytes(response.data);

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
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on DioException catch (error) {
      stopwatch.stop();
      final bodyBytes = _extractBodyBytes(error.response?.data);

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
        errorType: _mapErrorType(error),
        errorMessage: _buildErrorMessage(error),
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    } on Object catch (error) {
      stopwatch.stop();

      return RequestExecutionResult(
        request: draft,
        duration: stopwatch.elapsed,
        errorType: RequestExecutionErrorType.unknown,
        errorMessage: error.toString(),
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    }
  }

  /// Builds the exact URL string sent to the server while preserving duplicate query keys.
  String _buildExecutionUrl(
    String baseUrl,
    List<KeyValueItem> queryParameters,
  ) {
    final enabledQueryParameters = queryParameters
        .where((item) => item.isEnabled && item.hasKey)
        .map(
          (item) =>
              '${Uri.encodeQueryComponent(item.key)}=${Uri.encodeQueryComponent(item.value)}',
        )
        .toList(growable: false);

    if (enabledQueryParameters.isEmpty) {
      return baseUrl;
    }

    final suffix = enabledQueryParameters.join('&');
    if (baseUrl.contains('?')) {
      final separator = baseUrl.endsWith('?') || baseUrl.endsWith('&')
          ? ''
          : '&';
      return '$baseUrl$separator$suffix';
    }

    return '$baseUrl?$suffix';
  }

  /// Converts enabled request headers into a transport header map and adds default content types when needed.
  Map<String, String> _buildHeaders(
    RequestDraft draft, {
    required RequestBodyPayload payload,
    required bool canSendBody,
  }) {
    final headers = <String, String>{};

    for (final item in draft.headers.where(
      (item) => item.isEnabled && item.hasKey,
    )) {
      headers[item.key] = item.value;
    }

    if (!canSendBody || payload.contentType == null) {
      return headers;
    }

    if (_containsHeader(headers, Headers.contentTypeHeader)) {
      return headers;
    }

    headers[Headers.contentTypeHeader] = payload.contentType!;
    return headers;
  }

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

  /// Returns true when a header key already exists ignoring case differences.
  bool _containsHeader(Map<String, String> headers, String key) => headers.keys
      .any((existingKey) => existingKey.toLowerCase() == key.toLowerCase());
}
