import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nirapod_mobile_app/core/utils/api_client.dart';
import 'package:nirapod_mobile_app/providers/portal_provider.dart';
import 'package:nirapod_mobile_app/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('Empty portal responses stay empty and all sections are requested', () async {
    final paths = <String>{};
    final transport = InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      handler.resolve(Response(requestOptions: options, data: [], statusCode: 200));
    });
    apiClient.dio.interceptors.add(transport);
    addTearDown(() => apiClient.dio.interceptors.remove(transport));
    final portal = PortalProvider();
    await portal.loadAllData(1);
    expect(paths, hasLength(9));
    expect(portal.errorMessage, isNull);
    expect(portal.payments, isEmpty);
    expect(portal.notices, isEmpty);
    expect(portal.itrs, isEmpty);
  });

  test('A connection error cannot authenticate or confirm a notice reply', () async {
    final offline = InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
    });
    apiClient.dio.interceptors.add(offline);
    addTearDown(() => apiClient.dio.interceptors.remove(offline));
    final auth = AuthProvider();
    expect(await auth.login('taxpayer@nirapod.example', 'test'), isFalse);
    expect(auth.isLoggedIn, isFalse);
    final portal = PortalProvider();
    expect(await portal.replyNotice(1, 'Test response'), isFalse);
    expect(portal.notices, isEmpty);
    auth.dispose();
  });
}
