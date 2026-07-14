import 'package:equatable/equatable.dart';

import '../../domain/entities/disk_usage_models.dart';

enum HistoryDiskUsageStatus { initial, loading, loaded, deleting, error }

class HistoryDiskUsageState extends Equatable {
  const HistoryDiskUsageState({
    required this.status,
    required this.histories,
    required this.selectedHistoryIds,
    this.message = '',
  });

  const HistoryDiskUsageState.initial()
    : status = HistoryDiskUsageStatus.initial,
      histories = const <DiskUsageHistoryItem>[],
      selectedHistoryIds = const <String>{},
      message = '';

  final HistoryDiskUsageStatus status;
  final List<DiskUsageHistoryItem> histories;
  final Set<String> selectedHistoryIds;
  final String message;

  bool get selectionMode => selectedHistoryIds.isNotEmpty;
  int get selectedCount => selectedHistoryIds.length;
  int get selectedBytes => histories
      .where((item) => selectedHistoryIds.contains(item.historyId))
      .fold<int>(0, (total, item) => total + item.totalBytes);

  HistoryDiskUsageState copyWith({
    HistoryDiskUsageStatus? status,
    List<DiskUsageHistoryItem>? histories,
    Set<String>? selectedHistoryIds,
    String? message,
  }) => HistoryDiskUsageState(
    status: status ?? this.status,
    histories: histories ?? this.histories,
    selectedHistoryIds: selectedHistoryIds ?? this.selectedHistoryIds,
    message: message ?? this.message,
  );

  @override
  List<Object> get props => [status, histories, selectedHistoryIds, message];
}
