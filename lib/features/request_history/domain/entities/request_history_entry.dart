import 'package:equatable/equatable.dart';

import '../../../request_builder/domain/entities/request_draft.dart';
import 'request_history_response_snapshot.dart';

class RequestHistoryEntry extends Equatable {
  const RequestHistoryEntry({
    required this.id,
    required this.sentAt,
    required this.request,
    required this.response,
  });

  final String id;
  final DateTime sentAt;
  final RequestDraft request;
  final RequestHistoryResponseSnapshot response;

  /// Returns a compact request label that future history lists can render directly.
  String get title => '${request.method.wireName} ${request.url}'.trim();

  @override
  List<Object> get props => [
    id,
    sentAt,
    request,
    response,
  ];
}
