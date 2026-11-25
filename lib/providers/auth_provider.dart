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
    apiClient.onSessionExpired = _expireSession;
    _loadSession();
  }

  Future<void> _expireSession(String token) async {
    if (_currentUser?.token != token) return;
    _currentUser = null;
    await StorageManager.clearAll();
    notifyListeners();
  }

  @override
  void dispose() {
    if (apiClient.onSessionExpired == _expireSession) apiClient.onSessionExpired = null;
    super.dispose();
  }

  // Load token & user session from local storage on app start
  Future<void> _loadSession() async {
    await StorageManager.init();
    final jsonStr = StorageManager.getUserJson();
    if (jsonStr != null) {
      try {
        final saved = AuthUser.fromJson(json.decode(jsonStr));
        if (saved.token.isEmpty || saved.token.startsWith('mock-token') || saved.token != StorageManager.getToken()) {
          await StorageManager.clearAll();
          return;
        }
        _currentUser = saved;
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

        if (user.token.trim().isEmpty) throw const FormatException('Missing session token');
        await _saveSession(user);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (dioErr) {
      final body = dioErr.response?.data;
      _errorMessage = body is Map && body['message'] is String
          ? body['message'] as String
          : 'Could not sign in. Check your connection and credentials.';
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Session saving helpers
  Future<void> _saveSession(AuthUser user) async {
    await StorageManager.setToken(user.token);
    await StorageManager.setUserJson(json.encode(user.toJson()));
    _currentUser = user;
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
