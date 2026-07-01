import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({Key? key}) : super(key: key);

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String _searchQuery = '';
  String _statusFilter = '';
  String _typeFilter = '';
  String _categoryFilter = '';

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
    final portalProv = Provider.of<PortalProvider>(context);
    final businesses = portalProv.businesses;

    // Calculations for KPI Cards
    final int activeCount = businesses.where((b) => b.vatStatus.toLowerCase() == 'active').length;
    final int pendingCount = businesses.where((b) => b.vatStatus.toLowerCase() == 'pending').length;
    final int suspendedCount = businesses.where((b) => b.vatStatus.toLowerCase() == 'suspended').length;
    final int expiringCount = businesses.where((b) {
      if (b.expiryDate == null) return false;
      try {
        final expDate = DateTime.parse(b.expiryDate!);
        return expDate.difference(DateTime.now()).inDays < 30 && expDate.isAfter(DateTime.now());
      } catch (_) {
        return false;
      }
    }).length;

    final double totalActiveTurnover = businesses
        .where((b) => b.vatStatus.toLowerCase() == 'active' && b.annualTurnover != null)
        .fold(0.0, (sum, b) => sum + b.annualTurnover!);

    // Filter Logic
    final filteredBusinesses = businesses.where((b) {
      final matchesSearch = b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.tradeLicenseNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (b.ownerName != null && b.ownerName!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (b.tinNumber != null && b.tinNumber!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesStatus = _statusFilter.isEmpty || b.vatStatus.toLowerCase() == _statusFilter.toLowerCase();
      final matchesType = _typeFilter.isEmpty || (b.businessType != null && b.businessType!.toLowerCase() == _typeFilter.toLowerCase());
      final matchesCategory = _categoryFilter.isEmpty || (b.businessCategory != null && b.businessCategory!.toLowerCase() == _categoryFilter.toLowerCase());

      return matchesSearch && matchesStatus && matchesType && matchesCategory;
    }).toList();

    // Distinct Types and Categories for filters
    final types = businesses.map((b) => b.businessType).whereType<String>().toSet().toList();
    final categories = businesses.map((b) => b.businessCategory).whereType<String>().toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Registration'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // reload data
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header
              Text(
                'Business Registration',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage all registered businesses and trade licenses.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // KPI Cards Grid (Matching Screenshot layout)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildKpiCard('Active', '$activeCount', Icons.check_circle_fill, AppColors.success, isDark),
                  _buildKpiCard('Pending', '$pendingCount', Icons.hourglass_empty_rounded, AppColors.warning, isDark),
                  _buildKpiCard('Suspended', '$suspendedCount', Icons.remove_circle_outline, AppColors.error, isDark),
                  _buildKpiCard('Expiring Soon', '$expiringCount', Icons.warning_amber_rounded, Colors.orange, isDark),
                ],
              ),
              const SizedBox(height: 12),
              _buildWideKpiCard('Active Turnover', _formatCurrency(totalActiveTurnover), Icons.monetization_on, AppColors.primary, isDark),
              const SizedBox(height: 24),

              // Search & Filter Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Search field
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 20),
                        hintText: 'Search by name, license, owner, TIN...',
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Filter dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            'All Statuses',
                            _statusFilter,
                            ['Active', 'Pending', 'Suspended'],
                            (val) => setState(() => _statusFilter = val ?? ''),
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterDropdown(
                            'All Types',
                            _typeFilter,
                            types,
                            (val) => setState(() => _typeFilter = val ?? ''),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Business Cards List
              filteredBusinesses.isEmpty
                  ? const Center(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No business structures registered matching filters.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBusinesses.length,
                      itemBuilder: (context, index) {
                        final biz = filteredBusinesses[index];
                        return _buildBusinessCard(context, biz, isDark, theme);
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/business-create');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideKpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary.shade900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    String selectedValue,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            ...items.map((i) => DropdownMenuItem<String>(value: i, child: Text(i, style: TextStyle(color: isDark ? Colors.white : Colors.black87)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, Business biz, bool isDark, ThemeData theme) {
    Color statusColor = AppColors.success;
    if (biz.vatStatus.toLowerCase() == 'pending') {
      statusColor = AppColors.warning;
    } else if (biz.vatStatus.toLowerCase() == 'suspended') {
      statusColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        biz.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BUS-${biz.tradeLicenseNo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').substring(0, 6).toUpperCase()}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    biz.vatStatus,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),

          // Key Value Lists (matches Screenshot 110201 detail list exactly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildCardRow('OWNER', biz.ownerName ?? 'Tasrif Zaman'),
                _buildCardRow('TIN', biz.tinNumber ?? 'TIN-000000005', isMonospace: true),
                _buildCardRow('TYPE', biz.businessType ?? 'Textile Manufacturing'),
                _buildCardRow('CATEGORY', biz.businessCategory ?? 'Garments & Textile'),
                _buildCardRow('DIVISION', biz.division ?? 'Dhaka'),
                _buildCardRow('DISTRICT', biz.district ?? 'Dhaka'),
                _buildCardRow('TURNOVER', biz.annualTurnover != null ? _formatCurrency(biz.annualTurnover!) : 'N/A'),
                _buildCardRow('EMPLOYEES', biz.numberOfEmployees != null ? '${biz.numberOfEmployees}' : '0'),
                _buildCardRow('EXPIRY', biz.expiryDate ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // View Details Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.08),
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/business-details', arguments: biz);
              },
              icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
              label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

