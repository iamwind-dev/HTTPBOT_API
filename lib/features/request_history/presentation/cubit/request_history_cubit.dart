import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/request_history_entry.dart';
import '../../domain/usecases/clear_request_history_use_case.dart';
import '../../domain/usecases/get_request_history_entries_use_case.dart';
import 'request_history_state.dart';

class RequestHistoryCubit extends Cubit<RequestHistoryState> {
  RequestHistoryCubit(
    this._getRequestHistoryEntriesUseCase,
    this._clearRequestHistoryUseCase,
  ) : super(const RequestHistoryState.initial());

  final GetRequestHistoryEntriesUseCase _getRequestHistoryEntriesUseCase;
  final ClearRequestHistoryUseCase _clearRequestHistoryUseCase;

  /// Loads the saved request history entries for future list-based presentation.
  Future<void> load() async {
    emit(state.copyWith(status: RequestHistoryStatus.loading));
    final entries = await _getRequestHistoryEntriesUseCase();

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        status: RequestHistoryStatus.ready,
        entries: entries,
      ),
    );
  }

  /// Clears history storage and updates the presentation state to an empty ready list.
  Future<void> clear() async {
    await _clearRequestHistoryUseCase();

    if (isClosed) {
      return;
    }

    emit(
      state.copyWith(
        status: RequestHistoryStatus.ready,
        entries: const <RequestHistoryEntry>[],
      ),
    );
  }
}
