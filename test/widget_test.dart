import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nirapod_mobile_app/app.dart';
import 'package:nirapod_mobile_app/providers/auth_provider.dart';
import 'package:nirapod_mobile_app/providers/taxpayer_provider.dart';
import 'package:nirapod_mobile_app/providers/portal_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TaxpayerProvider()),
          ChangeNotifierProvider(create: (_) => PortalProvider()),
        ],
        child: const NirapodApp(),
      ),
    );

    expect(find.text('NIRAPOD TAXPAYER'), findsOneWidget);
  });
}
