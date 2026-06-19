import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'router/app_router.dart';

void main() async {
  // Required when calling native code (SharedPreferences) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted auth state before rendering.
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const FlutterTestApp(),
    ),
  );
}

class FlutterTestApp extends StatefulWidget {
  const FlutterTestApp({super.key});

  @override
  State<FlutterTestApp> createState() => _FlutterTestAppState();
}

class _FlutterTestAppState extends State<FlutterTestApp> {
  late final _router = createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Test App',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: _router,
    );
  }

  /// Builds a clean Material 3 theme with an indigo seed color.
  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Input field style
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
