import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'storage_manager.dart';

class ApiClient {
  late final Dio dio;
  Future<void> Function(String token)? onSessionExpired;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & response interceptor to attach JWT token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Initialize StorageManager if needed
          await StorageManager.init();
          final token = StorageManager.getToken();
          if (options.path != ApiEndpoints.login && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (e, handler) async {
          final header = e.requestOptions.headers['Authorization'];
          if (e.response?.statusCode == 401 && header is String && header.startsWith('Bearer ')) {
            await onSessionExpired?.call(header.substring(7));
          }
          return handler.next(e);
        },
      ),
    );
  }

  // HTTP wrapper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.delete(path, data: data, queryParameters: queryParameters);
  }
}

// Global single instance
final apiClient = ApiClient();
