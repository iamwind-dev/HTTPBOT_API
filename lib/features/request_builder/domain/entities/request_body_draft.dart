import 'package:equatable/equatable.dart';

import 'request_key_value.dart';

enum RequestBodyType {
  none('None', plannedForInitialImplementation: true),
  xWwwFormUrlEncoded('URL Encoded', plannedForInitialImplementation: true),
  formData('Form Data', plannedForInitialImplementation: true),
  raw('Raw', plannedForInitialImplementation: true),
  graphql('GraphQL', plannedForInitialImplementation: true);

  const RequestBodyType(
    this.label, {
    required this.plannedForInitialImplementation,
  });

  final String label;
  final bool plannedForInitialImplementation;
}

enum RawBodySubtype {
  text('Text', contentType: 'text/plain'),
  json('JSON', contentType: 'application/json'),
  xml('XML', contentType: 'application/xml'),
  html('HTML', contentType: 'text/html');

  const RawBodySubtype(this.label, {required this.contentType});

  final String label;
  final String contentType;
}

class RawBodyDraft extends Equatable {
  const RawBodyDraft({this.subtype = RawBodySubtype.text, this.content = ''});

  final RawBodySubtype subtype;
  final String content;

  /// Returns true when the raw editor currently holds non-empty text.
  bool get hasContent => content.trim().isNotEmpty;

  /// Returns the header value that should be auto-synced for the current raw subtype.
  String? get syncedContentType =>
      subtype.contentType.trim().isEmpty ? null : subtype.contentType;

  /// Creates a new raw-body draft with any updated content or subtype applied.
  RawBodyDraft copyWith({RawBodySubtype? subtype, String? content}) =>
      RawBodyDraft(
        subtype: subtype ?? this.subtype,
        content: content ?? this.content,
      );

  @override
  List<Object> get props => [subtype, content];
}

class GraphQlBodyDraft extends Equatable {
  const GraphQlBodyDraft({
    this.query = '',
    this.variables = '',
    this.operationName,
  });

  final String query;
  final String variables;
  final String? operationName;

  /// Returns true when any GraphQL-specific input has been provided.
  bool get hasContent =>
      query.trim().isNotEmpty ||
      variables.trim().isNotEmpty ||
      (operationName?.trim().isNotEmpty ?? false);

  /// Creates a new GraphQL draft with any updated fields applied.
  GraphQlBodyDraft copyWith({
    String? query,
    String? variables,
    String? operationName,
    bool clearOperationName = false,
  }) => GraphQlBodyDraft(
    query: query ?? this.query,
    variables: variables ?? this.variables,
    operationName: clearOperationName
        ? null
        : operationName ?? this.operationName,
  );

  @override
  List<Object?> get props => [query, variables, operationName];
}

class RequestBodyDraft extends Equatable {
  const RequestBodyDraft({
    this.type = RequestBodyType.none,
    this.raw = const RawBodyDraft(),
    this.formData = const <KeyValueItem>[],
    this.urlEncoded = const <KeyValueItem>[],
    this.graphQl = const GraphQlBodyDraft(),
  });

  const RequestBodyDraft.none()
    : type = RequestBodyType.none,
      raw = const RawBodyDraft(),
      formData = const <KeyValueItem>[],
      urlEncoded = const <KeyValueItem>[],
      graphQl = const GraphQlBodyDraft();

  final RequestBodyType type;
  final RawBodyDraft raw;
  final List<KeyValueItem> formData;
  final List<KeyValueItem> urlEncoded;
  final GraphQlBodyDraft graphQl;

  /// Returns true when the active body mode contains data that can be sent.
  bool get hasContent => switch (type) {
    RequestBodyType.none => false,
    RequestBodyType.raw => raw.hasContent,
    RequestBodyType.formData => formData.any(
      (item) =>
          item.isEnabled &&
          item.hasKey &&
          (item.type != KeyValueItemType.file || item.hasValue),
    ),
    RequestBodyType.xWwwFormUrlEncoded => urlEncoded.any(
      (item) => item.isEnabled && item.hasKey,
    ),
    RequestBodyType.graphql => graphQl.hasContent,
  };

  /// Creates a new body draft with any updated mode-specific content applied.
  RequestBodyDraft copyWith({
    RequestBodyType? type,
    RawBodyDraft? raw,
    List<KeyValueItem>? formData,
    List<KeyValueItem>? urlEncoded,
    GraphQlBodyDraft? graphQl,
  }) => RequestBodyDraft(
    type: type ?? this.type,
    raw: raw ?? this.raw,
    formData: formData ?? this.formData,
    urlEncoded: urlEncoded ?? this.urlEncoded,
    graphQl: graphQl ?? this.graphQl,
  );

  @override
  List<Object> get props => [type, raw, formData, urlEncoded, graphQl];
}
