import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/request_auth_draft.dart';
import '../../domain/helpers/oauth2_token_details_masker.dart';
import '../models/oauth2_token_exchange_result.dart';
import '../models/oauth2_token_response.dart';

class OAuth2RemoteDataSource {
  const OAuth2RemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Exchanges an authorization code using the configured OAuth2 token endpoint.
  Future<OAuth2TokenExchangeResult> exchangeAuthorizationCode({
    required OAuth2AuthDraft auth,
    required String code,
  }) async {
    final requestBody = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': auth.redirectUri.trim(),
    };

    if (auth.clientAuthentication == OAuth2ClientAuthentication.requestBody) {
      final clientId = auth.clientId.trim();
      if (clientId.isNotEmpty) {
        requestBody['client_id'] = clientId;
      }

      final clientSecret = auth.clientSecret.trim();
      if (clientSecret.isNotEmpty) {
        requestBody['client_secret'] = clientSecret;
      }
    }

    if (auth.usePkce && auth.codeVerifier.trim().isNotEmpty) {
      requestBody['code_verifier'] = auth.codeVerifier.trim();
    }

    for (final item in auth.tokenRequestParams) {
      final key = item.key.trim();
      if (!item.isEnabled || key.isEmpty || requestBody.containsKey(key)) {
        continue;
      }

      requestBody[key] = item.value;
    }

    final headers = <String, String>{
      'Content-Type': Headers.formUrlEncodedContentType,
      'Accept': Headers.jsonContentType,
    };

    if (auth.clientAuthentication ==
        OAuth2ClientAuthentication.basicAuthHeader) {
      final clientId = auth.clientId.trim();
      final clientSecret = auth.clientSecret.trim();

      if (clientId.isNotEmpty || clientSecret.isNotEmpty) {
        final credentials = base64Encode(
          utf8.encode('$clientId:$clientSecret'),
        );
        headers['Authorization'] = 'Basic $credentials';
      }
    }

    final response = await _postTokenRequest(
      accessTokenUrl: auth.resolvedAccessTokenUrl,
      headers: headers,
      requestBody: requestBody,
    );

    final responseBody = response.data;
    if (responseBody is Map<String, Object?>) {
      return _buildExchangeResult(
        tokenResponse: OAuth2TokenResponse.fromJson(responseBody),
        requestHeaders: headers,
        requestBody: requestBody,
        response: response,
        responseJsonBody: responseBody,
        responseRawBody: _stringifyResponseBody(responseBody),
      );
    }

    if (responseBody is Map) {
      final normalizedBody = Map<String, Object?>.from(responseBody);
      return _buildExchangeResult(
        tokenResponse: OAuth2TokenResponse.fromJson(normalizedBody),
        requestHeaders: headers,
        requestBody: requestBody,
        response: response,
        responseJsonBody: normalizedBody,
        responseRawBody: _stringifyResponseBody(normalizedBody),
      );
    }

    if (responseBody is String) {
      final decodedBody = jsonDecode(responseBody);
      if (decodedBody is Map) {
        final normalizedBody = Map<String, Object?>.from(decodedBody);
        return _buildExchangeResult(
          tokenResponse: OAuth2TokenResponse.fromJson(normalizedBody),
          requestHeaders: headers,
          requestBody: requestBody,
          response: response,
          responseJsonBody: normalizedBody,
          responseRawBody: responseBody,
        );
      }
    }

    throw const FormatException('Token endpoint returned non-JSON response.');
  }

  /// Executes the token request and maps transport errors into safe user-facing failures.
  Future<Response<Object?>> _postTokenRequest({
    required String accessTokenUrl,
    required Map<String, String> headers,
    required Map<String, String> requestBody,
  }) async {
    try {
      return await _dio.post<Object?>(
        accessTokenUrl,
        data: requestBody,
        options: Options(headers: headers),
      );
    } on DioException catch (error) {
      throw FormatException(_safeTokenExchangeErrorMessage(error));
    }
  }

  /// Extracts a safe error message from token exchange failures without echoing secrets.
  String _safeTokenExchangeErrorMessage(DioException error) {
    final responseData = error.response?.data;
    final serverMessage = _extractServerErrorMessage(responseData);
    if (serverMessage != null) {
      return serverMessage;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Token exchange failed with status $statusCode.';
    }

    return 'Token exchange failed.';
  }

  /// Reads OAuth-style error fields from a response payload without surfacing request data.
  String? _extractServerErrorMessage(Object? responseData) {
    if (responseData is Map<String, Object?>) {
      return _oauthErrorMessageFromMap(responseData);
    }

    if (responseData is Map) {
      return _oauthErrorMessageFromMap(Map<String, Object?>.from(responseData));
    }

    if (responseData is! String) {
      return null;
    }

    try {
      final decodedBody = jsonDecode(responseData);
      if (decodedBody is Map) {
        return _oauthErrorMessageFromMap(
          Map<String, Object?>.from(decodedBody),
        );
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  /// Combines OAuth server error fields into one concise failure string.
  String? _oauthErrorMessageFromMap(Map<String, Object?> json) {
    final error = (json['error'] as String?)?.trim() ?? '';
    final description = (json['error_description'] as String?)?.trim() ?? '';
    if (description.isNotEmpty) {
      return description;
    }

    if (error.isNotEmpty) {
      return error;
    }

    return null;
  }

  /// Builds the complete in-memory token exchange result used by the success details sheet.
  OAuth2TokenExchangeResult _buildExchangeResult({
    required OAuth2TokenResponse tokenResponse,
    required Map<String, String> requestHeaders,
    required Map<String, String> requestBody,
    required Response<Object?> response,
    required Map<String, Object?>? responseJsonBody,
    required String responseRawBody,
  }) => OAuth2TokenExchangeResult(
    token: tokenResponse,
    statusCode: response.statusCode,
    requestHeaders: Map<String, String>.unmodifiable(requestHeaders),
    requestBodyFields: Map<String, String>.unmodifiable(requestBody),
    encodedRequestBody: buildEncodedBodyPreview(requestBody),
    responseHeaders: Map<String, String>.unmodifiable(
      _flattenHeaders(response.headers),
    ),
    responseJsonBody: responseJsonBody == null
        ? null
        : Map<String, Object?>.unmodifiable(responseJsonBody),
    responseRawBody: responseRawBody,
  );

  /// Converts Dio's multi-value headers into a stable single-value map for UI rendering.
  Map<String, String> _flattenHeaders(Headers headers) => {
    for (final entry in headers.map.entries) entry.key: entry.value.join(', '),
  };

  /// Converts a response payload into a readable string without exposing it through logs.
  String _stringifyResponseBody(Object? responseBody) => switch (responseBody) {
    final String value => value,
    final Map<String, Object?> value => jsonEncode(value),
    final Map value => jsonEncode(Map<String, Object?>.from(value)),
    _ => responseBody?.toString() ?? '',
  };
}
