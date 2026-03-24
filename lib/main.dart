import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'injection/injection.dart';

export 'app/app.dart' show MyApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}
