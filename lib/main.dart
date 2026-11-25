import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'core/utils/storage_manager.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local disk cache SharedPreferences
  await StorageManager.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const NirapodApp(),
    ),
  );
}
