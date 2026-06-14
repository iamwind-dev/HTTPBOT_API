import 'package:equatable/equatable.dart';

import 'request_auth_draft.dart';
import 'request_body_draft.dart';
import 'request_key_value.dart';
import 'request_settings.dart';
import 'request_test.dart';
import 'request_variable.dart';
import 'requests_method.dart';

class RequestDraft extends Equatable {
  const RequestDraft({
    this.method = HttpMethod.get,
    this.url = '',
    this.queryParameters = const <KeyValueItem>[],
    this.headers = const <KeyValueItem>[],
    this.tests = const <RequestTest>[],
    this.variables = const <RequestVariable>[],
    this.body = const RequestBodyDraft.none(),
    this.auth = const RequestAuthDraft.none(),
    this.settings = const RequestSettings(),
    this.timeout = const Duration(seconds: 30),
    this.verifySsl = true,
  });

  final HttpMethod method;
  final String url;
  final List<KeyValueItem> queryParameters;
  final List<KeyValueItem> headers;
  final List<RequestTest> tests;
  final List<RequestVariable> variables;
  final RequestBodyDraft body;
  final RequestAuthDraft auth;
  final RequestSettings settings;
  final Duration timeout;
  final bool verifySsl;

  /// Returns the auth label expected by the current presentation layer.
  String get authMode => auth.type.label;

  /// Returns the body label expected by the current presentation layer.
  String get bodyMode => body.type.label;

  /// Creates a new request draft with any updated editor values applied.
  RequestDraft copyWith({
    HttpMethod? method,
    String? url,
    List<KeyValueItem>? queryParameters,
    List<KeyValueItem>? headers,
    List<RequestTest>? tests,
    List<RequestVariable>? variables,
    RequestBodyDraft? body,
    RequestAuthDraft? auth,
    RequestSettings? settings,
    Duration? timeout,
    bool? verifySsl,
  }) => RequestDraft(
    method: method ?? this.method,
    url: url ?? this.url,
    queryParameters: queryParameters ?? this.queryParameters,
    headers: headers ?? this.headers,
    tests: tests ?? this.tests,
    variables: variables ?? this.variables,
    body: body ?? this.body,
    auth: auth ?? this.auth,
    settings: settings ?? this.settings,
    timeout: timeout ?? this.timeout,
    verifySsl: verifySsl ?? this.verifySsl,
  );

  @override
  List<Object> get props => [
    method,
    url,
    queryParameters,
    headers,
    tests,
    variables,
    body,
    auth,
    settings,
    timeout,
    verifySsl,
  ];
}
