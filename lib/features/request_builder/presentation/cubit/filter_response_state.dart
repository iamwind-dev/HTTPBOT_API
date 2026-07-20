import 'package:equatable/equatable.dart';

import '../../domain/helpers/filter_response_mode.dart';

class FilterResponseState extends Equatable {
  const FilterResponseState({
    required this.mode,
    required this.query,
    required this.displayText,
    this.errorMessage,
  });

  final FilterResponseMode mode;
  final String query;
  final String displayText;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  FilterResponseState copyWith({
    FilterResponseMode? mode,
    String? query,
    String? displayText,
    String? errorMessage,
    bool clearError = false,
  }) => FilterResponseState(
    mode: mode ?? this.mode,
    query: query ?? this.query,
    displayText: displayText ?? this.displayText,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [mode, query, displayText, errorMessage];
}
