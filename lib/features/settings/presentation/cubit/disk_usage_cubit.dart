import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/disk_usage_models.dart';
import '../../domain/services/disk_usage_service.dart';
import 'disk_usage_state.dart';

class DiskUsageCubit extends Cubit<DiskUsageState> {
  DiskUsageCubit(this._service) : super(const DiskUsageState.initial());

  final DiskUsageService _service;

  Future<void> load() async {
    emit(state.copyWith(status: DiskUsageStatus.loading, message: ''));

    try {
      final requests = await _service.loadRequestUsage();
      final files = await _service.loadFileUsage();

      emit(
        state.copyWith(
          status: DiskUsageStatus.loaded,
          requestUsages: requests,
          fileUsages: files,
          selectedRequestIds: const <String>{},
          selectedFileIds: const <String>{},
          selectionMode: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DiskUsageStatus.error,
          message: 'Unable to load disk usage.',
        ),
      );
    }
  }

  void switchTab(DiskUsageTab tab) {
    emit(
      state.copyWith(
        selectedTab: tab,
        selectedRequestIds: const <String>{},
        selectedFileIds: const <String>{},
        selectionMode: false,
      ),
    );
  }

  void toggleRequest(String requestId) {
    final selected = Set<String>.of(state.selectedRequestIds);
    selected.contains(requestId)
        ? selected.remove(requestId)
        : selected.add(requestId);
    emit(state.copyWith(selectedRequestIds: selected, selectionMode: true));
  }

  void toggleFile(String fileId) {
    final selected = Set<String>.of(state.selectedFileIds);
    selected.contains(fileId) ? selected.remove(fileId) : selected.add(fileId);
    emit(state.copyWith(selectedFileIds: selected, selectionMode: true));
  }

  void enterSelectionMode() => emit(
    state.copyWith(
      selectionMode: true,
      selectedRequestIds: const <String>{},
      selectedFileIds: const <String>{},
    ),
  );

  void selectAll() {
    if (state.selectedTab == DiskUsageTab.requests) {
      emit(
        state.copyWith(
          selectionMode: true,
          selectedRequestIds: state.requestUsages
              .map((item) => item.requestId)
              .toSet(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectionMode: true,
        selectedFileIds: state.fileUsages.map((item) => item.fileId).toSet(),
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selectedRequestIds: const <String>{},
        selectedFileIds: const <String>{},
        selectionMode: false,
      ),
    );
  }

  Future<void> deleteSelected() async {
    if (state.selectedCount == 0) {
      emit(state.copyWith(message: 'Nothing selected.'));
      return;
    }

    emit(state.copyWith(status: DiskUsageStatus.deleting, message: ''));

    try {
      if (state.selectedTab == DiskUsageTab.requests) {
        await _service.deleteRequestUsage(state.selectedRequestIds);
      } else {
        await _service.deleteFiles(state.selectedFileIds);
      }

      final selectedTab = state.selectedTab;
      final requests = await _service.loadRequestUsage();
      final files = await _service.loadFileUsage();

      emit(
        DiskUsageState(
          status: DiskUsageStatus.loaded,
          selectedTab: selectedTab,
          requestUsages: requests,
          fileUsages: files,
          selectedRequestIds: const <String>{},
          selectedFileIds: const <String>{},
          selectionMode: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DiskUsageStatus.error,
          message: 'Unable to delete selected items.',
        ),
      );
    }
  }
}
