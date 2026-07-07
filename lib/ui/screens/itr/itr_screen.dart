import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_card.dart';
import 'itr_details_screen.dart';
import 'itr_wizard_screen.dart';
import '../../widgets/portal_shell.dart';

class ItrScreen extends StatefulWidget {
  const ItrScreen({Key? key}) : super(key: key);

  @override
  State<ItrScreen> createState() => _ItrScreenState();
}

class _ItrScreenState extends State<ItrScreen> {
  String searchQuery = '';
  String statusFilter = 'All';
  String categoryFilter = 'All';
  final ScrollController _tableScrollController = ScrollController();

  final List<String> statusOptions = ['All', 'Draft', 'Submitted', 'Under Review', 'Accepted', 'Rejected', 'Send Back'];
  final List<String> categoryOptions = ['All', 'Individual', 'Company', 'Partnership', 'NGO'];

  @override
  void dispose() {
    _tableScrollController.dispose();
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
    
    final taxpayerId = auth.currentUser?.taxpayerId ?? 0;
    final taxpayerName = auth.currentUser?.fullName ?? 'Tasrif Zaman';
    final tinNumber = auth.currentUser?.tinNumber ?? 'TIN-000000005';

    // Calculate ITR stats
    final totalFiled = portalProv.itrs.length;
    final acceptedCount = portalProv.itrs.where((r) => r.status.toLowerCase() == 'accepted').length;
    final pendingCount = portalProv.itrs.where((r) => r.status.toLowerCase() == 'under review' || r.status.toLowerCase() == 'submitted').length;
    final draftCount = portalProv.itrs.where((r) => r.status.toLowerCase() == 'draft').length;
    final double totalTaxPaid = portalProv.itrs.fold(0.0, (sum, item) => sum + (item.taxPaid ?? 0.0) + (item.advanceTaxPaid ?? 0.0));

    // Filtered list
    final filteredItrs = portalProv.itrs.where((r) {
      final matchesSearch = (r.returnNo?.toLowerCase().contains(searchQuery.toLowerCase()) ?? true) ||
          r.assessmentYear.contains(searchQuery) ||
          (r.taxpayerName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? true);

      final matchesStatus = statusFilter == 'All' || r.status.toLowerCase() == statusFilter.toLowerCase();
      final matchesCategory = categoryFilter == 'All' || r.itrCategory?.toLowerCase() == categoryFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    return Theme(
      data: localTheme,
      child: PortalShell(
        breadcrumbs: const ['My Portal', 'ITR'],
        showBackButton: true,
        floatingActionButton: isMobile
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItrWizardScreen(taxpayerId: taxpayerId, taxpayerName: taxpayerName, tinNumber: tinNumber)),
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
        body: portalProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => portalProv.loadAllData(
                  taxpayerId,
                  auth.currentUser?.taxpayerType ?? 'Individual',
                  taxpayerName: taxpayerName,
                  tinNumber: tinNumber,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header title block matching NBR design
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income Tax Returns (ITR)',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Filing & calculations records',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (!isMobile)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ItrWizardScreen(taxpayerId: taxpayerId, taxpayerName: taxpayerName, tinNumber: tinNumber)),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('File New Return'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KPI Statistics Row
                    _buildKpiRow(isMobile, totalFiled, acceptedCount, pendingCount, draftCount, totalTaxPaid),
                    const SizedBox(height: 24),

                    // Filter & Search bar card
                    _buildFilterSection(isDark, theme),
                    const SizedBox(height: 20),

                    // List of ITR returns
                    filteredItrs.isEmpty
                        ? _buildEmptyState(theme, isDark)
                        : _buildListGrid(filteredItrs, isDark, theme),
                  ],
                ),
              ),
      ),
    );
  }

  // Horizontally scrollable row on mobile, grid/row on desktop
  Widget _buildKpiRow(bool isMobile, int total, int accepted, int pending, int drafts, double totalPaid) {
    final widgets = [
      StatCard(
        title: 'Total Filings',
        value: total.toString(),
        icon: Icons.assignment_outlined,
        iconColor: AppColors.primary,
        subtext: 'All periods',
        accentColor: AppColors.primary,
        onTap: () => setState(() => statusFilter = 'All'),
        isSelected: statusFilter == 'All',
      ),
      StatCard(
        title: 'Accepted',
        value: accepted.toString(),
        icon: Icons.verified_user_outlined,
        iconColor: AppColors.success,
        subtext: 'Verified by NBR',
        accentColor: AppColors.success,
        onTap: () => setState(() => statusFilter = 'Accepted'),
        isSelected: statusFilter == 'Accepted',
      ),
      StatCard(
        title: 'Pending Review',
        value: pending.toString(),
        icon: Icons.pending_actions_outlined,
        iconColor: AppColors.info,
        subtext: 'Under processing',
        accentColor: AppColors.info,
        onTap: () => setState(() => statusFilter = 'Under Review'),
        isSelected: statusFilter == 'Under Review',
      ),
      StatCard(
        title: 'Draft / Send Back',
        value: drafts.toString(),
        icon: Icons.edit_note_outlined,
        iconColor: AppColors.warning,
        subtext: 'Needs action',
        accentColor: AppColors.warning,
        onTap: () => setState(() => statusFilter = 'Draft'),
        isSelected: statusFilter == 'Draft',
      ),
      StatCard(
        title: 'Total Tax Contributed',
        value: _formatAmount(totalPaid),
        icon: Icons.payments_outlined,
        iconColor: Colors.purple,
        subtext: 'AIT & self-paid',
        accentColor: Colors.purple,
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: widgets[0]),
              const SizedBox(width: 8),
              Expanded(child: widgets[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: widgets[2]),
              const SizedBox(width: 8),
              Expanded(child: widgets[3]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: widgets[4]),
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: widgets[0]),
          const SizedBox(width: 12),
          Expanded(child: widgets[1]),
          const SizedBox(width: 12),
          Expanded(child: widgets[2]),
          const SizedBox(width: 12),
          Expanded(child: widgets[3]),
          const SizedBox(width: 12),
          Expanded(child: widgets[4]),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by Return No or Year...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: statusFilter,
                        decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => statusFilter = val ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: categoryFilter,
                        decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => categoryFilter = val ?? 'All'),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: statusFilter,
                      decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => statusFilter = val ?? 'All'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categoryFilter,
                      decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => categoryFilter = val ?? 'All'),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No returns match your filter.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting search queries or filing a new return.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListGrid(List<ItrRecord> list, bool isDark, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Desktop: 3 columns; Tablet: 2 columns; Mobile: 1 column
        final int crossAxisCount = width > 1100 ? 3 : (width > 680 ? 2 : 1);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 220,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final r = list[index];
            final statusColor = _getStatusColor(r.status);
            final netPayable = (r.grossTax ?? 0.0) - (r.rebate ?? 0.0);
            
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status top line accent
                    Container(
                      height: 4,
                      color: statusColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Return No & Status Badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  r.returnNo ?? 'Draft ITR',
                                  style: const TextStyle(
                                    color: Color(0xFF1E40AF),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Taxpayer name
                          Text(
                            r.taxpayerName ?? 'Tasrif Zaman',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TIN: ${r.tinNumber ?? '—'}  ·  AY: ${r.assessmentYear}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(color: Colors.grey.shade100, height: 1),
                          const SizedBox(height: 10),
                          
                          // Financial columns
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoCol('Gross Income', _formatAmount(r.grossIncome), theme, isDark),
                              _buildInfoCol('Net Tax', _formatAmount(netPayable), theme, isDark),
                              _buildInfoCol('Tax Paid', _formatAmount(r.taxPaid), theme, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Footer details button
                    InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ItrDetailsScreen(itrId: r.id)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF1E40AF)),
                            SizedBox(width: 6),
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCol(String label, String val, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
