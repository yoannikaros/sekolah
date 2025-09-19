import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Get stored token
  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Save token
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Register user
  Future<ApiResponse<User>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role.value,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] as String?;
        if (token != null) {
          await saveToken(token);
        }
        
        return ApiResponse<User>(
          success: true,
          message: data['message'] as String? ?? 'Registration successful',
          data: User.fromJson(data['user'] as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: data['error'] as String? ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Login user
  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = data['token'] as String;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        
        // Save token
        await saveToken(token);
        
        return ApiResponse<LoginResponse>(
          success: true,
          message: data['message'] as String? ?? 'Login successful',
          data: LoginResponse(token: token, user: user),
        );
      } else {
        return ApiResponse<LoginResponse>(
          success: false,
          message: data['error'] as String? ?? 'Login failed',
        );
      }
    } catch (e) {
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _getHeaders(),
      );

      await clearToken();

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Logged out successfully',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: 'Logout failed',
        );
      }
    } catch (e) {
      await clearToken(); // Clear token anyway
      return ApiResponse<void>(
        success: true,
        message: 'Logged out locally',
      );
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });
}

// Login response model
class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });
}