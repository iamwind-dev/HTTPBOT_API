import 'package:equatable/equatable.dart';

enum RequestTestType {
  statusCode,
  responseTime,
  responseSize,
  responseBody,
  header,
  headers,
  cookie,
  cookies,
  jsonPath,
  xPath,
}

enum RequestTestComparator {
  isEqualTo,
  isNotEqualTo,
  isGreaterThan,
  isLessThan,
  isGreaterThanOrEqualTo,
  isLessThanOrEqualTo,
  isBetween,
  contains,
  doesNotContain,
  beginsWith,
  endsWith,
  hasAnyValue,
  doesNotHaveAnyValue,
  exists,
  doesNotExist,
  matchesRegex,
  doesNotMatchRegex,
  isEmpty,
  isNotEmpty,
  containsKey,
  doesNotContainKey,
  countIs,
}

enum ResponseTimeUnit { ms, s }

enum ResponseSizeUnit { b, kb, mb }

class RequestTest extends Equatable {
  const RequestTest({
    required this.id,
    required this.type,
    required this.comparator,
    this.expectedValue,
    this.minValue,
    this.maxValue,
    this.headerName,
    this.cookieName,
    this.jsonPath,
    this.xPath,
    this.timeUnit,
    this.sizeUnit,
    this.caseSensitive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final RequestTestType type;
  final RequestTestComparator comparator;
  final String? expectedValue;
  final String? minValue;
  final String? maxValue;
  final String? headerName;
  final String? cookieName;
  final String? jsonPath;
  final String? xPath;
  final ResponseTimeUnit? timeUnit;
  final ResponseSizeUnit? sizeUnit;
  final bool caseSensitive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RequestTest copyWith({
    String? id,
    RequestTestType? type,
    RequestTestComparator? comparator,
    String? expectedValue,
    bool clearExpectedValue = false,
    String? minValue,
    bool clearMinValue = false,
    String? maxValue,
    bool clearMaxValue = false,
    String? headerName,
    bool clearHeaderName = false,
    String? cookieName,
    bool clearCookieName = false,
    String? jsonPath,
    bool clearJsonPath = false,
    String? xPath,
    bool clearXPath = false,
    ResponseTimeUnit? timeUnit,
    bool clearTimeUnit = false,
    ResponseSizeUnit? sizeUnit,
    bool clearSizeUnit = false,
    bool? caseSensitive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RequestTest(
    id: id ?? this.id,
    type: type ?? this.type,
    comparator: comparator ?? this.comparator,
    expectedValue: clearExpectedValue
        ? null
        : (expectedValue ?? this.expectedValue),
    minValue: clearMinValue ? null : (minValue ?? this.minValue),
    maxValue: clearMaxValue ? null : (maxValue ?? this.maxValue),
    headerName: clearHeaderName ? null : (headerName ?? this.headerName),
    cookieName: clearCookieName ? null : (cookieName ?? this.cookieName),
    jsonPath: clearJsonPath ? null : (jsonPath ?? this.jsonPath),
    xPath: clearXPath ? null : (xPath ?? this.xPath),
    timeUnit: clearTimeUnit ? null : (timeUnit ?? this.timeUnit),
    sizeUnit: clearSizeUnit ? null : (sizeUnit ?? this.sizeUnit),
    caseSensitive: caseSensitive ?? this.caseSensitive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    comparator,
    expectedValue,
    minValue,
    maxValue,
    headerName,
    cookieName,
    jsonPath,
    xPath,
    timeUnit,
    sizeUnit,
    caseSensitive,
    createdAt,
    updatedAt,
  ];
}

extension RequestTestTypePresentation on RequestTestType {
  String get label => switch (this) {
    RequestTestType.statusCode => 'Status Code',
    RequestTestType.responseTime => 'Response Time',
    RequestTestType.responseSize => 'Response Size',
    RequestTestType.responseBody => 'Response Body',
    RequestTestType.header => 'Header',
    RequestTestType.headers => 'Headers',
    RequestTestType.cookie => 'Cookie',
    RequestTestType.cookies => 'Cookies',
    RequestTestType.jsonPath => 'JSON Path',
    RequestTestType.xPath => 'XPath',
  };
}

extension RequestTestComparatorPresentation on RequestTestComparator {
  String get label => switch (this) {
    RequestTestComparator.isEqualTo => 'is',
    RequestTestComparator.isNotEqualTo => 'is not',
    RequestTestComparator.isGreaterThan => 'is greater than',
    RequestTestComparator.isLessThan => 'is less than',
    RequestTestComparator.isGreaterThanOrEqualTo =>
      'is greater than or equal to',
    RequestTestComparator.isLessThanOrEqualTo => 'is less than or equal to',
    RequestTestComparator.isBetween => 'is between',
    RequestTestComparator.contains => 'contains',
    RequestTestComparator.doesNotContain => 'does not contain',
    RequestTestComparator.beginsWith => 'begins with',
    RequestTestComparator.endsWith => 'ends with',
    RequestTestComparator.hasAnyValue => 'has any value',
    RequestTestComparator.doesNotHaveAnyValue => 'does not have any value',
    RequestTestComparator.exists => 'exists',
    RequestTestComparator.doesNotExist => 'does not exist',
    RequestTestComparator.matchesRegex => 'matches regex',
    RequestTestComparator.doesNotMatchRegex => 'does not match regex',
    RequestTestComparator.isEmpty => 'is empty',
    RequestTestComparator.isNotEmpty => 'is not empty',
    RequestTestComparator.containsKey => 'contains key',
    RequestTestComparator.doesNotContainKey => 'does not contain key',
    RequestTestComparator.countIs => 'count is',
  };

  bool get needsExpectedValue => !{
    RequestTestComparator.hasAnyValue,
    RequestTestComparator.doesNotHaveAnyValue,
    RequestTestComparator.exists,
    RequestTestComparator.doesNotExist,
    RequestTestComparator.isEmpty,
    RequestTestComparator.isNotEmpty,
  }.contains(this);

  bool get needsRangeValues => this == RequestTestComparator.isBetween;
}

extension ResponseTimeUnitPresentation on ResponseTimeUnit {
  String get label => switch (this) {
    ResponseTimeUnit.ms => 'ms',
    ResponseTimeUnit.s => 's',
  };
}

extension ResponseSizeUnitPresentation on ResponseSizeUnit {
  String get label => switch (this) {
    ResponseSizeUnit.b => 'B',
    ResponseSizeUnit.kb => 'KB',
    ResponseSizeUnit.mb => 'MB',
  };
}
