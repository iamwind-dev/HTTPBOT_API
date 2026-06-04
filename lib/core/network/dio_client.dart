import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DioClient {
  const DioClient();

  /// Creates a configured Dio instance for one request execution, honoring timeout and SSL settings.
  Dio create({
    Duration timeout = const Duration(seconds: 15),
    bool verifySsl = true,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
    );

    if (!verifySsl) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (_, _, _) => true;
          return client;
        },
      );
    }

    return dio;
  }
}
