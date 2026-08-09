import 'dart:convert';

import '../../request_builder/domain/entities/executed_request_snapshot.dart';
import '../../request_builder/domain/entities/http_cookie_entity.dart';
import '../../request_builder/domain/entities/http_exchange.dart';
import '../../request_builder/domain/entities/parsed_response.dart';
import '../../request_builder/domain/entities/request_auth_draft.dart';
import '../../request_builder/domain/entities/request_auth_issue.dart';
import '../../request_builder/domain/entities/request_draft.dart';
import '../../request_builder/domain/entities/request_execution_result.dart';
import '../../request_builder/domain/entities/request_key_value.dart';
import '../../request_builder/domain/entities/request_resolution_issue.dart';
import '../../request_builder/domain/entities/request_settings.dart';
import '../../request_builder/domain/entities/request_test_result.dart';
import '../../request_builder/domain/entities/requests_method.dart';
import '../domain/entities/request_history_entry.dart';
import '../domain/entities/request_history_response_snapshot.dart';

const requestHistoryStorageVersion = 1;

/// Serializes the persisted portion of a history entry without exposing JSON
/// concerns to the request-history domain layer.
Map<String, Object?> requestHistoryEntryToJson(RequestHistoryEntry entry) => {
  'schemaVersion': requestHistoryStorageVersion,
  'id': entry.id,
  'sentAt': entry.sentAt.toIso8601String(),
  'request': _requestToJson(entry.request),
  'response': _responseSnapshotToJson(entry.response),
  'execution': _executionToJson(entry.executionResult),
  'parsed': _parsedResponseToJson(entry.parsedResponse),
};

/// Restores one history entry and lets the repository skip malformed records.
RequestHistoryEntry requestHistoryEntryFromJson(Map<String, dynamic> json) {
  final id = _stringValue(json['id']);
  final sentAt = DateTime.tryParse(_stringValue(json['sentAt']));
  if (id.trim().isEmpty || sentAt == null) {
    throw const FormatException('Invalid request history entry.');
  }

  final request = _requestFromJson(_mapFromJson(json['request']));
  final execution = _executionFromJson(
    _mapFromJson(json['execution']),
    fallbackRequest: request,
  );
  final parsedResponse = _parsedResponseFromJson(
    _mapFromJson(json['parsed']),
    execution: execution,
  );

  return RequestHistoryEntry(
    id: id,
    sentAt: sentAt,
    request: request,
    response: _responseSnapshotFromJson(
      _mapFromJson(json['response']),
      execution: execution,
      parsedResponse: parsedResponse,
    ),
    executionResult: execution,
    parsedResponse: parsedResponse,
  );
}

Map<String, Object?> _requestToJson(RequestDraft request) => {
  'method': request.method.name,
  'url': request.url,
  'savedResponsesInHistory': request.settings.savedResponsesInHistory,
};

RequestDraft _requestFromJson(Map<String, dynamic> json) => RequestDraft(
  method: _enumOrFallback(HttpMethod.values, json['method'], HttpMethod.get),
  url: _stringValue(json['url']),
  settings: RequestSettings(
    savedResponsesInHistory: _intValue(json['savedResponsesInHistory']) ?? 10,
  ),
);

Map<String, Object?> _responseSnapshotToJson(
  RequestHistoryResponseSnapshot response,
) => {
  'statusCode': response.statusCode,
  'statusMessage': response.statusMessage,
  'headers': response.headers.map(_keyValueToJson).toList(growable: false),
  'payloadSizeBytes': response.payloadSizeBytes,
  'durationMicroseconds': response.duration.inMicroseconds,
  'errorType': response.errorType?.name,
  'errorMessage': response.errorMessage,
  'rawBody': response.rawBody,
  'formattedBody': response.formattedBody,
  'contentType': response.contentType,
  'bodyType': response.bodyType.name,
};

RequestHistoryResponseSnapshot _responseSnapshotFromJson(
  Map<String, dynamic> json, {
  required RequestExecutionResult execution,
  required ParsedResponse parsedResponse,
}) {
  if (json.isEmpty) {
    return RequestHistoryResponseSnapshot(
      statusCode: execution.statusCode,
      statusMessage: execution.statusMessage,
      headers: execution.headers,
      payloadSizeBytes: execution.payloadSizeBytes,
      duration: execution.duration,
      errorType: execution.errorType,
      errorMessage: execution.errorMessage,
      rawBody: execution.bodyText,
      formattedBody: parsedResponse.formattedBody,
      contentType: parsedResponse.contentType,
      bodyType: parsedResponse.bodyType,
    );
  }

  return RequestHistoryResponseSnapshot(
    statusCode: _intValue(json['statusCode']),
    statusMessage: _stringValue(json['statusMessage']),
    headers: _keyValueListFromJson(json['headers']),
    payloadSizeBytes: _intValue(json['payloadSizeBytes']) ?? 0,
    duration: _durationFromJson(json['durationMicroseconds']) ?? Duration.zero,
    errorType: _enumOrNull(RequestExecutionErrorType.values, json['errorType']),
    errorMessage: _stringValue(json['errorMessage']),
    rawBody: _stringValue(json['rawBody']),
    formattedBody: _stringValue(json['formattedBody']),
    contentType: _stringValue(json['contentType']),
    bodyType: _enumOrFallback(
      ParsedResponseBodyType.values,
      json['bodyType'],
      ParsedResponseBodyType.empty,
    ),
  );
}

Map<String, Object?> _executionToJson(RequestExecutionResult execution) {
  final executedRequestSnapshot = execution.executedRequestSnapshot;

  return {
    'request': _requestToJson(execution.request),
    'statusCode': execution.statusCode,
    'statusMessage': execution.statusMessage,
    'headers': execution.headers.map(_keyValueToJson).toList(growable: false),
    'bodyBytes': base64Encode(execution.bodyBytes),
    'bodyText': execution.bodyText,
    'durationMicroseconds': execution.duration.inMicroseconds,
    'errorType': execution.errorType?.name,
    'errorMessage': execution.errorMessage,
    'executedRequestSnapshot': executedRequestSnapshot == null
        ? null
        : _executedSnapshotToJson(executedRequestSnapshot),
    'exchanges': execution.exchanges
        .map(_exchangeToJson)
        .toList(growable: false),
    'responseCookies': execution.responseCookies
        .map(_cookieToJson)
        .toList(growable: false),
    'testResults': execution.testResults
        .map(_testResultToJson)
        .toList(growable: false),
    'resolutionIssues': execution.resolutionIssues
        .map(_resolutionIssueToJson)
        .toList(growable: false),
    'authIssues': execution.authIssues
        .map(_authIssueToJson)
        .toList(growable: false),
  };
}

RequestExecutionResult _executionFromJson(
  Map<String, dynamic> json, {
  required RequestDraft fallbackRequest,
}) {
  final requestJson = _mapFromJson(json['request']);
  final request = requestJson.isEmpty
      ? fallbackRequest
      : _requestFromJson(requestJson);

  return RequestExecutionResult(
    request: request,
    statusCode: _intValue(json['statusCode']),
    statusMessage: _stringValue(json['statusMessage']),
    headers: _keyValueListFromJson(json['headers']),
    bodyBytes: _bytesFromJson(json['bodyBytes']),
    bodyText: _stringValue(json['bodyText']),
    duration: _durationFromJson(json['durationMicroseconds']) ?? Duration.zero,
    errorType: _enumOrNull(RequestExecutionErrorType.values, json['errorType']),
    errorMessage: _stringValue(json['errorMessage']),
    executedRequestSnapshot: _nullableExecutedSnapshotFromJson(
      json['executedRequestSnapshot'],
    ),
    exchanges: _listFromJson(json['exchanges'], _exchangeFromJson),
    responseCookies: _listFromJson(json['responseCookies'], _cookieFromJson),
    testResults: _listFromJson(json['testResults'], _testResultFromJson),
    resolutionIssues: _listFromJson(
      json['resolutionIssues'],
      _resolutionIssueFromJson,
    ),
    authIssues: _listFromJson(json['authIssues'], _authIssueFromJson),
  );
}

Map<String, Object?> _parsedResponseToJson(ParsedResponse response) => {
  'bodyType': response.bodyType.name,
  'formattedBody': response.formattedBody,
  'contentType': response.contentType,
  'isPrettyPrinted': response.isPrettyPrinted,
};

ParsedResponse _parsedResponseFromJson(
  Map<String, dynamic> json, {
  required RequestExecutionResult execution,
}) => ParsedResponse(
  execution: execution,
  bodyType: _enumOrFallback(
    ParsedResponseBodyType.values,
    json['bodyType'],
    ParsedResponseBodyType.empty,
  ),
  formattedBody: _stringValue(json['formattedBody']),
  contentType: _stringValue(json['contentType']),
  isPrettyPrinted: _boolValue(json['isPrettyPrinted']) ?? false,
);

Map<String, Object?> _executedSnapshotToJson(
  ExecutedRequestSnapshot snapshot,
) => {
  'method': snapshot.method,
  'url': snapshot.url,
  'headers': snapshot.headers,
  'body': snapshot.body,
  'protocol': snapshot.protocol,
  'headerSizeBytes': snapshot.headerSizeBytes,
  'bodySizeBytes': snapshot.bodySizeBytes,
  'startAt': snapshot.startAt?.toIso8601String(),
  'endAt': snapshot.endAt?.toIso8601String(),
};

ExecutedRequestSnapshot? _nullableExecutedSnapshotFromJson(Object? value) {
  final json = _mapFromJson(value);
  return json.isEmpty ? null : _executedSnapshotFromJson(json);
}

ExecutedRequestSnapshot _executedSnapshotFromJson(Map<String, dynamic> json) =>
    ExecutedRequestSnapshot(
      method: _stringValue(json['method'], fallback: HttpMethod.get.wireName),
      url: _stringValue(json['url']),
      headers: _stringMapFromJson(json['headers']),
      body: _optionalStringValue(json['body']),
      protocol: _optionalStringValue(json['protocol']),
      headerSizeBytes: _intValue(json['headerSizeBytes']),
      bodySizeBytes: _intValue(json['bodySizeBytes']),
      startAt: _dateTimeFromJson(json['startAt']),
      endAt: _dateTimeFromJson(json['endAt']),
    );

Map<String, Object?> _exchangeToJson(HttpExchange exchange) => {
  'index': exchange.index,
  'request': _executedSnapshotToJson(exchange.request),
  'statusCode': exchange.statusCode,
  'reasonPhrase': exchange.reasonPhrase,
  'protocol': exchange.protocol,
  'remoteAddress': exchange.remoteAddress,
  'tlsProtocol': exchange.tlsProtocol,
  'tlsCipher': exchange.tlsCipher,
  'keptAlive': exchange.keptAlive,
  'responseHeaderSizeBytes': exchange.responseHeaderSizeBytes,
  'responseBodySizeBytes': exchange.responseBodySizeBytes,
  'responseStartAt': exchange.responseStartAt?.toIso8601String(),
  'responseEndAt': exchange.responseEndAt?.toIso8601String(),
  'dnsLookupDuration': _durationToJson(exchange.dnsLookupDuration),
  'connectDuration': _durationToJson(exchange.connectDuration),
  'tlsHandshakeDuration': _durationToJson(exchange.tlsHandshakeDuration),
  'requestDuration': _durationToJson(exchange.requestDuration),
  'responseDuration': _durationToJson(exchange.responseDuration),
};

HttpExchange _exchangeFromJson(Map<String, dynamic> json) => HttpExchange(
  index: _intValue(json['index']) ?? 1,
  request: _executedSnapshotFromJson(_mapFromJson(json['request'])),
  statusCode: _intValue(json['statusCode']),
  reasonPhrase: _optionalStringValue(json['reasonPhrase']),
  protocol: _optionalStringValue(json['protocol']),
  remoteAddress: _optionalStringValue(json['remoteAddress']),
  tlsProtocol: _optionalStringValue(json['tlsProtocol']),
  tlsCipher: _optionalStringValue(json['tlsCipher']),
  keptAlive: _boolValue(json['keptAlive']),
  responseHeaderSizeBytes: _intValue(json['responseHeaderSizeBytes']),
  responseBodySizeBytes: _intValue(json['responseBodySizeBytes']),
  responseStartAt: _dateTimeFromJson(json['responseStartAt']),
  responseEndAt: _dateTimeFromJson(json['responseEndAt']),
  dnsLookupDuration: _durationFromJson(json['dnsLookupDuration']),
  connectDuration: _durationFromJson(json['connectDuration']),
  tlsHandshakeDuration: _durationFromJson(json['tlsHandshakeDuration']),
  requestDuration: _durationFromJson(json['requestDuration']),
  responseDuration: _durationFromJson(json['responseDuration']),
);

Map<String, Object?> _cookieToJson(HttpCookieEntity cookie) => {
  'id': cookie.id,
  'name': cookie.name,
  'value': cookie.value,
  'domain': cookie.domain,
  'path': cookie.path,
  'expiresAt': cookie.expiresAt?.toIso8601String(),
  'secure': cookie.secure,
  'httpOnly': cookie.httpOnly,
  'sameSite': cookie.sameSite,
  'createdAt': cookie.createdAt.toIso8601String(),
  'updatedAt': cookie.updatedAt.toIso8601String(),
};

HttpCookieEntity _cookieFromJson(Map<String, dynamic> json) => HttpCookieEntity(
  id: _stringValue(json['id']),
  name: _stringValue(json['name']),
  value: _stringValue(json['value']),
  domain: _stringValue(json['domain']),
  path: _stringValue(json['path'], fallback: '/'),
  expiresAt: _dateTimeFromJson(json['expiresAt']),
  secure: _boolValue(json['secure']) ?? false,
  httpOnly: _boolValue(json['httpOnly']) ?? false,
  sameSite: _optionalStringValue(json['sameSite']),
  createdAt:
      _dateTimeFromJson(json['createdAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt:
      _dateTimeFromJson(json['updatedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0),
);

Map<String, Object?> _testResultToJson(RequestTestResult result) => {
  'testId': result.testId,
  'label': result.label,
  'status': result.status.name,
  'expected': result.expected,
  'actual': result.actual,
  'message': result.message,
};

RequestTestResult _testResultFromJson(Map<String, dynamic> json) =>
    RequestTestResult(
      testId: _stringValue(json['testId']),
      label: _stringValue(json['label']),
      status: _enumOrFallback(
        RequestTestResultStatus.values,
        json['status'],
        RequestTestResultStatus.error,
      ),
      expected: _optionalStringValue(json['expected']),
      actual: _optionalStringValue(json['actual']),
      message: _optionalStringValue(json['message']),
    );

Map<String, Object?> _resolutionIssueToJson(RequestResolutionIssue issue) => {
  'type': issue.type.name,
  'variableKey': issue.variableKey,
  'source': issue.source,
  'placeholder': issue.placeholder,
};

RequestResolutionIssue _resolutionIssueFromJson(Map<String, dynamic> json) =>
    RequestResolutionIssue(
      type: _enumOrFallback(
        RequestResolutionIssueType.values,
        json['type'],
        RequestResolutionIssueType.missingVariable,
      ),
      variableKey: _stringValue(json['variableKey']),
      source: _stringValue(json['source']),
      placeholder: _stringValue(json['placeholder']),
    );

Map<String, Object?> _authIssueToJson(RequestAuthIssue issue) => {
  'type': issue.type.name,
  'authType': issue.authType.name,
  'message': issue.message,
  'fieldName': issue.fieldName,
};

RequestAuthIssue _authIssueFromJson(Map<String, dynamic> json) =>
    RequestAuthIssue(
      type: _enumOrFallback(
        RequestAuthIssueType.values,
        json['type'],
        RequestAuthIssueType.invalidConfiguration,
      ),
      authType: _enumOrFallback(
        AuthType.values,
        json['authType'],
        AuthType.none,
      ),
      message: _stringValue(json['message']),
      fieldName: _stringValue(json['fieldName']),
    );

Map<String, Object?> _keyValueToJson(KeyValueItem item) => {
  'key': item.key,
  'value': item.value,
  'isEnabled': item.isEnabled,
  'type': item.type.name,
  'contentType': item.contentType,
  'description': item.description,
  'source': item.source.name,
  'systemTag': item.systemTag,
};

KeyValueItem _keyValueFromJson(Map<String, dynamic> json) => KeyValueItem(
  key: _stringValue(json['key']),
  value: _stringValue(json['value']),
  isEnabled: _boolValue(json['isEnabled']) ?? true,
  type: _enumOrFallback(
    KeyValueItemType.values,
    json['type'],
    KeyValueItemType.text,
  ),
  contentType: _stringValue(json['contentType']),
  description: _stringValue(json['description']),
  source: _enumOrFallback(
    RequestHeaderSource.values,
    json['source'],
    RequestHeaderSource.user,
  ),
  systemTag: _stringValue(json['systemTag']),
);

List<KeyValueItem> _keyValueListFromJson(Object? value) =>
    _listFromJson(value, _keyValueFromJson);

List<T> _listFromJson<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) {
    return <T>[];
  }

  return value
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

Map<String, dynamic> _mapFromJson(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

Map<String, String> _stringMapFromJson(Object? value) {
  final map = _mapFromJson(value);
  return Map<String, String>.fromEntries(
    map.entries
        .where((entry) => entry.value is String)
        .map(
          (entry) => MapEntry<String, String>(entry.key, entry.value as String),
        ),
  );
}

List<int> _bytesFromJson(Object? value) {
  if (value is String) {
    try {
      return base64Decode(value);
    } on FormatException {
      return const <int>[];
    }
  }

  if (value is List) {
    return value.whereType<num>().map((item) => item.toInt()).toList();
  }

  return const <int>[];
}

String _stringValue(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

String? _optionalStringValue(Object? value) => value is String ? value : null;

int? _intValue(Object? value) => value is num ? value.toInt() : null;

bool? _boolValue(Object? value) => value is bool ? value : null;

DateTime? _dateTimeFromJson(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

int? _durationToJson(Duration? duration) => duration?.inMicroseconds;

Duration? _durationFromJson(Object? value) {
  final microseconds = _intValue(value);
  return microseconds == null ? null : Duration(microseconds: microseconds);
}

T _enumOrFallback<T extends Enum>(
  Iterable<T> values,
  Object? value,
  T fallback,
) {
  final name = value is String ? value : null;
  for (final candidate in values) {
    if (candidate.name == name) {
      return candidate;
    }
  }
  return fallback;
}

T? _enumOrNull<T extends Enum>(Iterable<T> values, Object? value) {
  final name = value is String ? value : null;
  for (final candidate in values) {
    if (candidate.name == name) {
      return candidate;
    }
  }
  return null;
}
