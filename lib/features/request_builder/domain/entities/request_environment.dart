import 'package:equatable/equatable.dart';

import 'request_variable.dart';

class RequestEnvironment extends Equatable {
  const RequestEnvironment({
    required this.id,
    required this.name,
    this.variables = const <RequestVariable>[],
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final List<RequestVariable> variables;
  final bool isEnabled;

  /// Returns true when the environment can participate in variable resolution.
  bool get isUsable =>
      isEnabled && id.trim().isNotEmpty && name.trim().isNotEmpty;

  @override
  List<Object> get props => [id, name, variables, isEnabled];
}
