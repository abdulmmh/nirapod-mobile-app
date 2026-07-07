import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../widgets/portal_shell.dart';

class VatReturnsScreen extends StatefulWidget {
  const VatReturnsScreen({Key? key}) : super(key: key);

  @override
  State<VatReturnsScreen> createState() => _VatReturnsScreenState();
}

class _VatReturnsScreenState extends State<VatReturnsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = ['All', 'Accepted', 'Submitted', 'Draft'];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2);
    return formatter.format(amount);
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppColors.success;
      case 'submitted':
        return AppColors.info;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);
    final returns = portalProv.vatReturns;

    // Filter Logic
    final filteredReturns = returns.where((r) {
      final matchesSearch = r.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.returnNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.binNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.periodMonth.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.periodYear.contains(_searchQuery);

      final matchesStatus = _statusFilter == 'All' || r.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    // Stats
    final double totalVatPaid = returns
        .where((r) => r.status.toLowerCase() == 'accepted' || r.status.toLowerCase() == 'submitted')
        .fold(0.0, (sum, r) => sum + r.taxPaid);

    final isMobile = MediaQuery.of(context).size.width < 900;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'VAT Returns'],
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VAT Returns',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track filed monthly VAT returns and tax calculations',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // KPI Cards row
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;
                final list = [
                  _buildKpiCard('Total Returns Filed', returns.length.toString(), Icons.history, Colors.blue, cardWidth),
                  _buildKpiCard('Total VAT Paid', _formatCurrency(totalVatPaid), Icons.account_balance_wallet, AppColors.success, cardWidth),
                  _buildKpiCard('Accepted Returns', returns.where((r) => r.status.toLowerCase() == 'accepted').length.toString(), Icons.check_circle_outline, Colors.teal, cardWidth),
                ];

                if (isMobile) {
                  return Column(
                    children: list.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: list,
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Filters Box
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter Returns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final childs = [
                          // Search Box
                          SizedBox(
                            width: isMobile ? double.infinity : constraints.maxWidth * 0.6,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search by Return No, Month, Year, BIN...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          if (isMobile) const SizedBox(height: 10),
                          // Status dropdown
                          SizedBox(
                            width: isMobile ? double.infinity : constraints.maxWidth * 0.35,
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: _statusOptions.map((opt) {
                                return DropdownMenuItem(value: opt, child: Text(opt));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _statusFilter = val);
                                }
                              },
                            ),
                          ),
                        ];

                        if (isMobile) {
                          return Column(children: childs);
                        } else {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: childs,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            filteredReturns.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Center(
                        child: Text(
                          'No VAT returns match the filter criteria.',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredReturns.length,
                    itemBuilder: (context, index) {
                      final r = filteredReturns[index];
                      final statusColor = _getStatusColor(r.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.periodMonth} ${r.periodYear} Return',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(r.businessName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      r.status,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Info items Grid
                              GridView.count(
                                crossAxisCount: isMobile ? 2 : 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 2.5,
                                children: [
                                  _buildInfoItem('Return Number', r.returnNo, isMonospace: true),
                                  _buildInfoItem('BIN Number', r.binNo, isMonospace: true),
                                  _buildInfoItem('Taxable Supplies', _formatCurrency(r.taxableSupplies)),
                                  _buildInfoItem('Exempt Supplies', _formatCurrency(r.exemptSupplies)),
                                  _buildInfoItem('Output VAT', _formatCurrency(r.outputTax)),
                                  _buildInfoItem('Input VAT Credit', _formatCurrency(r.inputTax)),
                                  _buildInfoItem('Net VAT Payable', _formatCurrency(r.netTaxPayable)),
                                  _buildInfoItem('Submission Date', _formatDate(r.submissionDate)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 6),

                              // Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Downloading VAT Return Form 9.1 for Period ${r.periodMonth} ${r.periodYear}...'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.download, size: 14),
                                    label: const Text('Download Form 9.1', style: TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue.shade800,
                                      side: BorderSide(color: Colors.blue.shade100),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Viewing return details for ${r.returnNo} (Simulation)'),
                                          backgroundColor: AppColors.info,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility, size: 14),
                                    label: const Text('View Details', style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade800,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        isMonospace
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              )
            : Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
      ],
    );
  }
}
