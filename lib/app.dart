import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/business/business_screen.dart';
import 'ui/screens/business/business_detail_screen.dart';
import 'ui/screens/business/business_create_screen.dart';
import 'ui/screens/tin/issue_tin_screen.dart';
import 'ui/screens/itr/itr_screen.dart';
import 'ui/screens/ait/ait_screen.dart';
import 'ui/screens/payments/payments_screen.dart';
import 'ui/screens/notices/notices_screen.dart';
import 'ui/screens/audits/audits_screen.dart';
import 'ui/screens/appeals/appeals_screen.dart';

class NirapodApp extends StatelessWidget {
  const NirapodApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirapod Taxpayer Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Responsive to OS preferences
      initialRoute: '/',
      routes: {
        '/': (context) => const AppInitGate(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/businesses': (context) => const BusinessScreen(),
        '/business-details': (context) => const BusinessDetailScreen(),
        '/business-create': (context) => const BusinessCreateScreen(),
        '/tin-create': (context) => const IssueTinScreen(),
        '/itr': (context) => const ItrScreen(),
        '/ait': (context) => const AitScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/notices': (context) => const NoticesScreen(),
        '/audits': (context) => const AuditsScreen(),
        '/appeals': (context) => const AppealsScreen(),
      },
    );
  }
}

// Intercepts app entry to check active session
class AppInitGate extends StatelessWidget {
  const AppInitGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // Allow minor delay for loading session from disk
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isLoggedIn) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
