import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/taxpayer_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final taxpayerProv = Provider.of<TaxpayerProvider>(context);
    final taxpayer = taxpayerProv.taxpayer;

    if (taxpayer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My TIN & Profile')),
        body: const Center(child: Text('Profile loading failed.')),
      );
    }

    final isIndividual = taxpayer.taxpayerType?.category?.toLowerCase() == 'individual';

    return Scaffold(
      appBar: AppBar(
        title: const Text('TIN & Profile Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TIN Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.credit_card_outlined, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'GOVERNMENT OF BANGLADESH',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'NATIONAL BOARD OF REVENUE',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    taxpayer.tin ?? 'NO TIN REGISTERED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      taxpayer.taxpayerType?.typeName ?? 'Taxpayer Profile',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile info header
            Text(
              'Identity Credentials',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Profile details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  if (isIndividual) ...[
                    _buildProfileRow('Full Name', taxpayer.fullName ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('NID Number', taxpayer.nid ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Date of Birth', taxpayer.dateOfBirth ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Gender', taxpayer.gender ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow("Father's Name", taxpayer.fathersName ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow("Mother's Name", taxpayer.mothersName ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Profession', taxpayer.profession ?? 'N/A', theme),
                  ] else ...[
                    _buildProfileRow('Company Name', taxpayer.companyName ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('RJSC No', taxpayer.rjscNo ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Nature of Business', taxpayer.natureOfBusiness ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Authorized Person', taxpayer.authorizedPersonName ?? 'N/A', theme),
                    _buildDivider(isDark),
                    _buildProfileRow('Authorized NID', taxpayer.authorizedPersonNid ?? 'N/A', theme),
                  ],
                  _buildDivider(isDark),
                  _buildProfileRow('Phone', taxpayer.phone ?? 'N/A', theme),
                  _buildDivider(isDark),
                  _buildProfileRow('Email', taxpayer.email ?? 'N/A', theme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Present Address header
            Text(
              'Tax Jurisdiction & Address',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Address card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Division', taxpayer.presentAddress?.division ?? 'N/A', theme),
                  _buildDivider(isDark),
                  _buildProfileRow('District', taxpayer.presentAddress?.district ?? 'N/A', theme),
                  _buildDivider(isDark),
                  _buildProfileRow('Address Details', taxpayer.presentAddress?.details ?? 'N/A', theme),
                  _buildDivider(isDark),
                  _buildProfileRow('Tax Zone', 'Zone 11 (Dhaka)', theme),
                  _buildDivider(isDark),
                  _buildProfileRow('Tax Circle', 'Circle 22 (Dhanmondi)', theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(color: isDark ? AppColors.borderDark : AppColors.border, height: 16);
  }
}
