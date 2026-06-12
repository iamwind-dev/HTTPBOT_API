import '../entities/requests_method.dart';

bool shouldAutoAttachContentTypeForMethod(HttpMethod method) =>
    switch (method) {
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
