import '../helpers/simple_curl_request_parser.dart';

/// Parses one supported cURL command for the request-editor confirmation flow.
class ParseCurlRequestUseCase {
  /// Creates the use case with the request-builder cURL parser dependency.
  const ParseCurlRequestUseCase([
    this._parser = const SimpleCurlRequestParser(),
  ]);

  final SimpleCurlRequestParser _parser;

  /// Returns the parsed draft and diagnostics without mutating persisted requests.
  CurlParseResult call(String command) => _parser.parseWithDiagnostics(command);
}
