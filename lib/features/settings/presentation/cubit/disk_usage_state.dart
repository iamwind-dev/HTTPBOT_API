import 'package:equatable/equatable.dart';

import '../../domain/entities/disk_usage_models.dart';

enum DiskUsageStatus { initial, loading, loaded, deleting, error }

class DiskUsageState extends Equatable {
  const DiskUsageState({
    required this.status,
    required this.selectedTab,
    required this.requestUsages,
    required this.fileUsages,
    required this.selectedRequestIds,
    required this.selectedFileIds,
    required this.selectionMode,
    this.message = '',
  });

  const DiskUsageState.initial()
    : status = DiskUsageStatus.initial,
      selectedTab = DiskUsageTab.requests,
      requestUsages = const <DiskUsageRequestItem>[],
      fileUsages = const <DiskUsageFileItem>[],
      selectedRequestIds = const <String>{},
      selectedFileIds = const <String>{},
      selectionMode = false,
      message = '';

  final DiskUsageStatus status;
  final DiskUsageTab selectedTab;
  final List<DiskUsageRequestItem> requestUsages;
  final List<DiskUsageFileItem> fileUsages;
  final Set<String> selectedRequestIds;
  final Set<String> selectedFileIds;
  final bool selectionMode;
  final String message;

  Set<String> get selectedIds => selectedTab == DiskUsageTab.requests
      ? selectedRequestIds
      : selectedFileIds;

  int get selectedCount => selectedIds.length;

  int get selectedBytes {
    if (selectedTab == DiskUsageTab.requests) {
      return requestUsages
          .where((item) => selectedRequestIds.contains(item.requestId))
          .fold<int>(0, (total, item) => total + item.totalBytes);
    }

    return fileUsages
        .where((item) => selectedFileIds.contains(item.fileId))
        .fold<int>(0, (total, item) => total + item.totalBytes);
  }

  int get visibleCount => selectedTab == DiskUsageTab.requests
      ? requestUsages.length
      : fileUsages.length;

  int get visibleBytes {
    if (selectedTab == DiskUsageTab.requests) {
      return requestUsages.fold<int>(
        0,
        (total, item) => total + item.totalBytes,
      );
    }

    return fileUsages.fold<int>(0, (total, item) => total + item.totalBytes);
  }

  DiskUsageState copyWith({
    DiskUsageStatus? status,
    DiskUsageTab? selectedTab,
    List<DiskUsageRequestItem>? requestUsages,
    List<DiskUsageFileItem>? fileUsages,
    Set<String>? selectedRequestIds,
    Set<String>? selectedFileIds,
    bool? selectionMode,
    String? message,
  }) => DiskUsageState(
    status: status ?? this.status,
    selectedTab: selectedTab ?? this.selectedTab,
    requestUsages: requestUsages ?? this.requestUsages,
    fileUsages: fileUsages ?? this.fileUsages,
    selectedRequestIds: selectedRequestIds ?? this.selectedRequestIds,
    selectedFileIds: selectedFileIds ?? this.selectedFileIds,
    selectionMode: selectionMode ?? this.selectionMode,
    message: message ?? this.message,
  );

  @override
  List<Object> get props => [
    status,
    selectedTab,
    requestUsages,
    fileUsages,
    selectedRequestIds,
    selectedFileIds,
    selectionMode,
    message,
  ];
}
