import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hardcoded test credentials.
const String _testEmail = 'test@example.com';
const String _testPassword = 'password123';

/// Keys used for SharedPreferences persistence.
const String _keyIsLoggedIn = 'isLoggedIn';
const String _keyUserEmail = 'userEmail';

/// Manages authentication state and persists it across app restarts.
///
/// Usage:
///   context.read<AuthProvider>().login(email, password)
///   context.read<AuthProvider>().logout()
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _userEmail = '';
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String get userEmail => _userEmail;
  bool get isLoading => _isLoading;

  /// Loads persisted session on app start.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    _userEmail = prefs.getString(_keyUserEmail) ?? '';
    notifyListeners();
  }

  /// Attempts login with [email] and [password].
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate a brief network delay for realism.
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.trim() == _testEmail && password == _testPassword) {
      _isLoggedIn = true;
      _userEmail = email.trim();

      // Persist session.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, _userEmail);

      _isLoading = false;
      notifyListeners();
      return null; // success
    }

    _isLoading = false;
    notifyListeners();
    return 'Invalid email or password. Please try again.';
  }

  /// Clears session data and returns user to login.
  Future<void> logout() async {
    _isLoggedIn = false;
    _userEmail = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);

    notifyListeners();
  }
}
