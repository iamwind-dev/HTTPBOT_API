import 'dart:async';

import 'package:app_links/app_links.dart';

const defaultOAuth2MobileRedirectUri = 'httpbot://oauth/callback';

abstract interface class OAuth2CallbackService {
  /// Starts listening for OAuth2 callback deep links as early as possible in app startup.
  Future<void> initialize();

  /// Clears any cached callback so a new authorization attempt starts from a clean state.
  void clearPendingCallback();

  /// Returns and clears the latest cached callback when one already arrived.
  Uri? takePendingCallback();

  /// Streams OAuth2 callback links received while the app is running.
  Stream<Uri> get callbackStream;

  /// Returns true when the given URI matches the app's supported OAuth2 callback.
  bool matchesCallback(Uri uri);
}

class AppLinksOAuth2CallbackService implements OAuth2CallbackService {
  AppLinksOAuth2CallbackService({required AppLinks appLinks})
    : _appLinks = appLinks;

  final AppLinks _appLinks;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  Uri? _pendingCallback;
  bool _initialized = false;

  @override
  /// Streams OAuth2 callback links collected by the service.
  Stream<Uri> get callbackStream => _controller.stream;

  @override
  /// Starts the app-links listener and captures the initial cold-start callback once.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _captureCallback(await _appLinks.getInitialLink());
    _appLinks.uriLinkStream.listen(_captureCallback);
  }

  @override
  /// Returns true only for the mobile callback URI registered by the app.
  bool matchesCallback(Uri uri) =>
      uri.scheme == 'httpbot' && uri.host == 'oauth' && uri.path == '/callback';

  @override
  /// Removes any previously cached callback before starting a fresh auth flow.
  void clearPendingCallback() {
    _pendingCallback = null;
  }

  @override
  /// Returns the cached callback once so the active auth flow can consume it.
  Uri? takePendingCallback() {
    final pendingCallback = _pendingCallback;
    _pendingCallback = null;
    return pendingCallback;
  }

  /// Caches and broadcasts matching callback URIs without exposing sensitive query values in logs.
  void _captureCallback(Uri? uri) {
    if (uri == null || !matchesCallback(uri)) {
      return;
    }

    _pendingCallback = uri;
    if (!_controller.isClosed) {
      _controller.add(uri);
    }
  }
}
