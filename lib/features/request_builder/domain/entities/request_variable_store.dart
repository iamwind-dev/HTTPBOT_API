import 'package:equatable/equatable.dart';

import 'request_environment.dart';
import 'request_variable.dart';

class RequestVariableStore extends Equatable {
  const RequestVariableStore({
    this.globalVariables = const <RequestVariable>[],
    this.environments = const <RequestEnvironment>[],
    this.selectedEnvironmentId = '',
  });

  final List<RequestVariable> globalVariables;
  final List<RequestEnvironment> environments;
  final String selectedEnvironmentId;

  /// Returns the selected environment when the persisted id matches an environment entry.
  RequestEnvironment? get selectedEnvironment {
    for (final environment in environments) {
      if (environment.id == selectedEnvironmentId) {
        return environment;
      }
    }

    return null;
  }

  /// Returns true when an environment is actively selected for resolution.
  bool get hasSelectedEnvironment => selectedEnvironment != null;

  @override
  List<Object> get props => [
    globalVariables,
    environments,
    selectedEnvironmentId,
  ];
}
