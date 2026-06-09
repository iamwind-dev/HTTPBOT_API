import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/services/oauth2_callback_service.dart';
import 'injection/injection.dart';

export 'app/app.dart' show MyApp;

/// Boots the app and starts deep-link listening before the first frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await getIt<OAuth2CallbackService>().initialize();
  runApp(const MyApp());
}
