import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../../providers/portal_provider.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user != null) {
      final taxpayerProv = Provider.of<TaxpayerProvider>(context, listen: false);
      await taxpayerProv.fetchProfile(user.taxpayerId, user.taxpayerType ?? 'Individual');
      
      if (mounted && user.taxpayerId != null) {
        final portalProv = Provider.of<PortalProvider>(context, listen: false);
        await portalProv.loadAllData(user.taxpayerId!, user.taxpayerType ?? 'Individual');
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0);
    if (amount >= 100000) {
      return '৳ ${(amount / 100000).toStringAsFixed(1)}L';
    }
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final auth = Provider.of<AuthProvider>(context);
    final taxpayerProv = Provider.of<TaxpayerProvider>(context);
    final portalProv = Provider.of<PortalProvider>(context);

    final taxpayer = taxpayerProv.taxpayer;
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String category = taxpayer?.taxpayerType?.category ?? user.taxpayerType ?? 'Individual';
    final String displayName = taxpayer?.fullName ?? taxpayer?.companyName ?? user.fullName;
    final String tinStr = taxpayer?.tin ?? user.tinNumber ?? 'N/A';
    final String approvalStatus = taxpayer?.approvalStatus ?? user.approvalStatus ?? 'Pending';

    // Calculation of dues from returns
    double outstandingDues = 0;
    for (var r in portalProv.itrs) {
      if (r.status != 'Accepted') {
        final double netPayable = r.netTaxPayable ?? ((r.grossTax ?? 0) - (r.rebate ?? 0));
        final double paid = (r.advanceTaxPaid ?? 0) + (r.withholdingTax ?? 0) + (r.taxPaid ?? 0);
        final due = netPayable - paid;
        if (due > 0) outstandingDues += due;
      }
    }

    // Compliance Score
    int complianceScore = 100;
    if (portalProv.itrs.isNotEmpty) {
      final accepted = portalProv.itrs.where((r) => r.status == 'Accepted').length;
      complianceScore = ((accepted / portalProv.itrs.length) * 100).round();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text('Nirapod Tax', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: taxpayerProv.isLoading || portalProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Header Card
                        _buildUserHeader(displayName, tinStr, category, approvalStatus, isDark, theme),
                        const SizedBox(height: 20),

                        // Profile Completion progress card
                        _buildProfileCompletenessCard(taxpayerProv, theme, isDark),
                        const SizedBox(height: 20),

                        // Stats Grid Row
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            StatCard(
                              title: 'Returns Filed',
                              value: '${portalProv.itrs.length}',
                              icon: '📋',
                              subtext: 'ITR history count',
                            ),
                            StatCard(
                              title: 'Outstanding Dues',
                              value: _formatCurrency(outstandingDues),
                              icon: '💳',
                              subtext: 'Unpaid liabilities',
                              accentColor: outstandingDues > 0 ? AppColors.error : AppColors.success,
                            ),
                            StatCard(
                              title: 'Compliance Rate',
                              value: '$complianceScore%',
                              icon: '⚖️',
                              subtext: 'Accepted vs filed',
                              accentColor: complianceScore >= 80 ? AppColors.success : AppColors.warning,
                            ),
                            StatCard(
                              title: 'Active Alerts',
                              value: '${portalProv.notices.where((n) => n.status == 'Unread').length}',
                              icon: '🔔',
                              subtext: 'Unread system notices',
                              accentColor: portalProv.notices.any((n) => n.status == 'Unread') ? AppColors.warning : Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Menu label
                        Text(
                          'Taxpayer Dashboard Modules',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Grid
                        _buildDashboardGrid(category, context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader(
    String name,
    String tin,
    String category,
    String status,
    bool isDark,
    ThemeData theme,
  ) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TIN: $tin',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletenessCard(
    TaxpayerProvider provider,
    ThemeData theme,
    bool isDark,
  ) {
    final completion = provider.profileCompletion;
    final missing = provider.missingFields;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$completion%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: completion >= 80 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Missing: ${missing.take(3).join(", ")}${missing.length > 3 ? " +${missing.length - 3} more" : ""}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(String category, BuildContext context) {
    final List<Map<String, dynamic>> menuItems;

    if (category.toLowerCase() == 'individual') {
      menuItems = [
        {'label': 'My TIN Details', 'icon': '🪪', 'route': '/profile'},
        {'label': 'My Businesses', 'icon': '🏪', 'route': '/businesses'},
        {'label': 'Income Tax Return', 'icon': '📋', 'route': '/itr'},
        {'label': 'AIT Records', 'icon': '📊', 'route': '/ait'},
        {'label': 'Payments', 'icon': '💳', 'route': '/payments'},
        {'label': 'Official Notices', 'icon': '🔔', 'route': '/notices'},
        {'label': 'My Audits', 'icon': '🔍', 'route': '/audits'},
        {'label': 'My Appeals', 'icon': '⚖️', 'route': '/appeals'},
      ];
    } else if (category.toLowerCase() == 'business') {
      menuItems = [
        {'label': 'My TIN Details', 'icon': '🪪', 'route': '/profile'},
        {'label': 'VAT Registrations', 'icon': '🏢', 'route': '/businesses'},
        {'label': 'VAT Returns', 'icon': '📋', 'route': '/itr'},
        {'label': 'Payments', 'icon': '💳', 'route': '/payments'},
        {'label': 'Official Notices', 'icon': '🔔', 'route': '/notices'},
        {'label': 'My Audits', 'icon': '🔍', 'route': '/audits'},
      ];
    } else {
      menuItems = [
        {'label': 'My TIN Details', 'icon': '🪪', 'route': '/profile'},
        {'label': 'Income Tax Return', 'icon': '📋', 'route': '/itr'},
        {'label': 'Payments', 'icon': '💳', 'route': '/payments'},
        {'label': 'Official Notices', 'icon': '🔔', 'route': '/notices'},
        {'label': 'My Audits', 'icon': '🔍', 'route': '/audits'},
        {'label': 'My Appeals', 'icon': '⚖️', 'route': '/appeals'},
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, item['route']),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.borderDark
                    : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['icon'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
