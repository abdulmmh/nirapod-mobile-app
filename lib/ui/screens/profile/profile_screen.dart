import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/taxpayer_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _downloadCertificate(BuildContext context, String? tinNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading TIN Certificate for $tinNumber...'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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

    final hasTin = taxpayer.tin != null && taxpayer.tin!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TIN & Profile Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Screen Header Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIN Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Full TIN record information.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!hasTin) ...[
              // Fallback block if taxpayer does not have a TIN
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off_outlined, size: 72, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No TIN Registered',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You do not have a Taxpayer Identification Number registered yet. Click below to issue a new TIN instantly.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/tin-create');
                      },
                      icon: const Icon(Icons.add_card_outlined),
                      label: const Text('Issue TIN Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success, width: 1.5),
                        foregroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _downloadCertificate(context, taxpayer.tin),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Download Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Redesigned Top Gradient Badge Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                taxpayer.tin ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                taxpayer.fullName ?? taxpayer.companyName ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Badges Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCardPill(taxpayer.taxpayerType?.category ?? 'Individual', Colors.white.withOpacity(0.2)),
                        _buildCardPill('Dhaka Tax Zone', Colors.white.withOpacity(0.15)),
                        _buildCardPill('Dhaka Circle-1', Colors.white.withOpacity(0.1)),
                        _buildCardPill('Active', Colors.amber.shade400, textColor: Colors.black87),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat('Issued Date', 'May 7, 2026'),
                        _buildStat('Last Updated', 'May 11, 2026'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Taxpayer Information card
              _buildSectionCard(
                title: 'Taxpayer Information',
                icon: Icons.business_outlined,
                isDark: isDark,
                theme: theme,
                rows: [
                  _buildDetailRow('TIN Number', taxpayer.tin ?? 'N/A', hasBadge: true, badgeColor: AppColors.primary.withOpacity(0.1), badgeTextColor: AppColors.primary),
                  _buildDetailRow('Full Name', taxpayer.fullName ?? taxpayer.companyName ?? 'N/A', isBoldValue: true),
                  _buildDetailRow('Category', taxpayer.taxpayerType?.category ?? 'Individual'),
                  _buildDetailRow('National ID', taxpayer.nid ?? 'N/A', hasBadge: true, badgeColor: Colors.blue.shade50, badgeTextColor: Colors.blue.shade800),
                  _buildDetailRow('Date of Birth', taxpayer.dateOfBirth ?? 'N/A'),
                  _buildDetailRow('Gender', taxpayer.gender ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Tax Authority details card
              _buildSectionCard(
                title: 'Tax Authority',
                icon: Icons.shield_outlined,
                isDark: isDark,
                theme: theme,
                rows: [
                  _buildDetailRow('Tax Zone', 'Dhaka Tax Zone', hasBadge: true, badgeColor: Colors.cyan.shade50, badgeTextColor: Colors.cyan.shade800),
                  _buildDetailRow('Tax Circle', 'Dhaka Circle-1', hasBadge: true, badgeColor: Colors.grey.shade100, badgeTextColor: Colors.grey.shade700),
                  _buildDetailRow('Status', taxpayer.approvalStatus ?? 'Active', hasBadge: true, badgeColor: AppColors.success.withOpacity(0.1), badgeTextColor: AppColors.success),
                  _buildDetailRow('Issued Date', 'May 7, 2026'),
                  _buildDetailRow('Last Updated', 'May 11, 2026'),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Contact & Location card
              _buildSectionCard(
                title: 'Contact & Location',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                theme: theme,
                rows: [
                  _buildDetailRow('Email', taxpayer.email ?? 'N/A'),
                  _buildDetailRow('Phone', taxpayer.phone ?? 'N/A'),
                  _buildDetailRow('Division', taxpayer.presentAddress?.division ?? 'N/A'),
                  _buildDetailRow('District', taxpayer.presentAddress?.district ?? 'N/A'),
                  _buildDetailRow('Address Details', taxpayer.presentAddress?.details ?? 'N/A', isAddress: true),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardPill(String text, Color bgColor, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Rows List
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    bool hasBadge = false,
    Color? badgeColor,
    Color? badgeTextColor,
    bool isAddress = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.06), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: hasBadge
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: badgeTextColor ?? Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: label.contains('TIN') || label.contains('ID') ? 'monospace' : null,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: isAddress ? TextAlign.right : TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                        color: isBoldValue ? Colors.black87 : Colors.black87,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

