import '../entities/request_body_draft.dart';

/// Returns the default header value that should be synchronized for a body mode.
String? contentTypeForBodyType(RequestBodyType bodyType) => switch (bodyType) {
  RequestBodyType.none => null,
  RequestBodyType.xWwwFormUrlEncoded => 'application/x-www-form-urlencoded',
  RequestBodyType.formData => 'multipart/form-data',
  RequestBodyType.raw => 'application/json',
  RequestBodyType.graphql => 'application/json',
};
