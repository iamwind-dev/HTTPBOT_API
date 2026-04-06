import 'package:equatable/equatable.dart';

import 'request_key_value.dart';

enum RequestBodyType {
  none('None', plannedForInitialImplementation: true),
  raw('Raw', plannedForInitialImplementation: true),
  json('JSON', plannedForInitialImplementation: true),
  formData('Form Data', plannedForInitialImplementation: true),
  xWwwFormUrlEncoded(
    'x-www-form-urlencoded',
    plannedForInitialImplementation: true,
  ),
  graphql('GraphQL', plannedForInitialImplementation: false);

  const RequestBodyType(
    this.label, {
    required this.plannedForInitialImplementation,
  });

  final String label;
  final bool plannedForInitialImplementation;
}

class GraphQlBodyDraft extends Equatable {
  const GraphQlBodyDraft({
    this.query = '',
    this.operationName = '',
    this.variables = '',
  });

  final String query;
  final String operationName;
  final String variables;

  /// Returns true when any GraphQL-specific input has been provided.
  bool get hasContent =>
      query.trim().isNotEmpty ||
      operationName.trim().isNotEmpty ||
      variables.trim().isNotEmpty;

  /// Creates a new GraphQL draft with any updated fields applied.
  GraphQlBodyDraft copyWith({
    String? query,
    String? operationName,
    String? variables,
  }) => GraphQlBodyDraft(
    query: query ?? this.query,
    operationName: operationName ?? this.operationName,
    variables: variables ?? this.variables,
  );

  @override
  List<Object> get props => [query, operationName, variables];
}

class RequestBodyDraft extends Equatable {
  const RequestBodyDraft({
    this.type = RequestBodyType.none,
    this.raw = '',
    this.json = '',
    this.rawContentType = 'text/plain',
    this.formData = const <KeyValueItem>[],
    this.urlEncoded = const <KeyValueItem>[],
    this.graphQl = const GraphQlBodyDraft(),
  });

  const RequestBodyDraft.none()
    : type = RequestBodyType.none,
      raw = '',
      json = '',
      rawContentType = 'text/plain',
      formData = const <KeyValueItem>[],
      urlEncoded = const <KeyValueItem>[],
      graphQl = const GraphQlBodyDraft();

  final RequestBodyType type;
  final String raw;
  final String json;
  final String rawContentType;
  final List<KeyValueItem> formData;
  final List<KeyValueItem> urlEncoded;
  final GraphQlBodyDraft graphQl;

  /// Returns true when the active body mode contains data that can be sent.
  bool get hasContent => switch (type) {
    RequestBodyType.none => false,
    RequestBodyType.raw => raw.trim().isNotEmpty,
    RequestBodyType.json => json.trim().isNotEmpty,
    RequestBodyType.formData => formData.any((item) => item.isComplete),
    RequestBodyType.xWwwFormUrlEncoded => urlEncoded.any(
      (item) => item.isComplete,
    ),
    RequestBodyType.graphql => graphQl.hasContent,
  };

  /// Creates a new body draft with any updated mode-specific content applied.
  RequestBodyDraft copyWith({
    RequestBodyType? type,
    String? raw,
    String? json,
    String? rawContentType,
    List<KeyValueItem>? formData,
    List<KeyValueItem>? urlEncoded,
    GraphQlBodyDraft? graphQl,
  }) => RequestBodyDraft(
    type: type ?? this.type,
    raw: raw ?? this.raw,
    json: json ?? this.json,
    rawContentType: rawContentType ?? this.rawContentType,
    formData: formData ?? this.formData,
    urlEncoded: urlEncoded ?? this.urlEncoded,
    graphQl: graphQl ?? this.graphQl,
  );

  @override
  List<Object> get props => [
    type,
    raw,
    json,
    rawContentType,
    formData,
    urlEncoded,
    graphQl,
  ];
}
