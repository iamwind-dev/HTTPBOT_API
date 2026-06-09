import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/saved_credential.dart';
import '../../domain/usecases/get_saved_credentials_use_case.dart';
import '../../domain/usecases/save_saved_credentials_use_case.dart';
import 'manage_credentials_state.dart';

class ManageCredentialsCubit extends Cubit<ManageCredentialsState> {
  ManageCredentialsCubit({
    required GetSavedCredentialsUseCase getSavedCredentialsUseCase,
    required SaveSavedCredentialsUseCase saveSavedCredentialsUseCase,
  }) : _getSavedCredentialsUseCase = getSavedCredentialsUseCase,
       _saveSavedCredentialsUseCase = saveSavedCredentialsUseCase,
       super(const ManageCredentialsState());

  final GetSavedCredentialsUseCase _getSavedCredentialsUseCase;
  final SaveSavedCredentialsUseCase _saveSavedCredentialsUseCase;

  /// Loads persisted credentials into state.
  Future<void> load() async {
    emit(state.copyWith(status: ManageCredentialsStatus.loading));
    try {
      final credentials = await _getSavedCredentialsUseCase();
      emit(
        state.copyWith(
          status: ManageCredentialsStatus.ready,
          credentials: credentials,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ManageCredentialsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Appends a new API Key credential and persists the full list.
  Future<void> createApiKeyCredential(SavedCredential credential) async {
    final next = <SavedCredential>[...state.credentials, credential];
    await _persist(next);
  }

  /// Removes the credential with the given [id] and persists the result.
  Future<void> delete(String id) async {
    final next = state.credentials
        .where((credential) => credential.id != id)
        .toList(growable: false);
    await _persist(next);
  }

  /// Clears all saved credentials.
  Future<void> deleteAll() => _persist(const <SavedCredential>[]);

  Future<void> _persist(List<SavedCredential> credentials) async {
    try {
      await _saveSavedCredentialsUseCase(credentials);
      emit(
        state.copyWith(
          status: ManageCredentialsStatus.ready,
          credentials: credentials,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ManageCredentialsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
