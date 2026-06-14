import '../entities/request_test.dart';

const numericRequestTestComparators = <RequestTestComparator>[
  RequestTestComparator.isEqualTo,
  RequestTestComparator.isNotEqualTo,
  RequestTestComparator.isGreaterThan,
  RequestTestComparator.isLessThan,
  RequestTestComparator.isGreaterThanOrEqualTo,
  RequestTestComparator.isLessThanOrEqualTo,
  RequestTestComparator.isBetween,
];

const stringRequestTestComparators = <RequestTestComparator>[
  RequestTestComparator.isEqualTo,
  RequestTestComparator.isNotEqualTo,
  RequestTestComparator.contains,
  RequestTestComparator.doesNotContain,
  RequestTestComparator.beginsWith,
  RequestTestComparator.endsWith,
  RequestTestComparator.hasAnyValue,
  RequestTestComparator.doesNotHaveAnyValue,
  RequestTestComparator.exists,
  RequestTestComparator.doesNotExist,
  RequestTestComparator.matchesRegex,
  RequestTestComparator.doesNotMatchRegex,
];

const collectionRequestTestComparators = <RequestTestComparator>[
  RequestTestComparator.isEmpty,
  RequestTestComparator.isNotEmpty,
  RequestTestComparator.containsKey,
  RequestTestComparator.doesNotContainKey,
  RequestTestComparator.countIs,
];

List<RequestTestComparator> comparatorsForRequestTestType(RequestTestType type) =>
    switch (type) {
      RequestTestType.statusCode ||
      RequestTestType.responseTime ||
      RequestTestType.responseSize => numericRequestTestComparators,
      RequestTestType.headers || RequestTestType.cookies =>
        collectionRequestTestComparators,
      _ => stringRequestTestComparators,
    };
