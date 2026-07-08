import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class AuditsScreen extends StatefulWidget {
  const AuditsScreen({Key? key}) : super(key: key);

  @override
  State<AuditsScreen> createState() => _AuditsScreenState();
}

class _AuditsScreenState extends State<AuditsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // 'ALL', 'ACTION', 'ACTIVE', 'CLOSED'
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);
    final audits = portalProv.audits;

    // ── KPI calculations ──────────────────────────────────────────────────
    final totalCases = audits.length;
    final actionRequiredCount = audits.where(_requiresAction).length;
    final totalOutstanding = audits.map((a) => a.demandAmount ?? 0.0).fold(0.0, (sum, val) => sum + val);

    // ── Filtering Logic ───────────────────────────────────────────────────
    final filteredAudits = audits.where((audit) {
      // Search check
      final matchesSearch = audit.caseNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          audit.auditType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          audit.status.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getTaxTypeLabel(audit.taxType).toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Filter category check
      if (_selectedFilter == 'ACTION') return _requiresAction(audit);
      if (_selectedFilter == 'ACTIVE') return audit.status.toUpperCase() != 'CLOSED' && audit.status.toUpperCase() != 'PAID';
      if (_selectedFilter == 'CLOSED') return audit.status.toUpperCase() == 'CLOSED' || audit.status.toUpperCase() == 'PAID';

      return true;
    }).toList();

    // ── Pagination Logic ──────────────────────────────────────────────────
    final int totalPages = (filteredAudits.length / _pageSize).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final int startIndex = (_currentPage - 1) * _pageSize;
    final List<Audit> paginatedAudits = filteredAudits.skip(startIndex).take(_pageSize).toList();

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Audits'],
      showBackButton: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Header
          Text(
            'My Audits',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'View and manage all active audit cases opened against your tax account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // ── KPI CARDS ROW (Responsive Layout) ────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 600;
              final cards = [
                _buildKPICard(
                  title: 'Total Cases',
                  value: '$totalCases',
                  icon: Icons.folder_open,
                  color: Colors.blue,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
                _buildKPICard(
                  title: 'Action Required',
                  value: '$actionRequiredCount',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
                _buildKPICard(
                  title: 'Outstanding Fine',
                  value: _formatAmount(totalOutstanding),
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.red,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards.map((card) => Expanded(child: card)).toList(),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(children: cards),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ── SEARCH BAR ────────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by case no, type, tax type...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 16),

          // ── FILTER CHIPS ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Cases'),
                _buildFilterChip('ACTION', 'Action Required'),
                _buildFilterChip('ACTIVE', 'Active'),
                _buildFilterChip('CLOSED', 'Closed'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── AUDITS LIST ───────────────────────────────────────────────────
          if (portalProv.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (paginatedAudits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No audit cases match your criteria.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginatedAudits.length,
              itemBuilder: (context, index) {
                final audit = paginatedAudits[index];
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
                  elevation: reqAction ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header (Responsive text wrapping & spacing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
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
                                        overflow: TextOverflow.ellipsis,
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
                            ),
                            const SizedBox(width: 12),
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
                        const SizedBox(height: 16),

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

                        const SizedBox(height: 16),

                        // Actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/audit-details',
                                  arguments: audit.id,
                                );
                              },
                              icon: const Icon(Icons.visibility, size: 14),
                              label: const Text('View Details', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            
            // ── PAGINATION BAR ────────────────────────────────────────────────
            if (totalPages > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    double? width = 150,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = value;
              _currentPage = 1;
            });
          }
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
