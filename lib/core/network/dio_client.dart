import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Captures low-level connection metadata observed while a request is in flight.
///
/// `dart:io` exposes the remote endpoint and the negotiated ALPN protocol off the
/// established socket; true TLS version/cipher are not surfaced and stay null.
class ConnectionMetadata {
  String? remoteAddress;
  String? tlsProtocol;
  String? tlsCipher;
}

class DioClient {
  const DioClient();

  /// Creates a configured Dio instance for one request execution, honoring timeout and SSL settings.
  ///
  /// When [metadata] is provided, the underlying [HttpClient] records the remote
  /// address and negotiated TLS protocol of the connection it opens.
  Dio create({
    Duration timeout = const Duration(seconds: 15),
    bool followRedirects = true,
    bool verifySsl = true,
    ConnectionMetadata? metadata,
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        followRedirects: followRedirects,
        maxRedirects: followRedirects ? 5 : 0,
      ),
    );

    final needsCustomClient = !verifySsl || metadata != null;
    if (needsCustomClient) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          if (!verifySsl) {
            client.badCertificateCallback = (_, _, _) => true;
          }
          if (metadata != null) {
            client.connectionFactory = (uri, proxyHost, proxyPort) =>
                _recordingConnectionFactory(uri, metadata);
          }
          return client;
        },
      );
    }

    return dio;
  }
}

Future<ConnectionTask<Socket>> _recordingConnectionFactory(
  Uri uri,
  ConnectionMetadata metadata,
) async {
  final isSecure = uri.scheme == 'https';
  final port = uri.port == 0 ? (isSecure ? 443 : 80) : uri.port;

  if (isSecure) {
    final task = await SecureSocket.startConnect(uri.host, port);
    // Record metadata as a side effect once the socket is established without
    // replacing the task, so Dio keeps full ownership of the connection.
    unawaited(
      task.socket
          .then((socket) {
            _recordSocket(metadata, socket);
            metadata.tlsProtocol = socket.selectedProtocol;
          })
          .catchError((_) {}),
    );
    return task;
  }

  final task = await Socket.startConnect(uri.host, port);
  unawaited(
    task.socket
        .then((socket) => _recordSocket(metadata, socket))
        .catchError((_) {}),
  );
  return task;
}

void _recordSocket(ConnectionMetadata metadata, Socket socket) {
  try {
    metadata.remoteAddress =
        '${socket.remoteAddress.address}:${socket.remotePort}';
  } catch (_) {
    // Remote address is best-effort metadata and must never break the request.
  }
}
