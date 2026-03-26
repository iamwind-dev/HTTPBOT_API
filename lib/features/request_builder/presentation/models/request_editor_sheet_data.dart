import 'package:equatable/equatable.dart';

import '../../domain/entities/request_draft.dart';
import 'request_list_item.dart';

class RequestEditorSheetData extends Equatable {
  const RequestEditorSheetData({
    required this.method,
    required this.title,
    required this.url,
    required this.authMode,
    required this.bodyMode,
  });

  final String method;
  final String title;
  final String url;
  final String authMode;
  final String bodyMode;

  /// Builds editor data by combining the tapped list item with the base draft metadata.
  factory RequestEditorSheetData.fromRequest({
    required RequestListItem item,
    required RequestDraft draft,
  }) => RequestEditorSheetData(
    method: item.method,
    title: item.title,
    url: item.url,
    authMode: draft.authMode,
    bodyMode: draft.bodyMode,
  );

  @override
  List<Object> get props => [method, title, url, authMode, bodyMode];
}
