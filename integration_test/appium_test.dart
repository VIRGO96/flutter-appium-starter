import 'package:appium_flutter_server/appium_flutter_server.dart';
import 'package:flutter_test_app/main.dart' as app;
import 'package:flutter_test_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  // Provide a fresh AuthProvider (no SharedPreferences async init needed here).
  // initializeTest handles binding setup internally via AppiumTestWidgetsFlutterBinding.
  initializeTest(
    app: ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const app.FlutterTestApp(),
    ),
  );
}
