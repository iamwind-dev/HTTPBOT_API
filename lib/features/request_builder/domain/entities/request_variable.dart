import 'package:equatable/equatable.dart';

enum RequestVariableScope { request, global, environment }

class RequestVariable extends Equatable {
  const RequestVariable({
    required this.key,
    this.currentValue = '',
    this.initialValue = '',
    this.scope = RequestVariableScope.request,
    this.isEnabled = true,
    this.isSecret = false,
    this.description = '',
  });

  final String key;
  final String currentValue;
  final String initialValue;
  final RequestVariableScope scope;
  final bool isEnabled;
  final bool isSecret;
  final String description;

  /// Returns true when the variable key has meaningful user input.
  bool get hasKey => key.trim().isNotEmpty;

  /// Returns true when the variable has either a current or fallback initial value.
  bool get hasValue =>
      currentValue.trim().isNotEmpty || initialValue.trim().isNotEmpty;

  /// Returns the value that should be used by the resolver before substitution.
  String get effectiveValue =>
      currentValue.trim().isNotEmpty ? currentValue : initialValue;

  @override
  List<Object> get props => [
    key,
    currentValue,
    initialValue,
    scope,
    isEnabled,
    isSecret,
    description,
  ];
}
