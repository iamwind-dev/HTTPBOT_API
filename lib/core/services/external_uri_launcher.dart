import 'package:url_launcher/url_launcher.dart';

abstract interface class ExternalUriLauncher {
  /// Opens the provided URI outside the app and reports whether launch succeeded.
  Future<bool> launchExternal(Uri uri);
}

class UrlLauncherExternalUriLauncher implements ExternalUriLauncher {
  const UrlLauncherExternalUriLauncher();

  @override
  /// Launches an external browser or app for the requested URI.
  Future<bool> launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
