import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/portal_records.dart';

class BusinessDetailScreen extends StatelessWidget {
  const BusinessDetailScreen({Key? key}) : super(key: key);

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '৳ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '৳ ${(amount / 100000).toStringAsFixed(2)} L';
    }
    final formatter = NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Extract Business argument
    final biz = ModalRoute.of(context)!.settings.arguments as Business;

    Color statusColor = AppColors.success;
    if (biz.vatStatus.toLowerCase() == 'pending') {
      statusColor = AppColors.warning;
    } else if (biz.vatStatus.toLowerCase() == 'suspended') {
      statusColor = AppColors.error;
    }

    final regNo = 'BUS-${biz.tradeLicenseNo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').substring(0, 6).toUpperCase()}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Business Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Description
            Text(
              'Business Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Full business registration information.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Top Card Gradient Info
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
                        child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              regNo,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              biz.name,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCardPill(biz.businessType ?? 'Textile Manufacturing', Colors.white.withOpacity(0.2)),
                      _buildCardPill(biz.businessCategory ?? 'Garments & Textile', Colors.white.withOpacity(0.15)),
                      _buildCardPill(biz.vatStatus, Colors.amber.shade400, textColor: Colors.black87),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Annual Turnover', biz.annualTurnover != null ? _formatCurrency(biz.annualTurnover!) : 'N/A'),
                      _buildStat('Employees', biz.numberOfEmployees != null ? '${biz.numberOfEmployees}' : '0'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Business Information Card
            _buildSectionCard(
              title: 'Business Information',
              icon: Icons.business_outlined,
              isDark: isDark,
              theme: theme,
              rows: [
                _buildDetailRow('Business Name', biz.name, isBoldValue: true),
                _buildDetailRow('Owner Name', biz.ownerName ?? 'Tasrif Zaman'),
                _buildDetailRow('TIN Number', biz.tinNumber ?? 'TIN-000000005', hasBadge: true, badgeColor: AppColors.primary.withOpacity(0.1), badgeTextColor: AppColors.primary),
                _buildDetailRow('Business Type', biz.businessType ?? 'Textile Manufacturing'),
                _buildDetailRow('Category', biz.businessCategory ?? 'Garments & Textile'),
              ],
            ),
            const SizedBox(height: 16),

            // 2. License & Registration Card
            _buildSectionCard(
              title: 'License & Registration',
              icon: Icons.assignment_outlined,
              isDark: isDark,
              theme: theme,
              rows: [
                _buildDetailRow('Reg No.', regNo, hasBadge: true, badgeColor: Colors.purple.shade50, badgeTextColor: Colors.purple.shade800),
                _buildDetailRow('Trade License', biz.tradeLicenseNo, hasBadge: true, badgeColor: Colors.blue.shade50, badgeTextColor: Colors.blue.shade800),
                _buildDetailRow('Incorporation', biz.incorporationDate ?? 'N/A'),
                _buildDetailRow('Registration', biz.registrationDate ?? 'N/A'),
                _buildDetailRow('Expiry', biz.expiryDate ?? 'N/A', hasBadge: biz.expiryDate != null, badgeColor: Colors.red.shade50, badgeTextColor: Colors.red.shade800),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Contact & Location Card
            _buildSectionCard(
              title: 'Contact & Location',
              icon: Icons.location_on_outlined,
              isDark: isDark,
              theme: theme,
              rows: [
                _buildDetailRow('Email', biz.email ?? 'N/A'),
                _buildDetailRow('Phone', biz.phone ?? 'N/A'),
                _buildDetailRow('Division', biz.division ?? 'N/A'),
                _buildDetailRow('District', biz.district ?? 'N/A'),
                _buildDetailRow('Address Details', biz.address ?? 'N/A', isAddress: true),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Financial & Workforce Card
            _buildSectionCard(
              title: 'Financial & Workforce',
              icon: Icons.monetization_on_outlined,
              isDark: isDark,
              theme: theme,
              rows: [
                _buildDetailRow('Annual Turnover', biz.annualTurnover != null ? _formatCurrency(biz.annualTurnover!) : 'N/A'),
                _buildDetailRow('Employees', biz.numberOfEmployees != null ? '${biz.numberOfEmployees}' : '0'),
                _buildDetailRow('Status', biz.vatStatus, hasBadge: true, badgeColor: statusColor.withOpacity(0.1), badgeTextColor: statusColor),
              ],
            ),
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
                          fontFamily: label.contains('Reg') || label.contains('TIN') || label.contains('License') ? 'monospace' : null,
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
