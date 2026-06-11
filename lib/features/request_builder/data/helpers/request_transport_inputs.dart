import '../mappers/request_body_mapper.dart';
import '../mappers/request_headers_mapper.dart';
import '../../domain/entities/request_draft.dart';
import '../../domain/entities/request_key_value.dart';
import '../../domain/helpers/header_method_policy.dart';
import '../../domain/entities/requests_method.dart';

/// The fully prepared wire inputs for one request execution.
class RequestTransportInputs {
  const RequestTransportInputs({
    required this.url,
    required this.headers,
    required this.payload,
    required this.canSendBody,
  });

  final String url;
  final Map<String, String> headers;
  final RequestBodyPayload payload;
  final bool canSendBody;
}

/// Builds the URL, headers, and body payload shared by every transport path.
Future<RequestTransportInputs> buildRequestTransportInputs(
  RequestDraft draft,
) async {
  final canSendBody = methodSupportsRequestBody(draft.method);
  final payload = canSendBody
      ? await buildRequestBodyPayload(draft.body)
      : const RequestBodyPayload();
  final baseHeaders = buildEnabledHeaders(draft.headers);
  final canAutoAttachContentType =
      shouldAutoAttachContentTypeForMethod(draft.method) &&
      canSendBody &&
      payload.contentType != null;
  final finalHeaders = applyAutoContentTypeIfNeeded(
    headers: baseHeaders,
    contentType: payload.contentType,
    canAutoAttachContentType: canAutoAttachContentType,
  );

  return RequestTransportInputs(
    url: buildExecutionUrl(draft.url, draft.queryParameters),
    headers: Map<String, String>.from(finalHeaders),
    payload: payload,
    canSendBody: canSendBody,
  );
}

/// Builds the exact URL string sent to the server while preserving duplicate keys.
String buildExecutionUrl(String baseUrl, List<KeyValueItem> queryParameters) {
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
    final separator =
        baseUrl.endsWith('?') || baseUrl.endsWith('&') ? '' : '&';
    return '$baseUrl$separator$suffix';
  }

  return '$baseUrl?$suffix';
}
