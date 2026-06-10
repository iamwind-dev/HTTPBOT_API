import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/request_body_draft.dart';
import '../../domain/entities/request_key_value.dart';

class RequestBodyPayload {
  const RequestBodyPayload({this.data, this.contentType});

  final dynamic data;
  final String? contentType;
}

Future<RequestBodyPayload> buildRequestBodyPayload(
  RequestBodyDraft body,
) async {
  switch (body.type) {
    case RequestBodyType.none:
      return const RequestBodyPayload();
    case RequestBodyType.xWwwFormUrlEncoded:
      return RequestBodyPayload(
        data: buildUrlEncodedBody(body),
        contentType: Headers.formUrlEncodedContentType,
      );
    case RequestBodyType.formData:
      return RequestBodyPayload(
        data: await buildFormDataBody(body),
        contentType: 'multipart/form-data',
      );
    case RequestBodyType.raw:
      return RequestBodyPayload(
        data: buildRawBody(body),
        contentType: body.raw.syncedContentType,
      );
    case RequestBodyType.graphql:
      return RequestBodyPayload(
        data: buildGraphQLBody(body),
        contentType: Headers.jsonContentType,
      );
  }
}

Map<String, dynamic> buildUrlEncodedBody(RequestBodyDraft body) {
  final data = <String, dynamic>{};

  for (final item in body.urlEncoded.where(
    (item) => item.isEnabled && item.hasKey,
  )) {
    data[item.key] = item.value;
  }

  return data;
}

Future<FormData> buildFormDataBody(RequestBodyDraft body) async {
  final formData = FormData();

  for (final item in body.formData.where(
    (item) => item.isEnabled && item.hasKey,
  )) {
    if (item.type == KeyValueItemType.file) {
      final filePath = item.value.trim();
      if (filePath.isEmpty) {
        continue;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        continue;
      }

      formData.files.add(
        MapEntry(
          item.key,
          await MultipartFile.fromFile(
            file.path,
            filename: file.uri.pathSegments.isEmpty
                ? null
                : file.uri.pathSegments.last,
            contentType: item.contentType.trim().isEmpty
                ? null
                : DioMediaType.parse(item.contentType),
          ),
        ),
      );
      continue;
    }

    formData.fields.add(MapEntry(item.key, item.value));
  }

  return formData;
}

dynamic buildRawBody(RequestBodyDraft body) {
  final trimmed = body.raw.content.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return body.raw.content;
}

Map<String, dynamic> buildGraphQLBody(RequestBodyDraft body) =>
    <String, dynamic>{
      'query': body.graphQl.query,
      'variables': _parseGraphQlVariables(body.graphQl.variables),
    };

Map<String, dynamic> _parseGraphQlVariables(String variables) {
  final trimmed = variables.trim();
  if (trimmed.isEmpty) {
    return <String, dynamic>{};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException {
    throw const FormatException(
      'GraphQL variables must be a valid JSON object',
    );
  }

  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }

  throw const FormatException('GraphQL variables must be a valid JSON object');
}
