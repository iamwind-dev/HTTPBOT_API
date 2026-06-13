import '../../domain/entities/request_test.dart';

class RequestTestModel {
  const RequestTestModel({
    required this.id,
    required this.type,
    required this.comparator,
    required this.expectedValue,
    required this.minValue,
    required this.maxValue,
    required this.headerName,
    required this.cookieName,
    required this.jsonPath,
    required this.xPath,
    required this.timeUnit,
    required this.sizeUnit,
    required this.caseSensitive,
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

  factory RequestTestModel.fromEntity(RequestTest entity) => RequestTestModel(
    id: entity.id,
    type: entity.type,
    comparator: entity.comparator,
    expectedValue: entity.expectedValue,
    minValue: entity.minValue,
    maxValue: entity.maxValue,
    headerName: entity.headerName,
    cookieName: entity.cookieName,
    jsonPath: entity.jsonPath,
    xPath: entity.xPath,
    timeUnit: entity.timeUnit,
    sizeUnit: entity.sizeUnit,
    caseSensitive: entity.caseSensitive,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
  );

  factory RequestTestModel.fromJson(Map<String, dynamic> json) =>
      RequestTestModel(
        id: (json['id'] as String? ?? '').trim(),
        type: _enumValueOrFallback(
          RequestTestType.values,
          json['type'] as String?,
          RequestTestType.statusCode,
        ),
        comparator: _enumValueOrFallback(
          RequestTestComparator.values,
          json['comparator'] as String?,
          RequestTestComparator.isEqualTo,
        ),
        expectedValue: _normalizeNullableString(json['expectedValue'] as String?),
        minValue: _normalizeNullableString(json['minValue'] as String?),
        maxValue: _normalizeNullableString(json['maxValue'] as String?),
        headerName: _normalizeNullableString(json['headerName'] as String?),
        cookieName: _normalizeNullableString(json['cookieName'] as String?),
        jsonPath: _normalizeNullableString(json['jsonPath'] as String?),
        xPath: _normalizeNullableString(json['xPath'] as String?),
        timeUnit: _enumValueOrNull(
          ResponseTimeUnit.values,
          json['timeUnit'] as String?,
        ),
        sizeUnit: _enumValueOrNull(
          ResponseSizeUnit.values,
          json['sizeUnit'] as String?,
        ),
        caseSensitive: json['caseSensitive'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  RequestTest toEntity() => RequestTest(
    id: id,
    type: type,
    comparator: comparator,
    expectedValue: expectedValue,
    minValue: minValue,
    maxValue: maxValue,
    headerName: headerName,
    cookieName: cookieName,
    jsonPath: jsonPath,
    xPath: xPath,
    timeUnit: timeUnit,
    sizeUnit: sizeUnit,
    caseSensitive: caseSensitive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'comparator': comparator.name,
    'expectedValue': expectedValue,
    'minValue': minValue,
    'maxValue': maxValue,
    'headerName': headerName,
    'cookieName': cookieName,
    'jsonPath': jsonPath,
    'xPath': xPath,
    'timeUnit': timeUnit?.name,
    'sizeUnit': sizeUnit?.name,
    'caseSensitive': caseSensitive,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static T _enumValueOrFallback<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }

  static T? _enumValueOrNull<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return null;
  }

  static String? _normalizeNullableString(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
