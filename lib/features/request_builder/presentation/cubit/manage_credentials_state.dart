import 'package:equatable/equatable.dart';

import '../../domain/entities/saved_credential.dart';

enum ManageCredentialsStatus { initial, loading, ready, failure }

class ManageCredentialsState extends Equatable {
  const ManageCredentialsState({
    this.status = ManageCredentialsStatus.initial,
    this.credentials = const <SavedCredential>[],
    this.errorMessage = '',
  });

  final ManageCredentialsStatus status;
  final List<SavedCredential> credentials;
  final String errorMessage;

  ManageCredentialsState copyWith({
    ManageCredentialsStatus? status,
    List<SavedCredential>? credentials,
    String? errorMessage,
  }) => ManageCredentialsState(
    status: status ?? this.status,
    credentials: credentials ?? this.credentials,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object> get props => [status, credentials, errorMessage];
}
