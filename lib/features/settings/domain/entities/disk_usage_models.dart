import 'package:equatable/equatable.dart';

enum DiskUsageTab { requests, files }

enum DiskUsageFileType { uploaded, downloadedResponse, responseFile }

class DiskUsageRequestItem extends Equatable {
  const DiskUsageRequestItem({
    required this.requestId,
    required this.title,
    required this.url,
    required this.responseCount,
    required this.totalBytes,
    required this.latestHistoryAt,
  });

  final String requestId;
  final String title;
  final String url;
  final int responseCount;
  final int totalBytes;
  final DateTime latestHistoryAt;

  @override
  List<Object> get props => [
    requestId,
    title,
    url,
    responseCount,
    totalBytes,
    latestHistoryAt,
  ];
}

class DiskUsageHistoryItem extends Equatable {
  const DiskUsageHistoryItem({
    required this.historyId,
    required this.requestId,
    required this.createdAt,
    required this.totalBytes,
  });

  final String historyId;
  final String requestId;
  final DateTime createdAt;
  final int totalBytes;

  @override
  List<Object> get props => [historyId, requestId, createdAt, totalBytes];
}

class DiskUsageFileItem extends Equatable {
  const DiskUsageFileItem({
    required this.fileId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.totalBytes,
    required this.createdAt,
    this.requestId,
    this.description = '',
  });

  final String fileId;
  final String fileName;
  final String filePath;
  final DiskUsageFileType fileType;
  final int totalBytes;
  final DateTime createdAt;
  final String? requestId;
  final String description;

  @override
  List<Object?> get props => [
    fileId,
    fileName,
    filePath,
    fileType,
    totalBytes,
    createdAt,
    requestId,
    description,
  ];
}
