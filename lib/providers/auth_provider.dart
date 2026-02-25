import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

/// Manages authentication state: login, JWT token, and user profile.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api;

  AuthProvider({required ApiClient api}) : _api = api;

  // ── State ──────────────────────────────────────────────────────────────
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Attempt login with username and password.
  ///
  /// On success, stores the JWT token and fetches the user profile.
  /// The Fake Store API doesn't return a user ID from login, so we
  /// search the users list by username to find the matching profile.
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Authenticate and receive JWT
      final authResponse = await _api.login(
        LoginRequest(username: username, password: password),
      );
      _token = authResponse.token;
      _api.setToken(_token!);

      // 2. Fetch user profile — the API uses sequential IDs (1-10).
      //    We try to find the user by iterating, since login doesn't
      //    return a user ID.
      _currentUser = await _findUserByUsername(username);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed. Please check your credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Try users 1-10 to find the one matching the given username.
  Future<User> _findUserByUsername(String username) async {
    for (int id = 1; id <= 10; id++) {
      try {
        final user = await _api.getUser(id);
        if (user.username == username) return user;
      } catch (_) {
        continue;
      }
    }
    // Fallback: return user 1 if no match found
    return _api.getUser(1);
  }

  /// Log out and clear all state.
  void logout() {
    _currentUser = null;
    _token = null;
    _error = null;
    _api.clearToken();
    notifyListeners();
  }
}
