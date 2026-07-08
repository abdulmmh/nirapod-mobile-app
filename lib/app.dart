import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/profile/edit_profile_screen.dart';
import 'ui/screens/business/business_screen.dart';
import 'ui/screens/business/business_detail_screen.dart';
import 'ui/screens/business/business_create_screen.dart';
import 'ui/screens/tin/issue_tin_screen.dart';
import 'ui/screens/tin/tin_details_screen.dart';
import 'ui/screens/itr/itr_screen.dart';
import 'ui/screens/ait/ait_screen.dart';
import 'ui/screens/payments/payments_screen.dart';
import 'ui/screens/payments/payment_create_screen.dart';
import 'ui/screens/payments/payment_detail_screen.dart';
import 'ui/screens/notices/notices_screen.dart';
import 'ui/screens/notices/notice_detail_screen.dart';
import 'ui/screens/audits/audits_screen.dart';
import 'ui/screens/audits/audit_detail_screen.dart';
import 'ui/screens/appeals/appeals_screen.dart';
import 'ui/screens/appeals/appeal_detail_screen.dart';
import 'ui/screens/vat/vat_registrations_screen.dart';
import 'ui/screens/vat/vat_returns_screen.dart';

class NirapodApp extends StatelessWidget {
  const NirapodApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirapod Taxpayer Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light mode to show whitesmoke background
      initialRoute: '/',
      routes: {
        '/': (context) => const AppInitGate(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile-edit': (context) => const EditProfileScreen(),
        '/businesses': (context) => const BusinessScreen(),
        '/business-details': (context) => const BusinessDetailScreen(),
        '/business-create': (context) => const BusinessCreateScreen(),
        '/tin-create': (context) => const IssueTinScreen(),
        '/tin-details': (context) => const TinDetailsScreen(),
        '/itr': (context) => const ItrScreen(),
        '/ait': (context) => const AitScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/payment-create': (context) => const PaymentCreateScreen(),
        '/payment-details': (context) => const PaymentDetailScreen(),
        '/notices': (context) => const NoticesScreen(),
        '/notice-details': (context) => const NoticeDetailScreen(),
        '/audits': (context) => const AuditsScreen(),
        '/audit-details': (context) => const AuditDetailScreen(),
        '/appeals': (context) => const AppealsScreen(),
        '/appeal-details': (context) => const AppealDetailScreen(),
        '/vat-registrations': (context) => const VatRegistrationsScreen(),
        '/vat-returns': (context) => const VatReturnsScreen(),
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
