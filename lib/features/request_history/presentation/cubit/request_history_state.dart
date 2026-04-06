import 'package:equatable/equatable.dart';

import '../../domain/entities/request_history_entry.dart';

enum RequestHistoryStatus { initial, loading, ready }

class RequestHistoryState extends Equatable {
  const RequestHistoryState({
    required this.status,
    required this.entries,
  });

  const RequestHistoryState.initial()
    : status = RequestHistoryStatus.initial,
      entries = const <RequestHistoryEntry>[];

  final RequestHistoryStatus status;
  final List<RequestHistoryEntry> entries;

  /// Returns true when there are no saved history entries to render.
  bool get isEmpty => entries.isEmpty;

  /// Creates a new immutable history state with updated status or entries.
  RequestHistoryState copyWith({
    RequestHistoryStatus? status,
    List<RequestHistoryEntry>? entries,
  }) => RequestHistoryState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
  );

  @override
  List<Object> get props => [
    status,
    entries,
  ];
}
