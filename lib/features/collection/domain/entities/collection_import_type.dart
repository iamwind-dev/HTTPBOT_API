enum CollectionImportType { har, openApiSpec, postmanCollection }

extension CollectionImportTypeX on CollectionImportType {
  String get label => switch (this) {
    CollectionImportType.har => 'HAR',
    CollectionImportType.openApiSpec => 'OpenAPI Spec',
    CollectionImportType.postmanCollection => 'Postman Collection',
  };
}
