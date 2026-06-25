import 'package:equatable/equatable.dart';

import 'request_variable.dart';

enum RequestEnvironmentSource { local, postman }

class RequestEnvironment extends Equatable {
  const RequestEnvironment({
    required this.id,
    required this.name,
    this.variables = const <RequestVariable>[],
    this.isEnabled = true,
    this.source = RequestEnvironmentSource.local,
  });

  final String id;
  final String name;
  final List<RequestVariable> variables;
  final bool isEnabled;
  final RequestEnvironmentSource source;

  /// Returns true when the environment can participate in variable resolution.
  bool get isUsable => isEnabled && id.trim().isNotEmpty;

  /// Returns the user-facing name with a fallback for unnamed environments.
  String get displayName =>
      name.trim().isEmpty ? 'Untitled Environment' : name.trim();

  RequestEnvironment copyWith({
    String? id,
    String? name,
    List<RequestVariable>? variables,
    bool? isEnabled,
    RequestEnvironmentSource? source,
  }) => RequestEnvironment(
    id: id ?? this.id,
    name: name ?? this.name,
    variables: variables ?? this.variables,
    isEnabled: isEnabled ?? this.isEnabled,
    source: source ?? this.source,
  );

  @override
  List<Object> get props => [id, name, variables, isEnabled, source];
}
