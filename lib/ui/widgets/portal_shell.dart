import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/taxpayer_provider.dart';

class PortalShell extends StatelessWidget {
  final Widget body;
  final List<String>? breadcrumbs;
  final bool showBackButton;
  final Widget? floatingActionButton;

  const PortalShell({
    Key? key,
    required this.body,
    this.breadcrumbs,
    this.showBackButton = false,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final taxpayerProv = Provider.of<TaxpayerProvider>(context);
    
    final taxpayer = taxpayerProv.taxpayer;
    final user = auth.currentUser;
    
    final String displayName = taxpayer?.fullName ?? taxpayer?.companyName ?? user?.fullName ?? 'Tasrif Zaman';
    final String taxpayerCategory = taxpayer?.taxpayerType?.category ?? user?.taxpayerType ?? 'Resident Individual';
    final activeRoute = ModalRoute.of(context)?.settings.name;
    final double screenWidth = MediaQuery.of(context).size.width;

    void navigateHome() {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: floatingActionButton,
      drawer: screenWidth < 850 ? _buildMobileDrawer(context, activeRoute, displayName, taxpayerCategory, auth) : null,
      body: Column(
        children: [
          // ── 1. DARK GREEN NBR TOP BAR ──
          Container(
            height: 64,
            color: const Color(0xFF14532D), // NBR Dark Green
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Left
                Row(
                  children: [
                    if (screenWidth < 850) ...[
                      Builder(
                        builder: (innerContext) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(innerContext).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    InkWell(
                      onTap: navigateHome,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'NBR Portal',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'GOVERNMENT OF BANGLADESH',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Center Segmented Navigation Menu (For Desktop/Wide screens)
                if (screenWidth >= 850)
                  _buildNavTabs(context, activeRoute),

                // User Profile Right
                Row(
                  children: [
                    // Profile Info (Hidden on very narrow mobile screens)
                    if (screenWidth > 480) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            taxpayerCategory,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Avatar
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.teal.shade700,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Logout (Only on desktop, inside drawer on mobile)
                    if (screenWidth >= 850)
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                        tooltip: 'Logout',
                        onPressed: () async {
                          await auth.logout();
                          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. BREADCRUMBS BAR (Sub-header) ──
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Back button option
                  if (showBackButton) ...[
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Breadcrumb items
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: breadcrumbs!.length,
                      itemBuilder: (context, index) {
                        final isLast = index == breadcrumbs!.length - 1;
                        final label = breadcrumbs![index];
                        final isHome = index == 0;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isHome) ...[
                              Icon(
                                Icons.home_outlined,
                                size: 14,
                                color: isLast ? Colors.grey.shade500 : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                            ],
                            GestureDetector(
                              onTap: () {
                                if (isHome) {
                                  navigateHome();
                                } else if (!isLast) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                                  color: isLast
                                      ? Colors.grey.shade700
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ── 3. CONTENT BODY & BOTTOM FOOTER ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Body Content Centered
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: body,
                      ),
                    ),
                  ),

                  // ── 4. BOTTOM BAR (Footer) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '© 2026 National Board of Revenue, Bangladesh · Secure Government Portal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Navigation Tabs Helper ──
  Widget _buildNavTabs(BuildContext context, String? activeRoute) {
    Widget buildTabItem(String label, IconData icon, String route, List<String> prefixes) {
      final isCurrent = activeRoute != null && 
          (activeRoute == route || prefixes.any((p) => activeRoute.startsWith(p)));

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (activeRoute != route) {
              Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isCurrent
                  ? Border.all(color: Colors.white24, width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isCurrent ? Colors.white : Colors.white70,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontSize: 12.5,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildTabItem('Home', Icons.dashboard_outlined, '/dashboard', []),
        buildTabItem('ITR', Icons.assignment_outlined, '/itr', ['/itr-wizard', '/itr-details']),
        buildTabItem('AIT', Icons.receipt_long_outlined, '/ait', ['/ait-wizard', '/ait-details']),
        buildTabItem('Businesses', Icons.business_outlined, '/businesses', ['/business-']),
        buildTabItem('Payments', Icons.payment_outlined, '/payments', []),
        buildTabItem('Notices', Icons.notifications_outlined, '/notices', []),
      ],
    );
  }

  // ── Mobile Responsive Drawer Helper ──
  Widget _buildMobileDrawer(
    BuildContext context, 
    String? activeRoute, 
    String displayName, 
    String taxpayerCategory,
    AuthProvider auth
  ) {
    Widget buildDrawerItem(String label, IconData icon, String route, List<String> prefixes) {
      final isCurrent = activeRoute != null && 
          (activeRoute == route || prefixes.any((p) => activeRoute.startsWith(p)));

      return ListTile(
        leading: Icon(icon, color: isCurrent ? AppColors.primary : Colors.grey.shade600),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.primary : Colors.grey.shade800,
          ),
        ),
        selected: isCurrent,
        selectedTileColor: AppColors.primary.withOpacity(0.06),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (activeRoute != route) {
            Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
          }
        },
      );
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF14532D), // NBR Dark Green
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(taxpayerCategory),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: Color(0xFF14532D),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildDrawerItem('Home Dashboard', Icons.dashboard_outlined, '/dashboard', []),
                buildDrawerItem('Income Tax (ITR)', Icons.assignment_outlined, '/itr', ['/itr-wizard', '/itr-details']),
                buildDrawerItem('Claim Advance Tax (AIT)', Icons.receipt_long_outlined, '/ait', ['/ait-wizard', '/ait-details']),
                buildDrawerItem('Businesses', Icons.business_outlined, '/businesses', ['/business-']),
                buildDrawerItem('Payments', Icons.payment_outlined, '/payments', []),
                buildDrawerItem('Notices', Icons.notifications_outlined, '/notices', []),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
