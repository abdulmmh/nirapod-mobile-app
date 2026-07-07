import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class AuditsScreen extends StatelessWidget {
  const AuditsScreen({Key? key}) : super(key: key);

  String _formatAmount(double? amt) {
    if (amt == null || amt == 0.0) return '৳ 0';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  bool _isOverdue(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _requiresAction(Audit c) {
    final status = c.status.toUpperCase();
    return ['DOCUMENT_REQUESTED', 'NOTICE_ISSUED', 'DEMAND_ISSUED'].contains(status) ||
        c.openQueryCount > 0;
  }

  String _getActionRequired(Audit c) {
    final status = c.status.toUpperCase();
    if (status == 'DOCUMENT_REQUESTED') return 'Upload Documents';
    if (c.openQueryCount > 0) return '${c.openQueryCount} query pending';
    if (status == 'NOTICE_ISSUED') return 'Notice Received';
    if (status == 'DEMAND_ISSUED') return 'Pay or Appeal';
    return '';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CLOSED':
      case 'PAID':
        return AppColors.success;
      case 'DOCUMENT_REQUESTED':
        return Colors.orange.shade700;
      case 'NOTICE_ISSUED':
      case 'ASSESSMENT_PROPOSED':
        return Colors.amber.shade800;
      case 'DEMAND_ISSUED':
        return AppColors.error;
      case 'UNDER_REVIEW':
      case 'CASE_CREATED':
      default:
        return AppColors.info;
    }
  }

  String _getTypeLabel(String t) {
    switch (t.toUpperCase()) {
      case 'DESK': return 'Desk';
      case 'FIELD': return 'Field';
      case 'COMPREHENSIVE': return 'Comprehensive';
      case 'VAT': return 'VAT';
      case 'REFUND': return 'Refund';
      case 'SPECIAL': return 'Special';
      default: return t;
    }
  }

  String _getTaxTypeLabel(String t) {
    switch (t.toUpperCase()) {
      case 'INCOME_TAX': return 'Income Tax';
      case 'VAT': return 'VAT';
      case 'AIT': return 'AIT';
      default: return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Audits'],
      showBackButton: true,
      body: portalProv.audits.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No active audit investigations found.'),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portalProv.audits.length,
              itemBuilder: (context, index) {
                final audit = portalProv.audits[index];
                final reqAction = _requiresAction(audit);
                final statusColor = _getStatusColor(audit.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: reqAction ? Colors.orange.shade300 : Colors.grey.shade200,
                      width: reqAction ? 1.5 : 1.0,
                    ),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blue.shade100),
                                  ),
                                  child: Text(
                                    audit.caseNo,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getTypeLabel(audit.auditType),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                audit.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action Warning Banner if required
                        if (reqAction) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.orange.shade800, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Action Required: ${_getActionRequired(audit)}',
                                  style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Audit Details Meta rows
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetaItem('Tax Type', _getTaxTypeLabel(audit.taxType)),
                            ),
                            Expanded(
                              child: _buildMetaItem('Fiscal Year', audit.year),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetaItem('Notice Date', _formatDate(audit.createdAt)),
                            ),
                            Expanded(
                              child: _buildMetaItem(
                                'Due Date',
                                _formatDate(audit.dueDate),
                                textColor: _isOverdue(audit.dueDate) ? Colors.red.shade700 : null,
                              ),
                            ),
                          ],
                        ),

                        // Outstanding Demand section
                        if (audit.demandAmount != null && audit.demandAmount! > 0) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Outstanding Fine / Demand:',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatAmount(audit.demandAmount),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 6),

                        // Card Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/audit-details',
                                  arguments: audit.id,
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMetaItem(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: textColor ?? Colors.grey.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
