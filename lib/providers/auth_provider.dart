import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _setLoading(false);
  }

  // Register user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );

      if (response.success && response.data != null) {
        _user = response.data!;
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    }
  }

  // Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _setLoading(false);
        return true;
      } else {
        _setError(response.message ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _apiService.logout();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _user = null;
      _setLoading(false);
    }
  }

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      final isLoggedIn = await _apiService.isLoggedIn();
      if (!isLoggedIn) {
        _user = null;
      }
      // Note: In a real app, you might want to validate the token with the server
      _setLoading(false);
    } catch (e) {
      _user = null;
      _setLoading(false);
    }
  }
}