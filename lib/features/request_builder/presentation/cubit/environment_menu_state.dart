import 'package:equatable/equatable.dart';

import '../../domain/entities/request_environment.dart';
import '../../domain/entities/request_variable_store.dart';

enum EnvironmentMenuStatus { initial, loading, ready, failure }

class EnvironmentMenuState extends Equatable {
  const EnvironmentMenuState({
    this.status = EnvironmentMenuStatus.initial,
    this.store = const RequestVariableStore(),
  });

  final EnvironmentMenuStatus status;
  final RequestVariableStore store;

  /// Environments created locally in the app.
  List<RequestEnvironment> get localEnvironments => store.environments
      .where((environment) => environment.source == RequestEnvironmentSource.local)
      .toList(growable: false);

  /// Environments imported or synced from Postman.
  List<RequestEnvironment> get postmanEnvironments => store.environments
      .where(
        (environment) => environment.source == RequestEnvironmentSource.postman,
      )
      .toList(growable: false);

  /// The environment currently applied to the request, if any.
  RequestEnvironment? get selectedEnvironment => store.selectedEnvironment;

  EnvironmentMenuState copyWith({
    EnvironmentMenuStatus? status,
    RequestVariableStore? store,
  }) => EnvironmentMenuState(
    status: status ?? this.status,
    store: store ?? this.store,
  );

  @override
  List<Object> get props => [status, store];
}
