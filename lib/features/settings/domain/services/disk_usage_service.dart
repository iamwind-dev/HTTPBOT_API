import 'dart:convert';

import '../../../request_history/domain/entities/request_history_entry.dart';
import '../../../request_history/domain/repositories/request_history_repository.dart';
import '../entities/disk_usage_models.dart';

class DiskUsageService {
  const DiskUsageService(this._historyRepository);

  final RequestHistoryRepository _historyRepository;

  Future<List<DiskUsageRequestItem>> loadRequestUsage() async {
    final entries = await _historyRepository.getRequestHistoryEntries();
    final grouped = <String, List<RequestHistoryEntry>>{};

    for (final entry in entries) {
      grouped
          .putIfAbsent(requestKey(entry), () => <RequestHistoryEntry>[])
          .add(entry);
    }

    final items =
        grouped.entries.map((group) {
          final histories = group.value;
          final latest = histories
              .map((entry) => entry.sentAt)
              .reduce((left, right) => left.isAfter(right) ? left : right);
          final first = histories.first;

          return DiskUsageRequestItem(
            requestId: group.key,
            title: 'Untitled Request',
            url: first.request.url,
            responseCount: histories.length,
            totalBytes: histories.fold<int>(
              0,
              (total, entry) => total + historySizeBytes(entry),
            ),
            latestHistoryAt: latest,
          );
        }).toList()..sort((left, right) {
          final sizeOrder = right.totalBytes.compareTo(left.totalBytes);
          if (sizeOrder != 0) {
            return sizeOrder;
          }

          return right.latestHistoryAt.compareTo(left.latestHistoryAt);
        });

    return items;
  }

  Future<List<DiskUsageHistoryItem>> loadHistoryUsage(String requestId) async {
    final entries = await _historyRepository.getRequestHistoryEntries();
    final histories =
        entries
            .where((entry) => requestKey(entry) == requestId)
            .map(
              (entry) => DiskUsageHistoryItem(
                historyId: entry.id,
                requestId: requestId,
                createdAt: entry.sentAt,
                totalBytes: historySizeBytes(entry),
              ),
            )
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return histories;
  }

  Future<List<DiskUsageFileItem>> loadFileUsage() async =>
      const <DiskUsageFileItem>[];

  Future<void> deleteRequestUsage(Set<String> requestIds) async {
    for (final requestId in requestIds) {
      await _historyRepository.deleteRequestHistoryForRequest(requestId);
    }
  }

  Future<void> deleteHistories(Set<String> historyIds) =>
      _historyRepository.deleteRequestHistoryEntries(historyIds);

  Future<void> deleteFiles(Set<String> fileIds) async {}

  static String requestKey(RequestHistoryEntry entry) =>
      '${entry.request.method.wireName}|${entry.request.url}';

  static int historySizeBytes(RequestHistoryEntry entry) {
    final response = entry.response;
    final textBytes = utf8
        .encode(
          [
            response.statusCode?.toString() ?? '',
            response.statusMessage,
            response.errorType?.name ?? '',
            response.errorMessage,
            response.contentType,
            response.rawBody,
            response.formattedBody,
            for (final header in response.headers)
              '${header.key}:${header.value}',
          ].join('\n'),
        )
        .length;

    return response.payloadSizeBytes > textBytes
        ? response.payloadSizeBytes
        : textBytes;
  }
}
