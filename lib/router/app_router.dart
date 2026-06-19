import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';

/// Builds the app router, using [authProvider] to gate route access.
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final goingToLogin = state.matchedLocation == '/login';

      // Not logged in and not heading to login → redirect to login.
      if (!isLoggedIn && !goingToLogin) return '/login';

      // Already logged in and heading to login → redirect to dashboard.
      if (isLoggedIn && goingToLogin) return '/dashboard';

      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
