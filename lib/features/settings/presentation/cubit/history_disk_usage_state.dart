import 'package:equatable/equatable.dart';

import '../../domain/entities/disk_usage_models.dart';

enum HistoryDiskUsageStatus { initial, loading, loaded, deleting, error }

class HistoryDiskUsageState extends Equatable {
  const HistoryDiskUsageState({
    required this.status,
    required this.histories,
    required this.selectedHistoryIds,
    required this.selectionMode,
    this.message = '',
  });

  const HistoryDiskUsageState.initial()
    : status = HistoryDiskUsageStatus.initial,
      histories = const <DiskUsageHistoryItem>[],
      selectedHistoryIds = const <String>{},
      selectionMode = false,
      message = '';

  final HistoryDiskUsageStatus status;
  final List<DiskUsageHistoryItem> histories;
  final Set<String> selectedHistoryIds;
  final bool selectionMode;
  final String message;
  int get selectedCount => selectedHistoryIds.length;
  int get selectedBytes => histories
      .where((item) => selectedHistoryIds.contains(item.historyId))
      .fold<int>(0, (total, item) => total + item.totalBytes);

  HistoryDiskUsageState copyWith({
    HistoryDiskUsageStatus? status,
    List<DiskUsageHistoryItem>? histories,
    Set<String>? selectedHistoryIds,
    bool? selectionMode,
    String? message,
  }) => HistoryDiskUsageState(
    status: status ?? this.status,
    histories: histories ?? this.histories,
    selectedHistoryIds: selectedHistoryIds ?? this.selectedHistoryIds,
    selectionMode: selectionMode ?? this.selectionMode,
    message: message ?? this.message,
  );

  @override
  List<Object> get props => [
    status,
    histories,
    selectedHistoryIds,
    selectionMode,
    message,
  ];
}
