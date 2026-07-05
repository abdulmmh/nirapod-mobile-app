import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({Key? key}) : super(key: key);

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '৳ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '৳ ${(amount / 100000).toStringAsFixed(2)} L';
    }
    final formatter = NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0);
    return formatter.format(amount);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'VAT':
        return Colors.teal;
      case 'Income Tax':
        return Colors.blue.shade700;
      case 'Penalty':
        return Colors.orange.shade700;
      case 'Demand Notice':
        return Colors.purple;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Extract Payment argument
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Payment) {
      return PortalShell(
        breadcrumbs: const ['My Portal', 'Payments', 'Payment Details'],
        showBackButton: true,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                const Text(
                  'No Payment Selected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Could not retrieve the details for this transaction. Please return to the list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/payments');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Back to Payments List'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final payment = args;

    final isSuccess = payment.status.toLowerCase() == 'success' || payment.status.toLowerCase() == 'completed';
    final isFailed = payment.status.toLowerCase() == 'failed';

    Color statusColor = AppColors.warning;
    if (isSuccess) statusColor = AppColors.success;
    if (isFailed) statusColor = AppColors.error;

    final taxpayerCard = _buildSectionCard(
      title: 'Taxpayer Information',
      icon: Icons.person_outline,
      isDark: isDark,
      theme: theme,
      rows: [
        _buildDetailRow(
          'TIN Number',
          payment.tinNumber ?? 'N/A',
          hasBadge: true,
          badgeColor: AppColors.primary.withOpacity(0.1),
          badgeTextColor: AppColors.primary,
        ),
        _buildDetailRow('Taxpayer Name', payment.taxpayerName ?? 'N/A', isBoldValue: true),
        if (payment.returnNo != null && payment.returnNo!.isNotEmpty)
          _buildDetailRow(
            'Return / Ref No.',
            payment.returnNo!,
            hasBadge: true,
            badgeColor: Colors.purple.shade50,
            badgeTextColor: Colors.purple.shade800,
          ),
      ],
    );

    final paymentCard = _buildSectionCard(
      title: 'Payment Information',
      icon: Icons.payment_outlined,
      isDark: isDark,
      theme: theme,
      rows: [
        _buildDetailRow(
          'Payment Type',
          payment.paymentType ?? 'Other',
          hasBadge: true,
          badgeColor: _getTypeColor(payment.paymentType ?? 'Other').withOpacity(0.1),
          badgeTextColor: _getTypeColor(payment.paymentType ?? 'Other'),
        ),
        _buildDetailRow('Payment Method', payment.paymentMethod ?? 'N/A'),
        _buildDetailRow('Amount', _formatCurrency(payment.amount), isBoldValue: true),
        _buildDetailRow('Payment Date', payment.date ?? payment.paymentDate ?? 'N/A'),
        if (payment.valueDate != null && payment.valueDate!.isNotEmpty)
          _buildDetailRow('Value Date', payment.valueDate!),
        if (payment.referenceNo != null && payment.referenceNo!.isNotEmpty)
          _buildDetailRow(
            'Reference No.',
            payment.referenceNo!,
            hasBadge: true,
            badgeColor: Colors.blue.shade50,
            badgeTextColor: Colors.blue.shade800,
          ),
        if (payment.chequeNo != null && payment.chequeNo!.isNotEmpty)
          _buildDetailRow('Cheque No.', payment.chequeNo!),
      ],
    );

    final bankCard = _buildSectionCard(
      title: 'Bank Information',
      icon: Icons.account_balance_outlined,
      isDark: isDark,
      theme: theme,
      rows: [
        _buildDetailRow('Bank Name', payment.bankName ?? 'N/A', isBoldValue: true),
        if (payment.bankBranch != null && payment.bankBranch!.isNotEmpty)
          _buildDetailRow('Branch', payment.bankBranch!),
        if (payment.accountNo != null && payment.accountNo!.isNotEmpty)
          _buildDetailRow(
            'Account No.',
            payment.accountNo!,
            hasBadge: true,
            badgeColor: Colors.grey.shade100,
            badgeTextColor: Colors.black87,
          ),
      ],
    );

    final processingCard = _buildSectionCard(
      title: 'Processing Information',
      icon: Icons.settings_outlined,
      isDark: isDark,
      theme: theme,
      rows: [
        _buildDetailRow(
          'Status',
          payment.status,
          hasBadge: true,
          badgeColor: statusColor.withOpacity(0.1),
          badgeTextColor: statusColor,
        ),
        if (payment.remarks != null && payment.remarks!.isNotEmpty)
          _buildDetailRow('Remarks', payment.remarks!, isAddress: true),
      ],
    );

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Payments', 'Payment Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Full transaction information.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (!isMobile)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to List'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                      side: BorderSide(color: Colors.teal.shade200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Transaction Header Card
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
                    color: AppColors.primary.withOpacity(0.2),
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
                        child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.challanNo,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              payment.paymentType ?? 'Tax Payment',
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
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(payment.amount),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visual Workflow Status Stepper
            _buildWorkflowStepper(payment.status, theme),
            const SizedBox(height: 20),

            // Detail Cards Grid/Column layout
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      taxpayerCard,
                      const SizedBox(height: 16),
                      paymentCard,
                      const SizedBox(height: 16),
                      bankCard,
                      const SizedBox(height: 16),
                      processingCard,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            taxpayerCard,
                            const SizedBox(height: 16),
                            bankCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            paymentCard,
                            const SizedBox(height: 16),
                            processingCard,
                          ],
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowStepper(String status, ThemeData theme) {
    final statusL = status.toLowerCase();
    
    bool step1Done = true; // Always submitted
    bool step2Active = statusL == 'under review';
    bool step2Done = statusL == 'completed' || statusL == 'success';
    bool step3Active = statusL == 'completed' || statusL == 'success';
    bool step3Done = statusL == 'completed' || statusL == 'success';
    bool isRejected = statusL == 'failed';

    Color getColor(bool done, bool active) {
      if (isRejected && active) return Colors.red;
      if (done) return AppColors.success;
      if (active) return Colors.purple;
      return Colors.grey.shade300;
    }

    Widget _buildStep(String title, bool done, bool active, IconData icon) {
      final color = getColor(done, active);
      return Expanded(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: active || done ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    done ? 'Done' : (active ? (isRejected ? 'Failed' : 'Active') : 'Pending'),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildLine(bool done) {
      return Container(
        width: 32,
        height: 2,
        color: done ? AppColors.success : Colors.grey.shade300,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildStep('Submitted', step1Done, statusL == 'pending', Icons.check_circle_outline),
          _buildLine(step2Done || step2Active),
          _buildStep('Under Review', step2Done, step2Active, Icons.search),
          _buildLine(step3Done),
          _buildStep('Settled', step3Done, step3Active, Icons.verified_outlined),
        ],
      ),
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
                          fontFamily: label.contains('TIN') || label.contains('Ref') || label.contains('Reference') || label.contains('Account') ? 'monospace' : null,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      textAlign: isAddress ? TextAlign.right : TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
