import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import 'it10b_screen.dart';

class ItrDetailsScreen extends StatefulWidget {
  final int itrId;

  const ItrDetailsScreen({Key? key, required this.itrId}) : super(key: key);

  @override
  State<ItrDetailsScreen> createState() => _ItrDetailsScreenState();
}

class _ItrDetailsScreenState extends State<ItrDetailsScreen> {
  bool _isActionLoading = false;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(double? amt) {
    if (amt == null) return '৳ 0';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'submitted':
        return AppColors.info;
      case 'under review':
        return AppColors.accent;
      case 'rejected':
        return AppColors.error;
      case 'draft':
        return Colors.grey;
      case 'send back':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  void _showWorkflowActionDialog(BuildContext context, PortalProvider provider, ItrRecord itr, String action, String targetStatus) {
    final requiresRemarks = action == 'Reject' || action == 'Send Back';
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('$action Return'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Return No: ${itr.returnNo ?? 'Draft ITR'}'),
                  const SizedBox(height: 8),
                  Text('Transitioning status to: $targetStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _remarksController,
                    decoration: InputDecoration(
                      labelText: requiresRemarks ? 'Remarks * (Required)' : 'Remarks (Optional)',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _remarksController.clear();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isActionLoading
                      ? null
                      : () async {
                          if (requiresRemarks && _remarksController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Remarks are required for this action!'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          setModalState(() => _isActionLoading = true);
                          final updated = await provider.patchItrStatus(
                            itr.id,
                            targetStatus,
                            _remarksController.text,
                            action,
                          );
                          setModalState(() => _isActionLoading = false);
                          if (updated != null && mounted) {
                            _remarksController.clear();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Return status updated to $targetStatus!'), backgroundColor: AppColors.success),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action == 'Reject' ? AppColors.error : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isActionLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        background: const Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );

    final theme = localTheme;
    const isDark = false;
    final portalProv = Provider.of<PortalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Find return record
    final itrIndex = portalProv.itrs.indexWhere((element) => element.id == widget.itrId);
    if (itrIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Details')),
        body: const Center(child: Text('Record not found.')),
      );
    }
    final itr = portalProv.itrs[itrIndex];
    final statusColor = _getStatusColor(itr.status);
    final double netTax = (itr.grossTax ?? 0.0) - (itr.rebate ?? 0.0);
    final double outstanding = netTax - ((itr.advanceTaxPaid ?? 0.0) + (itr.taxPaid ?? 0.0));

    final bool isOfficer = auth.currentUser?.role != 'TAXPAYER';
    final bool canSubmit = !isOfficer && (itr.status == 'Draft' || itr.status == 'Send Back');
    final bool canStartReview = isOfficer && itr.status == 'Submitted';
    final bool canAcceptReject = isOfficer && itr.status == 'Under Review';

    return Theme(
      data: localTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(itr.returnNo ?? 'ITR Details'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => It10bScreen(returnId: itr.id, returnNo: itr.returnNo ?? 'ITR-#${itr.id}'),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 18, color: Colors.amber),
                label: const Text('IT-10B Statement', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Top Header Card
          _buildHeaderCard(itr, isDark, theme, statusColor, netTax),
          const SizedBox(height: 20),

          // Workflow Actions Bar
          if (canSubmit || canStartReview || canAcceptReject)
            _buildWorkflowBar(context, portalProv, itr, canSubmit, canStartReview, canAcceptReject, isDark),

          const SizedBox(height: 20),

          // Main Grid Layout
          isMobile
              ? Column(
                  children: [
                    _buildLeftDetails(itr, theme, isDark, netTax, outstanding),
                    const SizedBox(height: 20),
                    _buildTimelineCard(itr, theme, isDark),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildLeftDetails(itr, theme, isDark, netTax, outstanding),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildTimelineCard(itr, theme, isDark),
                    ),
                  ],
                ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeaderCard(ItrRecord itr, bool isDark, ThemeData theme, Color statusColor, double netTax) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    final detailsWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          itr.returnNo ?? 'Draft ITR Record',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          itr.taxpayerName ?? 'Tasrif Zaman',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                itr.itrCategory ?? 'Individual',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'FY ${itr.assessmentYear}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                itr.status,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );

    final taxWidget = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          'Net Tax Payable',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(netTax),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.surfaceDark, Colors.grey.shade900]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detailsWidget,
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                taxWidget,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: detailsWidget),
                const SizedBox(width: 16),
                taxWidget,
              ],
            ),
    );
  }

  Widget _buildWorkflowBar(
    BuildContext context,
    PortalProvider provider,
    ItrRecord itr,
    bool canSubmit,
    bool canStartReview,
    bool canAcceptReject,
    bool isDark,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.settings_suggest, color: AppColors.accent),
        const SizedBox(width: 10),
        const Text('Workflow Actions:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
      ],
    );

    final actionsWidget = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canSubmit)
          ElevatedButton.icon(
            onPressed: () => _showWorkflowActionDialog(context, provider, itr, 'Submit', 'Submitted'),
            icon: const Icon(Icons.send, size: 14),
            label: const Text('Submit Return'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        if (canStartReview)
          ElevatedButton.icon(
            onPressed: () => _showWorkflowActionDialog(context, provider, itr, 'Start Review', 'Under Review'),
            icon: const Icon(Icons.search, size: 14),
            label: const Text('Start Review'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          ),
        if (canAcceptReject) ...[
          ElevatedButton.icon(
            onPressed: () => _showWorkflowActionDialog(context, provider, itr, 'Send Back', 'Send Back'),
            icon: const Icon(Icons.keyboard_return, size: 14),
            label: const Text('Send Back'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () => _showWorkflowActionDialog(context, provider, itr, 'Accept', 'Accepted'),
            icon: const Icon(Icons.check, size: 14),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () => _showWorkflowActionDialog(context, provider, itr, 'Reject', 'Rejected'),
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          ),
        ]
      ],
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelWidget,
                const SizedBox(height: 12),
                actionsWidget,
              ],
            )
          : Row(
              children: [
                labelWidget,
                const Spacer(),
                actionsWidget,
              ],
            ),
    );
  }

  Widget _buildLeftDetails(ItrRecord itr, ThemeData theme, bool isDark, double netTax, double outstanding) {
    return Column(
      children: [
        // Taxpayer & Period details card
        _buildInfoCard(
          title: 'Taxpayer & Period',
          icon: Icons.person_outline,
          rows: [
            _buildDetailRow('Return No.', itr.returnNo ?? 'Draft'),
            _buildDetailRow('TIN Number', itr.tinNumber ?? '—'),
            _buildDetailRow('Taxpayer Name', itr.taxpayerName ?? '—'),
            _buildDetailRow('Category', itr.itrCategory ?? '—'),
            _buildDetailRow('Assessment Year', itr.assessmentYear),
            _buildDetailRow('Income Year', itr.incomeYear ?? '—'),
            _buildDetailRow('Return Period', itr.returnPeriod ?? '—'),
          ],
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(height: 16),

        // Submission Details Card
        _buildInfoCard(
          title: 'Filing & Submission',
          icon: Icons.assignment_outlined,
          rows: [
            _buildDetailRow('Filing Deadline', _formatDate(itr.dueDate)),
            _buildDetailRow('Submission Date', _formatDate(itr.submissionDate)),
            _buildDetailRow('Submitted By', itr.submittedBy ?? '—'),
            _buildDetailRow('Status', itr.status),
          ],
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(height: 16),

        // Income & Tax Breakdown Card
        _buildBreakdownCard(itr, theme, isDark, netTax, outstanding),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(ItrRecord itr, ThemeData theme, bool isDark, double netTax, double outstanding) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.table_chart_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Income & Tax Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Income Section
                const Text('INCOME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: 8),
                _buildBreakdownRow('Gross Income', _formatAmount(itr.grossIncome)),
                _buildBreakdownRow('Exempt Income', '- ${_formatAmount(itr.exemptIncome)}', color: AppColors.success),
                _buildBreakdownRow('Taxable Income', _formatAmount((itr.grossIncome ?? 0) - (itr.exemptIncome ?? 0)), isBold: true),
                
                const SizedBox(height: 16),
                const Divider(),
                
                // Tax Section
                const Text('TAX COMPUTATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: 8),
                _buildBreakdownRow('Tax Rate', '${itr.taxRate ?? 0}%'),
                _buildBreakdownRow('Gross Tax Liability', _formatAmount(itr.grossTax)),
                _buildBreakdownRow('Investment Rebate', '- ${_formatAmount(itr.taxRebate)}', color: AppColors.success),
                _buildBreakdownRow('Net Tax Payable', _formatAmount(netTax), isBold: true),

                const SizedBox(height: 16),
                const Divider(),

                // Payment Section
                const Text('PAYMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                const SizedBox(height: 8),
                _buildBreakdownRow('Advance Tax Paid (AIT)', _formatAmount(itr.advanceTaxPaid)),
                _buildBreakdownRow('Withholding Tax', _formatAmount(itr.withholdingTax)),
                _buildBreakdownRow('Self-Paid with Return', _formatAmount(itr.taxPaid)),
                _buildBreakdownRow(
                  outstanding > 0 ? 'Outstanding Due Balance' : 'Refund Receivable',
                  _formatAmount(outstanding.abs()),
                  isBold: true,
                  color: outstanding > 0 ? AppColors.error : AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(ItrRecord itr, ThemeData theme, bool isDark) {
    final actions = itr.actionHistory ?? [];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Action History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('${actions.length} logs', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (actions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No history actions recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(actions.length, (index) {
                  final a = actions[index];
                  final isLast = index == actions.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getStatusColor(a.toStatus ?? '').withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              a.action == 'Accept'
                                  ? Icons.check
                                  : a.action == 'Reject'
                                      ? Icons.close
                                      : Icons.history,
                              size: 14,
                              color: _getStatusColor(a.toStatus ?? ''),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 60,
                              color: Colors.grey.shade300,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text('${a.fromStatus ?? 'Draft'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const Icon(Icons.arrow_right_alt, size: 12, color: Colors.grey),
                                Text(
                                  '${a.toStatus ?? 'Submitted'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(a.toStatus ?? ''),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By: ${a.performedBy} (${a.role})',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                            if (a.remarks != null && a.remarks!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade100.withOpacity(0.5)),
                                ),
                                child: Text(
                                  a.remarks!,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900),
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(a.performedAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
