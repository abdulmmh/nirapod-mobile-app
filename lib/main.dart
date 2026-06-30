import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/taxpayer_provider.dart';
import 'providers/portal_provider.dart';
import 'core/utils/storage_manager.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local disk cache SharedPreferences
  await StorageManager.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaxpayerProvider()),
        ChangeNotifierProvider(create: (_) => PortalProvider()),
      ],
      child: const NirapodApp(),
    ),
  );
}
