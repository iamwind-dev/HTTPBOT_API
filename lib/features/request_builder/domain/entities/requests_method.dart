enum HttpMethod {
  get('GET', wireName: 'GET', supportsRequestBody: false),
  post('POST', wireName: 'POST', supportsRequestBody: true),
  put('PUT', wireName: 'PUT', supportsRequestBody: true),
  delete('DEL', wireName: 'DELETE', supportsRequestBody: true),
  patch('PAT', wireName: 'PATCH', supportsRequestBody: true),
  head('HEAD', wireName: 'HEAD', supportsRequestBody: false),
  options('OPT', wireName: 'OPTIONS', supportsRequestBody: false),
  connect('CON', wireName: 'CONNECT', supportsRequestBody: true),
  trace('TRACE', wireName: 'TRACE', supportsRequestBody: false);

  const HttpMethod(
    this.label, {
    required this.wireName,
    required this.supportsRequestBody,
  });

  final String label;
  final String wireName;
  final bool supportsRequestBody;
}

bool methodSupportsRequestBody(HttpMethod method) => switch (method) {
  HttpMethod.get => false,
  HttpMethod.head => false,
  HttpMethod.options => false,
  HttpMethod.trace => false,
  HttpMethod.post => true,
  HttpMethod.put => true,
  HttpMethod.patch => true,
  HttpMethod.delete => true,
  HttpMethod.connect => true,
};
