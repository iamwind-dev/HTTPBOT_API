import 'dart:convert';

import 'package:dio/dio.dart';

import '../../features/request_builder/data/helpers/request_transport_inputs.dart';
import '../../features/request_builder/domain/entities/auth_applied_request.dart';
import '../../features/request_builder/domain/entities/request_draft.dart';
import '../../features/request_builder/domain/entities/request_execution_result.dart';
import '../../features/request_builder/domain/entities/request_key_value.dart';
import '../../features/request_builder/domain/helpers/digest_authorization_header_builder.dart';
import '../../features/request_builder/domain/helpers/digest_challenge_parser.dart';
import 'dio_client.dart';

typedef DigestDioFactory = Dio Function(RequestDraft draft);

class DigestHttpClient {
  DigestHttpClient({
    DioClient dioClient = const DioClient(),
    DigestAuthorizationHeaderBuilder headerBuilder =
        const DigestAuthorizationHeaderBuilder(),
    DigestDioFactory? dioFactory,
  }) : _headerBuilder = headerBuilder,
       _dioFactory =
           dioFactory ??
           ((draft) => dioClient.create(
             timeout: draft.timeout,
             verifySsl: draft.verifySsl,
           ));

  final DigestAuthorizationHeaderBuilder _headerBuilder;
  final DigestDioFactory _dioFactory;

  /// Executes [request] with HTTP Digest authentication.
  ///
  /// When the draft carries a manual realm and nonce, the Authorization header
  /// is built up front and the request is sent once. Otherwise the request is
  /// sent without Authorization first and retried exactly once using the
  /// server's `WWW-Authenticate: Digest` challenge.
  Future<RequestExecutionResult> execute(AuthAppliedRequest request) async {
    final stopwatch = Stopwatch()..start();
    final draft = request.request;
    final digest = draft.auth.digest;

    if (_hasUserDefinedAuthorization(draft)) {
      return _blockedResult(
        request,
        stopwatch,
        'Authorization header already exists as user-defined.',
      );
    }

    String? manualAuthorization;
    if (digest.hasManualChallenge) {
      final buildResult = _headerBuilder.build(
        method: draft.method.wireName,
        url: draft.url,
        digest: digest,
      );
      if (!buildResult.isValid) {
        return _blockedResult(
          request,
          stopwatch,
          buildResult.errorMessage ??
              'Could not build Digest Authorization header.',
        );
      }
      manualAuthorization = buildResult.authorizationHeader;
    }

    try {
      final firstResponse = await _send(draft, manualAuthorization);
      if (firstResponse.statusCode != 401) {
        stopwatch.stop();
        return _responseResult(request, stopwatch, firstResponse);
      }

      final challenge = _extractDigestChallenge(firstResponse);
      if (challenge == null) {
        stopwatch.stop();
        return _responseResult(
          request,
          stopwatch,
          firstResponse,
          errorType: RequestExecutionErrorType.unknown,
          errorMessage: manualAuthorization == null
              ? 'Digest challenge was not received.'
              : null,
        );
      }

      final retryBuildResult = _headerBuilder.build(
        method: draft.method.wireName,
        url: draft.url,
        digest: digest,
        challenge: challenge,
      );
      if (!retryBuildResult.isValid) {
        stopwatch.stop();
        return _responseResult(
          request,
          stopwatch,
          firstResponse,
          errorType: RequestExecutionErrorType.unknown,
          errorMessage:
              retryBuildResult.errorMessage ??
              'Could not build Digest Authorization header.',
        );
      }

      final retryResponse = await _send(
        draft,
        retryBuildResult.authorizationHeader,
      );
      stopwatch.stop();

      return _responseResult(request, stopwatch, retryResponse);
    } on DioException catch (error) {
      stopwatch.stop();

      return RequestExecutionResult(
        request: draft,
        statusCode: error.response?.statusCode,
        statusMessage: error.response?.statusMessage ?? '',
        headers: _flattenHeaders(error.response?.headers.map ?? const {}),
        duration: stopwatch.elapsed,
        errorType: _mapErrorType(error),
        errorMessage: error.message ?? 'Request execution failed unexpectedly.',
        resolutionIssues: request.resolutionIssues,
        authIssues: request.authIssues,
      );
    }
  }

  /// Sends one attempt, rebuilding transport inputs so the body can be resent.
  Future<Response<List<int>>> _send(
    RequestDraft draft,
    String? authorization,
  ) async {
    final inputs = await buildRequestTransportInputs(draft);
    final headers = Map<String, String>.from(inputs.headers);
    if (authorization != null) {
      headers['Authorization'] = authorization;
    }
    final dio = _dioFactory(draft);

    return dio.request<List<int>>(
      inputs.url,
      data: inputs.canSendBody ? inputs.payload.data : null,
      options: Options(
        method: draft.method.wireName,
        headers: headers,
        responseType: ResponseType.bytes,
        validateStatus: (_) => true,
      ),
    );
  }

  /// Returns true when an enabled request header already sets Authorization.
  bool _hasUserDefinedAuthorization(RequestDraft draft) => draft.headers.any(
    (header) =>
        header.isEnabled &&
        header.key.trim().toLowerCase() == 'authorization' &&
        !header.isAnySystemGeneratedHeader,
  );

  /// Returns the parsed Digest challenge of a 401 response, if any.
  DigestChallenge? _extractDigestChallenge(Response<List<int>> response) {
    final headerValues = response.headers['www-authenticate'];
    if (headerValues == null) {
      return null;
    }

    for (final value in headerValues) {
      final challenge = parseDigestChallenge(value);
      if (challenge != null) {
        return challenge;
      }
    }

    return null;
  }

  /// Maps a completed transport response into a domain execution result.
  RequestExecutionResult _responseResult(
    AuthAppliedRequest request,
    Stopwatch stopwatch,
    Response<List<int>> response, {
    RequestExecutionErrorType? errorType,
    String? errorMessage,
  }) {
    final bodyBytes = response.data ?? const <int>[];

    return RequestExecutionResult(
      request: request.request,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage ?? '',
      headers: _flattenHeaders(response.headers.map),
      bodyBytes: List<int>.unmodifiable(bodyBytes),
      bodyText: utf8.decode(bodyBytes, allowMalformed: true),
      duration: stopwatch.elapsed,
      errorType: errorMessage == null ? null : errorType,
      errorMessage: errorMessage ?? '',
      resolutionIssues: request.resolutionIssues,
      authIssues: request.authIssues,
    );
  }

  /// Returns a blocked result for failures detected before any network call.
  RequestExecutionResult _blockedResult(
    AuthAppliedRequest request,
    Stopwatch stopwatch,
    String message,
  ) {
    stopwatch.stop();

    return RequestExecutionResult(
      request: request.request,
      duration: stopwatch.elapsed,
      errorType: RequestExecutionErrorType.blocked,
      errorMessage: message,
      resolutionIssues: request.resolutionIssues,
      authIssues: request.authIssues,
    );
  }

  /// Flattens response headers into reusable key/value entities.
  List<KeyValueItem> _flattenHeaders(Map<String, List<String>> headers) {
    final items = <KeyValueItem>[];

    headers.forEach((key, values) {
      for (final value in values) {
        items.add(KeyValueItem(key: key, value: value));
      }
    });

    return List<KeyValueItem>.unmodifiable(items);
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
}
