import 'package:equatable/equatable.dart';

import '../../../request_builder/domain/entities/request_auth_draft.dart';
import '../../../request_builder/domain/entities/request_key_value.dart';
import 'web_socket_settings_entity.dart';

class WebSocketRequestEntity extends Equatable {
  const WebSocketRequestEntity({
    required this.id,
    required this.name,
    this.url = '',
    this.queryParameters = const <KeyValueItem>[],
    this.headers = const <KeyValueItem>[],
    this.auth = const RequestAuthDraft.none(),
    this.settings = const WebSocketSettingsEntity(),
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String url;
  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
  final RequestAuthDraft auth;
  final WebSocketSettingsEntity settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Creates a request copy with editor updates applied.
  WebSocketRequestEntity copyWith({
    String? id,
    String? name,
    String? url,
    List<KeyValueItem>? queryParameters,
    List<KeyValueItem>? headers,
    RequestAuthDraft? auth,
    WebSocketSettingsEntity? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WebSocketRequestEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    auth: auth ?? this.auth,
    settings: settings ?? this.settings,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    queryParameters,
    headers,
    auth,
    settings,
    createdAt,
    updatedAt,
  ];
}
