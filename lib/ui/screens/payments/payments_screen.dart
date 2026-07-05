import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();
  String _searchQuery = '';
  String _selectedStatus = 'All'; // 'All', 'Pending', 'Under Review', 'Completed', 'Failed'
  
  String _statusFilter = ''; // '' means All Statuses
  String _typeFilter = ''; // '' means All Types
  String _yearFilter = ''; // '' means All Years

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '৳ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '৳ ${(amount / 100000).toStringAsFixed(2)} L';
    }
    final formatter = NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0);
    return formatter.format(amount);
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((p) {
      final q = _searchQuery.toLowerCase().trim();
      final txn = p.challanNo.toLowerCase();
      final type = (p.paymentType ?? '').toLowerCase();
      final ref = (p.referenceNo ?? '').toLowerCase();
      final bank = (p.bankName ?? '').toLowerCase();
      final tin = (p.tinNumber ?? '').toLowerCase();
      final name = (p.taxpayerName ?? '').toLowerCase();

      final matchesQuery = q.isEmpty ||
          txn.contains(q) ||
          type.contains(q) ||
          ref.contains(q) ||
          bank.contains(q) ||
          tin.contains(q) ||
          name.contains(q);

      final activeStatusFilter = _selectedStatus != 'All' ? _selectedStatus : _statusFilter;
      final matchesStatus = activeStatusFilter.isEmpty ||
          p.status.toLowerCase() == activeStatusFilter.toLowerCase() ||
          (activeStatusFilter.toLowerCase() == 'completed' && p.status.toLowerCase() == 'success') ||
          (activeStatusFilter.toLowerCase() == 'completed' && p.status.toLowerCase() == 'completed') ||
          (activeStatusFilter.toLowerCase() == 'success' && p.status.toLowerCase() == 'success') ||
          (activeStatusFilter.toLowerCase() == 'success' && p.status.toLowerCase() == 'completed');

      final matchesType = _typeFilter.isEmpty ||
          (p.paymentType ?? '').toLowerCase().contains(_typeFilter.toLowerCase());

      final paymentDate = p.date ?? p.paymentDate ?? '';
      final matchesYear = _yearFilter.isEmpty ||
          paymentDate.contains(_yearFilter);

      return matchesQuery && matchesStatus && matchesType && matchesYear;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);
    final totalPayments = portalProv.payments;
    final isMobile = MediaQuery.of(context).size.width < 900;

    final filteredList = _filterPayments(totalPayments);

    final pendingCount = totalPayments.where((p) => p.status.toLowerCase() == 'pending').length;
    final underReviewCount = totalPayments.where((p) => p.status.toLowerCase() == 'under review').length;
    final completedCount = totalPayments.where((p) => p.status.toLowerCase() == 'success' || p.status.toLowerCase() == 'completed').length;
    final failedCount = totalPayments.where((p) => p.status.toLowerCase() == 'failed').length;

    final double totalCollected = totalPayments
        .where((p) => p.status.toLowerCase() == 'success' || p.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, item) => sum + item.amount);

    final kpiCards = [
      _buildKpiCard(
        label: 'Pending',
        value: '$pendingCount',
        icon: Icons.hourglass_empty,
        color: Colors.amber.shade800,
        context: context,
        isMobile: isMobile,
      ),
      _buildKpiCard(
        label: 'Under Review',
        value: '$underReviewCount',
        icon: Icons.search,
        color: Colors.purple.shade700,
        context: context,
        isMobile: isMobile,
      ),
      _buildKpiCard(
        label: 'Completed',
        value: '$completedCount',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        context: context,
        isMobile: isMobile,
      ),
      _buildKpiCard(
        label: 'Failed',
        value: '$failedCount',
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        context: context,
        isMobile: isMobile,
      ),
      _buildKpiCard(
        label: 'Total Collected',
        value: _formatCurrency(totalCollected),
        icon: Icons.monetization_on_outlined,
        color: Colors.blue.shade700,
        isClickable: false,
        context: context,
        isMobile: isMobile,
      ),
    ];

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Payments'],
      showBackButton: true,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/payment-create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.payment_outlined),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header Block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Management',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track and manage all tax payments and transactions.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/payment-create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Cards Section (Stretching Row on Desktop, Wrapping Column Rows on Mobile)
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: kpiCards[0]),
                          const SizedBox(width: 8),
                          Expanded(child: kpiCards[1]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: kpiCards[2]),
                          const SizedBox(width: 8),
                          Expanded(child: kpiCards[3]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: kpiCards[4]),
                        ],
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: kpiCards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[1]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[2]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[3]),
                        const SizedBox(width: 12),
                        Expanded(child: kpiCards[4]),
                      ],
                    ),
                  ),
            const SizedBox(height: 20),

            // Search & Filter Dropdowns Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Transaction ID, taxpayer, TIN, type, reference...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Dropdowns
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDropdownWrapper(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _statusFilter.isEmpty ? 'All Statuses' : _statusFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                  items: ['All Statuses', 'Pending', 'Under Review', 'Completed', 'Failed']
                                      .map((val) => DropdownMenuItem<String>(
                                            value: val,
                                            child: Text(val),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _statusFilter = val == 'All Statuses' ? '' : val!;
                                      _selectedStatus = 'All';
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdownWrapper(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _typeFilter.isEmpty ? 'All Types' : _typeFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                  items: ['All Types', 'VAT', 'Income Tax', 'Penalty']
                                      .map((val) => DropdownMenuItem<String>(
                                            value: val,
                                            child: Text(val),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _typeFilter = val == 'All Types' ? '' : val!;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDropdownWrapper(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _yearFilter.isEmpty ? 'All Years' : _yearFilter,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                  items: ['All Years', '2026', '2025', '2024']
                                      .map((val) => DropdownMenuItem<String>(
                                            value: val,
                                            child: Text(val),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _yearFilter = val == 'All Years' ? '' : val!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownWrapper(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _statusFilter.isEmpty ? 'All Statuses' : _statusFilter,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                                        items: ['All Statuses', 'Pending', 'Under Review', 'Completed', 'Failed']
                                            .map((val) => DropdownMenuItem<String>(
                                                  value: val,
                                                  child: Text(val),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _statusFilter = val == 'All Statuses' ? '' : val!;
                                            _selectedStatus = 'All';
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdownWrapper(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _typeFilter.isEmpty ? 'All Types' : _typeFilter,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                                        items: ['All Types', 'VAT', 'Income Tax', 'Penalty']
                                            .map((val) => DropdownMenuItem<String>(
                                                  value: val,
                                                  child: Text(val),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _typeFilter = val == 'All Types' ? '' : val!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDropdownWrapper(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _yearFilter.isEmpty ? 'All Years' : _yearFilter,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                                        items: ['All Years', '2026', '2025', '2024']
                                            .map((val) => DropdownMenuItem<String>(
                                                  value: val,
                                                  child: Text(val),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _yearFilter = val == 'All Years' ? '' : val!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Filter Badge
            if (_selectedStatus != 'All' || _statusFilter.isNotEmpty || _typeFilter.isNotEmpty || _yearFilter.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Active Filters: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedStatus != 'All')
                      _buildFilterChip(_selectedStatus, () => setState(() => _selectedStatus = 'All')),
                    if (_statusFilter.isNotEmpty)
                      _buildFilterChip(_statusFilter, () => setState(() => _statusFilter = '')),
                    if (_typeFilter.isNotEmpty)
                      _buildFilterChip(_typeFilter, () => setState(() => _typeFilter = '')),
                    if (_yearFilter.isNotEmpty)
                      _buildFilterChip(_yearFilter, () => setState(() => _yearFilter = '')),
                  ],
                ),
              ),

            // List / Table results
            if (filteredList.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.credit_card_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No payments found.', style: TextStyle(color: Colors.black54, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )
            else
              isMobile
                  ? _buildMobileList(filteredList, theme)
                  : _buildDesktopTable(filteredList, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownWrapper({required Widget child}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal.shade700,
        onDeleted: onDeleted,
        deleteIconColor: Colors.white,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildMobileList(List<Payment> list, ThemeData theme) {
    return Column(
      children: List.generate(list.length, (index) {
        final payment = list[index];
        final isSuccess = payment.status.toLowerCase() == 'success' || payment.status.toLowerCase() == 'completed';
        final isUnderReview = payment.status.toLowerCase() == 'under review';
        final isFailed = payment.status.toLowerCase() == 'failed';

        Color statusColor = AppColors.warning;
        if (isSuccess) statusColor = AppColors.success;
        if (isUnderReview) statusColor = Colors.purple;
        if (isFailed) statusColor = AppColors.error;

        Color typeColor = Colors.grey.shade600;
        final pType = payment.paymentType ?? 'Other';
        if (pType.toLowerCase().contains('vat')) typeColor = Colors.teal;
        if (pType.toLowerCase().contains('income tax')) typeColor = Colors.blue.shade700;
        if (pType.toLowerCase().contains('penalty')) typeColor = Colors.orange.shade700;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Avatar, Name, Transaction ID, Status
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (payment.taxpayerName ?? 'A').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.taxpayerName ?? 'Abdul Karim',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                      Text(
                            payment.challanNo,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payment.status,
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
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Fields list
                _buildMobileFieldRow('TIN', payment.tinNumber ?? '—'),
                _buildMobileFieldRow(
                  'TYPE',
                  pType,
                  hasBadge: true,
                  badgeColor: typeColor.withOpacity(0.1),
                  badgeTextColor: typeColor,
                ),
                _buildMobileFieldRow('AMOUNT', _formatCurrency(payment.amount), isBold: true),
                _buildMobileFieldRow('METHOD', payment.paymentMethod ?? '—'),
                _buildMobileFieldRow('BANK', payment.bankName ?? '—'),
                _buildMobileFieldRow('REFERENCE', payment.referenceNo ?? '—', isMonospace: true),
                _buildMobileFieldRow('DATE', payment.date ?? payment.paymentDate ?? '—'),
                
                const SizedBox(height: 16),

                // View Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/payment-details',
                      arguments: payment,
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade900,
                    backgroundColor: Colors.blue.shade50.withOpacity(0.5),
                    side: BorderSide(color: Colors.blue.shade100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMobileFieldRow(
    String label,
    String value, {
    bool hasBadge = false,
    Color? badgeColor,
    Color? badgeTextColor,
    bool isBold = false,
    bool isMonospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          hasBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: badgeTextColor ?? Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: Colors.black87,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Payment> list, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          controller: _tableScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _tableScrollController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              dataRowHeight: 64,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Taxpayer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Reference No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Payment Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: List.generate(list.length, (index) {
                final p = list[index];
                final isSuccess = p.status.toLowerCase() == 'success' || p.status.toLowerCase() == 'completed';
                final isUnderReview = p.status.toLowerCase() == 'under review';
                final isFailed = p.status.toLowerCase() == 'failed';

                Color statusColor = AppColors.warning;
                if (isSuccess) statusColor = AppColors.success;
                if (isUnderReview) statusColor = Colors.purple;
                if (isFailed) statusColor = AppColors.error;

                Color typeColor = Colors.grey.shade600;
                final pType = p.paymentType ?? 'Other';
                if (pType.toLowerCase().contains('vat')) typeColor = Colors.teal;
                if (pType.toLowerCase().contains('income tax')) typeColor = Colors.blue.shade700;
                if (pType.toLowerCase().contains('penalty')) typeColor = Colors.orange.shade700;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.challanNo,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (p.taxpayerName ?? 'A').substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.taxpayerName ?? 'Abdul Karim', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(p.tinNumber ?? 'TIN-00000000', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pType,
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(p.paymentMethod ?? 'N/A', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCurrency(p.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    DataCell(Text(p.bankName ?? 'N/A', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(p.referenceNo ?? 'N/A', style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                    DataCell(Text(p.date ?? p.paymentDate ?? 'N/A', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/payment-details',
                                arguments: p,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isClickable = true,
    required BuildContext context,
    required bool isMobile,
  }) {
    final isSelected = _selectedStatus == label;

    return GestureDetector(
      onTap: isClickable
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedStatus = 'All';
                } else {
                  _selectedStatus = label;
                }
              });
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isClickable && isSelected)
              Icon(Icons.check_circle, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}
