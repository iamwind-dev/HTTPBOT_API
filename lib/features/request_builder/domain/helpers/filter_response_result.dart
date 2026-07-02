import 'package:equatable/equatable.dart';

/// The outcome of running a Filter Response query against the response body.
class FilterResponseResult extends Equatable {
  const FilterResponseResult({
    required this.displayText,
    this.rawValue,
    this.errorMessage,
  });

  /// Pretty-printed text shown in the result viewer.
  final String displayText;

  /// Decoded value the query produced, for downstream consumers (e.g. copy).
  final Object? rawValue;

  /// Human-readable error, or null when the query succeeded.
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  @override
  List<Object?> get props => [displayText, rawValue, errorMessage];
}
