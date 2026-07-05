import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class AppealDetailScreen extends StatefulWidget {
  const AppealDetailScreen({Key? key}) : super(key: key);

  @override
  State<AppealDetailScreen> createState() => _AppealDetailScreenState();
}

class _AppealDetailScreenState extends State<AppealDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);

    // Get appeal ID from route settings arguments
    final int? appealId = ModalRoute.of(context)?.settings.arguments as int?;

    if (appealId == null) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Appeals', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Error: No Appeal Selected',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    // Find appeal from provider list
    final appeal = portalProv.appeals.firstWhere(
      (a) => a.id == appealId,
      orElse: () => Appeal(
        id: 0,
        taxpayerId: 0,
        caseNo: 'Unknown',
        status: 'Unknown',
      ),
    );

    if (appeal.id == 0) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Appeals', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Error: Appeal Record Not Found',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatCurrency(double? val) {
      if (val == null) return '0.00';
      return val.toStringAsFixed(2).replaceAllMapped(formatter, (Match m) => '${m[1]},');
    }

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Appeals', 'Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Back Button Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appeal Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track the status of your filed appeal.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Relief Granted Green Alert Banner
            if (appeal.decision != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FBF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Partial Relief Granted. Your appeal was partially successful. Partial relief has been granted. Relief amount: ${formatCurrency(appeal.reliefGranted)} BDT',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Status Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          appeal.appealNo ?? appeal.caseNo,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            appeal.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildStatusMetaItem(Icons.label_outline, 'DEMAND NOTICE', isDark),
                        _buildStatusMetaItem(Icons.calendar_today_outlined, 'Filed ${appeal.filedAt ?? "—"}', isDark),
                        _buildStatusMetaItem(Icons.hourglass_empty_outlined, 'Deadline: ${appeal.deadline ?? "—"}', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial Details Grid Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Financial Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amounts involved in this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    isMobile
                        ? Column(
                            children: [
                              _buildFinancialBox('Total Demanded', '${formatCurrency(appeal.demandedAmount)} BDT', const Color(0xFFFEF2F2), Colors.red.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Amount Disputed', '${formatCurrency(appeal.disputedAmount)} BDT', const Color(0xFFFFFBEB), Colors.amber.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Relief Granted', '${formatCurrency(appeal.reliefGranted)} BDT', const Color(0xFFF0FDF4), Colors.green.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Accepted Amount', '${formatCurrency(appeal.acceptedAmount)} BDT', const Color(0xFFEFF6FF), Colors.blue.shade900),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildFinancialBox('Total Demanded', '${formatCurrency(appeal.demandedAmount)} BDT', const Color(0xFFFEF2F2), Colors.red.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Amount Disputed', '${formatCurrency(appeal.disputedAmount)} BDT', const Color(0xFFFFFBEB), Colors.amber.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Relief Granted', '${formatCurrency(appeal.reliefGranted)} BDT', const Color(0xFFF0FDF4), Colors.green.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Accepted Amount', '${formatCurrency(appeal.acceptedAmount)} BDT', const Color(0xFFEFF6FF), Colors.blue.shade900)),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Partial Payment Alert Box Card
            if (appeal.acceptedAmount != null && appeal.acceptedAmount! > 0) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                color: const Color(0xFFFEFDF6),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Partial Payment Required',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Accepted amount of ${formatCurrency(appeal.acceptedAmount)} BDT. Relief granted: ${formatCurrency(appeal.reliefGranted)} BDT.',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment redirecting processed!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Pay Accepted Amount'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Grounds & Relief sought card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Your Grounds',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reasons submitted for this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      appeal.groundsText ?? appeal.description ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (appeal.reliefSought != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FBF7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          'Relief Sought: ${appeal.reliefSought}',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Supporting Documents Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Supporting Documents',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Documents submitted in support of this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.folder_open_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No documents uploaded yet.',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Decision outcome Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Decision',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official decision on your appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Outcome',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appeal.decision ?? 'PENDING DECISION',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decided By',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appeal.decidedBy ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decided On',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appeal.decidedAt ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetaItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBox(String title, String val, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
