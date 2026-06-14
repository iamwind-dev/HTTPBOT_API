import '../entities/request_test.dart';

String buildRequestTestLabel(RequestTest test) {
  final comparator = test.comparator.label;

  switch (test.type) {
    case RequestTestType.statusCode:
      return _numericLabel('Status Code', comparator, test);
    case RequestTestType.responseTime:
      return _numericLabel(
        'Response Time',
        comparator,
        test,
        suffix: test.timeUnit?.label ?? 'ms',
      );
    case RequestTestType.responseSize:
      return _numericLabel(
        'Response Size',
        comparator,
        test,
        suffix: test.sizeUnit?.label ?? 'B',
      );
    case RequestTestType.responseBody:
      return _stringLabel('Response Body', comparator, test);
    case RequestTestType.header:
      return _stringLabel(
        'Header (${test.headerName?.trim().isEmpty ?? true ? '?' : test.headerName!.trim()})',
        comparator,
        test,
      );
    case RequestTestType.headers:
      return _collectionLabel('Headers', comparator, test, test.headerName);
    case RequestTestType.cookie:
      return _stringLabel(
        'Cookie (${test.cookieName?.trim().isEmpty ?? true ? '?' : test.cookieName!.trim()})',
        comparator,
        test,
      );
    case RequestTestType.cookies:
      return _collectionLabel('Cookies', comparator, test, test.cookieName);
    case RequestTestType.jsonPath:
      return _stringLabel(
        'JSON Path ${test.jsonPath?.trim().isEmpty ?? true ? '?' : test.jsonPath!.trim()}',
        comparator,
        test,
      );
    case RequestTestType.xPath:
      return _stringLabel(
        'XPath ${test.xPath?.trim().isEmpty ?? true ? '?' : test.xPath!.trim()}',
        comparator,
        test,
      );
  }
}

String _collectionLabel(
  String title,
  String comparator,
  RequestTest test,
  String? keyName,
) {
  return switch (test.comparator) {
    RequestTestComparator.containsKey ||
    RequestTestComparator.doesNotContainKey =>
      '$title $comparator ${keyName?.trim() ?? ''}'.trim(),
    RequestTestComparator.countIs =>
      '$title $comparator ${test.expectedValue?.trim() ?? ''}'.trim(),
    _ => '$title $comparator',
  };
}

String _numericLabel(
  String title,
  String comparator,
  RequestTest test, {
  String suffix = '',
}) {
  if (test.comparator == RequestTestComparator.isBetween) {
    final minValue = test.minValue?.trim() ?? '';
    final maxValue = test.maxValue?.trim() ?? '';
    final unit = suffix.isEmpty ? '' : suffix;
    return '$title $comparator $minValue$unit and $maxValue$unit'.trim();
  }

  final expectedValue = test.expectedValue?.trim() ?? '';
  final unit = suffix.isEmpty ? '' : suffix;
  return '$title $comparator $expectedValue$unit'.trim();
}

String _stringLabel(String title, String comparator, RequestTest test) {
  if (!test.comparator.needsExpectedValue ||
      test.comparator == RequestTestComparator.isBetween) {
    return '$title $comparator';
  }

  return '$title $comparator ${test.expectedValue?.trim() ?? ''}'.trim();
}
