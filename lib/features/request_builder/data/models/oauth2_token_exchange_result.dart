import 'oauth2_token_response.dart';

class OAuth2TokenExchangeResult {
  const OAuth2TokenExchangeResult({
    required this.token,
    required this.statusCode,
    required this.requestHeaders,
    required this.requestBodyFields,
    required this.encodedRequestBody,
    required this.responseHeaders,
    required this.responseJsonBody,
    required this.responseRawBody,
  });

  final OAuth2TokenResponse token;
  final int? statusCode;
  final Map<String, String> requestHeaders;
  final Map<String, String> requestBodyFields;
  final String encodedRequestBody;
  final Map<String, String> responseHeaders;
  final Map<String, Object?>? responseJsonBody;
  final String responseRawBody;
}
