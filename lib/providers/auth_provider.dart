import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../core/utils/storage_manager.dart';
import '../data/models/auth_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _loadSession();
  }

  // Load token & user session from local storage on app start
  Future<void> _loadSession() async {
    await StorageManager.init();
    final jsonStr = StorageManager.getUserJson();
    if (jsonStr != null) {
      try {
        _currentUser = AuthUser.fromJson(json.decode(jsonStr));
        notifyListeners();
      } catch (e) {
        print('Error loading user session: $e');
        logout();
      }
    }
  }

  // Core Login function
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final user = AuthUser.fromJson(data);
        
        // Exclude non-taxpayers from mobile app
        if (user.role != 'TAXPAYER') {
          _errorMessage = 'Access denied. Taxpayers only.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _saveSession(user);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (dioErr) {
      // Offline fallback / Mock authentication to match Angular's login flow
      if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.connectionError ||
          dioErr.response?.statusCode == 404 ||
          dioErr.response?.statusCode == 500 ||
          email == 'taxpayer@example.com') {
        final mockUser = _getMockUser(email, password);
        if (mockUser != null) {
          await _saveSession(mockUser);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _errorMessage = dioErr.response?.data?['message'] ?? 'Login failed. Please check credentials.';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Session saving helpers
  Future<void> _saveSession(AuthUser user) async {
    _currentUser = user;
    await StorageManager.setToken(user.token);
    await StorageManager.setUserJson(json.encode(user.toJson()));
  }

  // Logout
  Future<void> logout() async {
    try {
      if (isLoggedIn) {
        await apiClient.post(ApiEndpoints.logout);
      }
    } catch (_) {}

    _currentUser = null;
    _errorMessage = null;
    await StorageManager.clearAll();
    notifyListeners();
  }

  // Mock Taxpayer accounts for immediate testability
  AuthUser? _getMockUser(String email, String password) {
    if (email == 'taxpayer@example.com' && password == 'demo1234') {
      return AuthUser(
        id: 6,
        fullName: 'Abdul Karim',
        email: 'taxpayer@example.com',
        role: 'TAXPAYER',
        token: 'mock-token-taxpayer',
        taxpayerId: 1,
        taxpayerType: 'Individual',
        tinNumber: '102345678912',
        approvalStatus: 'Approved',
      );
    }
    // Additional business demo account if they input it
    if (email == 'business@example.com' && password == 'demo1234') {
      return AuthUser(
        id: 12,
        fullName: 'A.K. Traders Ltd.',
        email: 'business@example.com',
        role: 'TAXPAYER',
        token: 'mock-token-business',
        taxpayerId: 2,
        taxpayerType: 'Business',
        tinNumber: '302485967154',
        approvalStatus: 'Approved',
      );
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
