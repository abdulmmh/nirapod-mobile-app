import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_card.dart';
import 'ait_details_screen.dart';
import 'ait_wizard_screen.dart';
import '../../widgets/portal_shell.dart';

class AitScreen extends StatefulWidget {
  const AitScreen({Key? key}) : super(key: key);

  @override
  State<AitScreen> createState() => _AitScreenState();
}

class _AitScreenState extends State<AitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _challanController = TextEditingController();

  String _selectedStatusFilter = 'All';
  String _selectedSourceFilter = 'All';
  String _searchQuery = '';
  final ScrollController _tableScrollController = ScrollController();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _challanController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }



  Map<String, dynamic> _getSourceInfo(String source) {
    final s = source.toUpperCase();
    if (s.contains('IMPORT')) {
      return {
        'label': 'Import Duty',
        'bg': const Color(0xFFE0F2F9),
        'text': const Color(0xFF0891B2),
        'icon': Icons.local_shipping_outlined,
      };
    } else if (s.contains('SUPPLIER')) {
      return {
        'label': 'Supplier Payment',
        'bg': const Color(0xFFE8EEF9),
        'text': const Color(0xFF1A3F8F),
        'icon': Icons.business_outlined,
      };
    } else if (s.contains('SALARY')) {
      return {
        'label': 'Salary Deduction',
        'bg': const Color(0xFFE6F7F3),
        'text': const Color(0xFF1FAA8B),
        'icon': Icons.badge_outlined,
      };
    } else if (s.contains('CONTRACTOR')) {
      return {
        'label': 'Contractor Payment',
        'bg': const Color(0xFFFEF3E2),
        'text': const Color(0xFFF59E0B),
        'icon': Icons.construction_outlined,
      };
    } else if (s.contains('RENT')) {
      return {
        'label': 'Rent Payment',
        'bg': const Color(0xFFFCE7F3),
        'text': const Color(0xFFBE185D),
        'icon': Icons.home_outlined,
      };
    } else if (s.contains('BANK')) {
      return {
        'label': source,
        'bg': const Color(0xFFE6F7F3),
        'text': const Color(0xFF1FAA8B),
        'icon': Icons.account_balance_outlined,
      };
    } else {
      return {
        'label': source,
        'bg': const Color(0xFFE8EEF9),
        'text': const Color(0xFF1A3F8F),
        'icon': Icons.receipt_long_outlined,
      };
    }
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    final s = status.toUpperCase();
    if (s.contains('DRAFT')) {
      return {
        'label': 'Draft',
        'bg': const Color(0xFFF3F4F6),
        'text': const Color(0xFF6B7280),
      };
    } else if (s.contains('SUBMITTED')) {
      return {
        'label': 'Submitted',
        'bg': const Color(0xFFDBEAFE),
        'text': const Color(0xFF1D4ED8),
      };
    } else if (s.contains('PENDING')) {
      return {
        'label': 'Pending Review',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFF92400E),
      };
    } else if (s.contains('REVIEW') || s.contains('UNDER')) {
      return {
        'label': 'Under Review',
        'bg': const Color(0xFFEDE9FE),
        'text': const Color(0xFF5B21B6),
      };
    } else if (s.contains('APPROV') || s.contains('VERIFIED')) {
      return {
        'label': 'Approved',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF166534),
      };
    } else if (s.contains('REJECT')) {
      return {
        'label': 'Rejected',
        'bg': const Color(0xFFFEE2E2),
        'text': const Color(0xFF991B1B),
      };
    } else if (s.contains('CREDIT')) {
      return {
        'label': 'Credited',
        'bg': const Color(0xFFD1FAE5),
        'text': const Color(0xFF065F46),
      };
    } else {
      return {
        'label': status,
        'bg': const Color(0xFFF3F4F6),
        'text': const Color(0xFF6B7280),
      };
    }
  }



  Widget _buildKpiRow(List<AitRecord> aits, BuildContext context) {
    final totalCount = aits.length;
    final approvedCount = aits.where((a) {
      final s = a.status.toUpperCase();
      return s == 'APPROVED' || s == 'VERIFIED';
    }).length;
    final pendingCount = aits.where((a) {
      final s = a.status.toUpperCase();
      return s == 'PENDING' || s == 'PENDING REVIEW' || s == 'PENDING_REVIEW' || s == 'SUBMITTED' || s == 'UNDER_REVIEW';
    }).length;
    final creditedCount = aits.where((a) => a.status.toUpperCase() == 'CREDITED').length;
    final totalAmount = aits.where((a) {
      final s = a.status.toUpperCase();
      return s != 'REJECTED' && s != 'DRAFT';
    }).fold<double>(0.0, (sum, item) => sum + item.amount);

    final widgets = [
      StatCard(
        title: 'Total Records',
        value: '$totalCount',
        icon: Icons.receipt_long_outlined,
        iconColor: AppColors.primary,
        subtext: 'AIT submissions',
        onTap: () => setState(() => _selectedStatusFilter = 'All'),
        isSelected: _selectedStatusFilter == 'All',
      ),
      StatCard(
        title: 'Approved',
        value: '$approvedCount',
        icon: Icons.verified_outlined,
        iconColor: AppColors.success,
        subtext: 'Challan verified',
        onTap: () => setState(() => _selectedStatusFilter = 'Approved'),
        isSelected: _selectedStatusFilter == 'Approved',
      ),
      StatCard(
        title: 'Pending Review',
        value: '$pendingCount',
        icon: Icons.hourglass_empty_rounded,
        iconColor: AppColors.warning,
        subtext: 'Awaiting officer',
        onTap: () => setState(() => _selectedStatusFilter = 'Pending'),
        isSelected: _selectedStatusFilter == 'Pending',
      ),
      StatCard(
        title: 'Credited to ITR',
        value: '$creditedCount',
        icon: Icons.assignment_turned_in_outlined,
        iconColor: Colors.teal,
        subtext: 'Adjusted in return',
        onTap: () => setState(() => _selectedStatusFilter = 'Credited'),
        isSelected: _selectedStatusFilter == 'Credited',
      ),
      StatCard(
        title: 'Total Claimed',
        value: NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(totalAmount),
        icon: Icons.payments_outlined,
        iconColor: Colors.purple,
        subtext: 'Approved & pending',
        accentColor: Colors.purple,
      ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 900;

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
    final statusOptions = ['All', 'Draft', 'Submitted', 'Pending Review', 'Under Review', 'Approved', 'Rejected', 'Credited'];
    final sourceOptions = ['All', 'Import Duty', 'Supplier Payment', 'Salary Deduction', 'Contractor Payment', 'Rent Payment', 'Bank Interest', 'Vehicle Registration'];

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
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by reference no, source, challan...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSourceFilter,
                        decoration: const InputDecoration(labelText: 'Source Type', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: sourceOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setState(() => _selectedSourceFilter = val ?? 'All'),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedStatusFilter,
                      decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'All'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSourceFilter,
                      decoration: const InputDecoration(labelText: 'Source Type', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      items: sourceOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _selectedSourceFilter = val ?? 'All'),
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
              'No AIT records match your filter.',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting search queries or claiming a new AIT record.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    final taxpayerId = auth.currentUser?.taxpayerId ?? 0;

    // Filter logic
    final filteredAits = portalProv.aits.where((ait) {
      if (_selectedStatusFilter != 'All') {
        final key = _selectedStatusFilter.toUpperCase();
        final status = ait.status.toUpperCase();
        if (key == 'APPROVED') {
          if (status != 'APPROVED' && status != 'VERIFIED') return false;
        } else if (key == 'PENDING REVIEW') {
          if (status != 'PENDING' && status != 'PENDING REVIEW' && status != 'PENDING_REVIEW') return false;
        } else {
          if (status != key) return false;
        }
      }

      if (_selectedSourceFilter != 'All') {
        final key = _selectedSourceFilter.toUpperCase();
        final source = ait.source.toUpperCase();
        if (key == 'IMPORT DUTY' && !source.contains('IMPORT')) return false;
        if (key == 'SUPPLIER PAYMENT' && !source.contains('SUPPLIER')) return false;
        if (key == 'SALARY DEDUCTION' && !source.contains('SALARY')) return false;
        if (key == 'CONTRACTOR PAYMENT' && !source.contains('CONTRACTOR')) return false;
        if (key == 'RENT PAYMENT' && !source.contains('RENT')) return false;
        if (key == 'BANK INTEREST' && !source.contains('BANK')) return false;
        if (key == 'VEHICLE REGISTRATION' && !source.contains('VEHICLE')) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final ref = 'ait-ref-${ait.id}';
        final source = ait.source.toLowerCase();
        final challan = ait.challanNo.toLowerCase();
        final status = ait.status.toLowerCase();
        return ref.contains(query) || source.contains(query) || challan.contains(query) || status.contains(query);
      }
      return true;
    }).toList();

    return PortalShell(
      breadcrumbs: const ['My Portal', 'AIT'],
      showBackButton: true,
      floatingActionButton: screenWidth < 600
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AitWizardScreen(
                    taxpayerId: taxpayerId,
                    taxpayerName: auth.currentUser?.fullName ?? 'Tasrif Zaman',
                    tinNumber: auth.currentUser?.tinNumber ?? 'TIN-000000005',
                  ),
                ),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advance Income Tax (AIT)',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and track all AIT submissions and credits.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (screenWidth >= 600)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AitWizardScreen(
                        taxpayerId: taxpayerId,
                        taxpayerName: auth.currentUser?.fullName ?? 'Tasrif Zaman',
                        tinNumber: auth.currentUser?.tinNumber ?? 'TIN-000000005',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New AIT Record', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Row
          _buildKpiRow(portalProv.aits, context),
          const SizedBox(height: 20),

          // Filter Section
          _buildFilterSection(isDark, theme),
          const SizedBox(height: 20),

          // Content body
          filteredAits.isEmpty
              ? _buildEmptyState(theme, isDark)
              : (screenWidth >= 760
                  ? _buildDesktopTable(filteredAits, isDark, theme)
                  : _buildMobileCardList(filteredAits, isDark, theme)),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<AitRecord> filteredAits, bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          controller: _tableScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _tableScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(isDark ? Colors.grey.shade900 : Colors.grey.shade50),
              dataRowHeight: 64,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Reference No')),
                DataColumn(label: Text('Source Type')),
                DataColumn(label: Text('Challan')),
                DataColumn(label: Text('AIT Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Actions')),
              ],
              rows: List.generate(filteredAits.length, (index) {
                final ait = filteredAits[index];
                final sourceInfo = _getSourceInfo(ait.source);
                final statusInfo = _getStatusInfo(ait.status);

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          ait.challanNo.isNotEmpty ? 'AIT-REF-${ait.id}' : 'Draft-REF',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3F8F),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sourceInfo['bg'],
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sourceInfo['icon'], size: 12, color: sourceInfo['text']),
                            const SizedBox(width: 4),
                            Text(
                              sourceInfo['label'],
                              style: TextStyle(
                                color: sourceInfo['text'],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ait.status.toLowerCase() == 'verified' || ait.status.toLowerCase() == 'approved'
                                ? Icons.verified
                                : Icons.history_toggle_off_rounded,
                            size: 14,
                            color: ait.status.toLowerCase() == 'verified' || ait.status.toLowerCase() == 'approved'
                                ? const Color(0xFF1FAA8B)
                                : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ait.challanNo,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(ait.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3F8F)),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusInfo['bg'],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusInfo['label'],
                          style: TextStyle(color: statusInfo['text'], fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(Text(ait.date ?? 'N/A')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.visibility, size: 14),
                            label: const Text('View'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AitDetailsScreen(aitId: ait.id)),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<AitRecord> filteredAits, bool isDark, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAits.length,
      itemBuilder: (context, index) {
        final ait = filteredAits[index];
        final sourceInfo = _getSourceInfo(ait.source);
        final statusInfo = _getStatusInfo(ait.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
          ),
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        ait.challanNo.isNotEmpty ? 'AIT-REF-${ait.id}' : 'Draft-REF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3F8F),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo['bg'],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusInfo['label'],
                        style: TextStyle(color: statusInfo['text'], fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildMobileField('Source', Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sourceInfo['bg'],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sourceInfo['icon'], size: 11, color: sourceInfo['text']),
                      const SizedBox(width: 4),
                      Text(
                        sourceInfo['label'],
                        style: TextStyle(
                          color: sourceInfo['text'],
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
                _buildMobileField('Challan', Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ait.status.toLowerCase() == 'verified' || ait.status.toLowerCase() == 'approved'
                          ? Icons.verified
                          : Icons.history_toggle_off_rounded,
                      size: 13,
                      color: ait.status.toLowerCase() == 'verified' || ait.status.toLowerCase() == 'approved'
                          ? const Color(0xFF1FAA8B)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ait.challanNo,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ],
                )),
                const SizedBox(height: 8),
                _buildMobileField('Date', Text(ait.date ?? 'N/A', style: const TextStyle(fontSize: 12))),
                const SizedBox(height: 8),
                _buildMobileField('AIT Amount', Text(
                  NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(ait.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3F8F), fontSize: 14),
                )),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 14),
                      label: const Text('View'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AitDetailsScreen(aitId: ait.id)),
                      ),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileField(String label, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        child,
      ],
    );
  }
}
