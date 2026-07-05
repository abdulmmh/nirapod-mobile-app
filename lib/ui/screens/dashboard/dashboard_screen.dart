import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../../providers/portal_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/portal_shell.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth.clamp(0.0, 1100.0);

    final int statsCrossAxisCount = screenWidth < 720 ? 2 : 4;
    final double statsCardWidth = (gridWidth - 32 - (statsCrossAxisCount - 1) * 12) / statsCrossAxisCount;
    final double statsCardHeight = screenWidth < 720 ? 128 : 110;
    final double statsAspectRatio = statsCardWidth / statsCardHeight;
    
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

    if (taxpayerProv.isLoading || portalProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PortalShell(
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
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
                          crossAxisCount: statsCrossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: statsAspectRatio,
                          children: [
                            StatCard(
                              title: 'Returns Filed',
                              value: '${portalProv.itrs.length}',
                              icon: Icons.assignment_outlined,
                              iconColor: AppColors.primary,
                              subtext: 'ITR history count',
                            ),
                            StatCard(
                              title: 'Outstanding Dues',
                              value: _formatCurrency(outstandingDues),
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: outstandingDues > 0 ? AppColors.error : AppColors.success,
                              subtext: 'Unpaid liabilities',
                              accentColor: outstandingDues > 0 ? AppColors.error : AppColors.success,
                            ),
                            StatCard(
                              title: 'Compliance Rate',
                              value: '$complianceScore%',
                              icon: Icons.verified_user_outlined,
                              iconColor: complianceScore >= 80 ? AppColors.success : AppColors.warning,
                              subtext: 'Accepted vs filed',
                              accentColor: complianceScore >= 80 ? AppColors.success : AppColors.warning,
                            ),
                            StatCard(
                              title: 'Active Alerts',
                              value: '${portalProv.notices.where((n) => n.status == 'Unread').length}',
                              icon: Icons.notifications_active_outlined,
                              iconColor: portalProv.notices.any((n) => n.status == 'Unread') ? AppColors.warning : Colors.grey,
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
    Color statusBg;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF4ADE80); // Bright light green
        statusBg = Colors.white.withOpacity(0.12);
        break;
      case 'pending':
        statusColor = const Color(0xFFFBBF24); // Bright amber
        statusBg = Colors.white.withOpacity(0.12);
        break;
      default:
        statusColor = const Color(0xFFF87171); // Bright red
        statusBg = Colors.white.withOpacity(0.12);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
            : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.0 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'N',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'TIN: $tin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
          if (completion < 100) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14532D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/profile-edit'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Complete Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(String category, BuildContext context) {
    final List<Map<String, dynamic>> menuItems;
    final screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth.clamp(0.0, 1100.0);
    final int crossAxisCount = screenWidth < 600 ? 3 : (screenWidth < 900 ? 4 : 6);
    final double cardWidth = (gridWidth - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;
    final double cardHeight = screenWidth < 600 ? 136 : 115;
    final double aspectRatio = cardWidth / cardHeight;

    if (category.toLowerCase() == 'individual') {
      menuItems = [
        {'label': 'My TIN Details', 'icon': Icons.badge_outlined, 'color': AppColors.primary, 'route': '/profile'},
        {'label': 'My Businesses', 'icon': Icons.storefront_outlined, 'color': Colors.indigo, 'route': '/businesses'},
        {'label': 'Income Tax Return', 'icon': Icons.description_outlined, 'color': Colors.orange, 'route': '/itr'},
        {'label': 'AIT Records', 'icon': Icons.receipt_long_outlined, 'color': Colors.purple, 'route': '/ait'},
        {'label': 'Payments', 'icon': Icons.payment_outlined, 'color': Colors.green, 'route': '/payments'},
        {'label': 'Official Notices', 'icon': Icons.campaign_outlined, 'color': Colors.red, 'route': '/notices'},
        {'label': 'My Audits', 'icon': Icons.search_outlined, 'color': Colors.blue, 'route': '/audits'},
        {'label': 'My Appeals', 'icon': Icons.gavel_outlined, 'color': Colors.amber, 'route': '/appeals'},
      ];
    } else if (category.toLowerCase() == 'business') {
      menuItems = [
        {'label': 'My TIN Details', 'icon': Icons.badge_outlined, 'color': AppColors.primary, 'route': '/profile'},
        {'label': 'VAT Registrations', 'icon': Icons.storefront_outlined, 'color': Colors.indigo, 'route': '/businesses'},
        {'label': 'VAT Returns', 'icon': Icons.description_outlined, 'color': Colors.orange, 'route': '/itr'},
        {'label': 'Payments', 'icon': Icons.payment_outlined, 'color': Colors.green, 'route': '/payments'},
        {'label': 'Official Notices', 'icon': Icons.campaign_outlined, 'color': Colors.red, 'route': '/notices'},
        {'label': 'My Audits', 'icon': Icons.search_outlined, 'color': Colors.blue, 'route': '/audits'},
      ];
    } else {
      menuItems = [
        {'label': 'My TIN Details', 'icon': Icons.badge_outlined, 'color': AppColors.primary, 'route': '/profile'},
        {'label': 'Income Tax Return', 'icon': Icons.description_outlined, 'color': Colors.orange, 'route': '/itr'},
        {'label': 'Payments', 'icon': Icons.payment_outlined, 'color': Colors.green, 'route': '/payments'},
        {'label': 'Official Notices', 'icon': Icons.campaign_outlined, 'color': Colors.red, 'route': '/notices'},
        {'label': 'My Audits', 'icon': Icons.search_outlined, 'color': Colors.blue, 'route': '/audits'},
        {'label': 'My Appeals', 'icon': Icons.gavel_outlined, 'color': Colors.amber, 'route': '/appeals'},
      ];
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final itemColor = item['color'] as Color;
        final itemIcon = item['icon'] as IconData;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, item['route']),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: itemColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      itemIcon,
                      color: itemColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['label'],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
