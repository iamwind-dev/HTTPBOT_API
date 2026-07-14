import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/disk_usage_service.dart';
import 'history_disk_usage_state.dart';

class HistoryDiskUsageCubit extends Cubit<HistoryDiskUsageState> {
  HistoryDiskUsageCubit({
    required DiskUsageService service,
    required String requestId,
  }) : _service = service,
       _requestId = requestId,
       super(const HistoryDiskUsageState.initial());

  final DiskUsageService _service;
  final String _requestId;

  Future<void> load() async {
    emit(state.copyWith(status: HistoryDiskUsageStatus.loading, message: ''));

    try {
      final histories = await _service.loadHistoryUsage(_requestId);
      emit(
        state.copyWith(
          status: HistoryDiskUsageStatus.loaded,
          histories: histories,
          selectedHistoryIds: const <String>{},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HistoryDiskUsageStatus.error,
          message: 'Unable to load disk usage.',
        ),
      );
    }
  }

  void toggleHistory(String historyId) {
    final selected = Set<String>.of(state.selectedHistoryIds);
    selected.contains(historyId)
        ? selected.remove(historyId)
        : selected.add(historyId);
    emit(state.copyWith(selectedHistoryIds: selected));
  }

  void selectAll() {
    emit(
      state.copyWith(
        selectedHistoryIds: state.histories
            .map((item) => item.historyId)
            .toSet(),
      ),
    );
  }

  void clearSelection() {
    emit(state.copyWith(selectedHistoryIds: const <String>{}));
  }

  Future<void> deleteSelected() async {
    if (state.selectedCount == 0) {
      emit(state.copyWith(message: 'Nothing selected.'));
      return;
    }

    emit(state.copyWith(status: HistoryDiskUsageStatus.deleting, message: ''));

    try {
      await _service.deleteHistories(state.selectedHistoryIds);
      final histories = await _service.loadHistoryUsage(_requestId);
      emit(
        state.copyWith(
          status: HistoryDiskUsageStatus.loaded,
          histories: histories,
          selectedHistoryIds: const <String>{},
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HistoryDiskUsageStatus.error,
          message: 'Unable to delete selected items.',
        ),
      );
    }
  }
}
