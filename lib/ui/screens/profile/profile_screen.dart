import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../widgets/portal_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxpayerProv = Provider.of<TaxpayerProvider>(context);
    final taxpayer = taxpayerProv.taxpayer;

    if (taxpayer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Taxpayer Details')),
        body: const Center(child: Text('Profile loading failed.')),
      );
    }

    final category = taxpayer.taxpayerType?.category ?? 'Individual';
    final isBusiness = category.toLowerCase() == 'business';
    final hasTin = taxpayer.tin != null && taxpayer.tin!.isNotEmpty;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Taxpayer Details'],
      showBackButton: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── SCREEN HEADER (Title + Buttons) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taxpayer Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Full taxpayer profile information.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B), // Yellow/Amber Edit button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/profile-edit'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!hasTin) ...[
            // Fallback block if taxpayer does not have a TIN
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.credit_card_off_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No TIN Registered',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have a Taxpayer Identification Number registered yet. Click below to issue a new TIN instantly.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/tin-create');
                    },
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Issue TIN Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── BLUE HEADER BANNER CARD ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Royal Blue Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Photo Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: taxpayer.photoPath != null && taxpayer.photoPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              '${ApiEndpoints.baseUrl.replaceAll('/api', '')}${taxpayer.photoPath}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.white, size: 36),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taxpayer.companyName ?? taxpayer.fullName ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TIN - ${taxpayer.tin}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildBannerPill(taxpayer.taxpayerType?.typeName ?? category, Colors.white.withOpacity(0.2)),
                            const SizedBox(width: 8),
                            _buildBannerPill(taxpayer.approvalStatus ?? 'Active', Colors.white.withOpacity(0.2)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Registered Date (Far right)
                  if (!isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Registered Date',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Jun 8, 2026',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── DETAIL CARDS GRID ──
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

                final companyOrPersonalCard = _buildDetailSection(
                  title: isBusiness ? 'Company Details' : 'Personal Details',
                  icon: isBusiness ? Icons.business_outlined : Icons.person_outline,
                  width: cardWidth,
                  theme: theme,
                  items: isBusiness
                      ? [
                          _buildDetailRow('TIN Number', taxpayer.tin ?? 'N/A', isBadge: true),
                          _buildDetailRow('Name', taxpayer.companyName ?? 'N/A'),
                          _buildDetailRow('Trade License', 'TL-12623-0998', isBadge: true),
                          _buildDetailRow('RJSC No', taxpayer.rjscNo ?? 'C-12827-2025', isBadge: true),
                          _buildDetailRow('Incorporation Date', 'Jun 14, 2016'),
                        ]
                      : [
                          _buildDetailRow('TIN Number', taxpayer.tin ?? 'N/A', isBadge: true),
                          _buildDetailRow('Name', taxpayer.fullName ?? 'N/A'),
                          _buildDetailRow('National ID (NID)', taxpayer.nid ?? 'N/A', isBadge: true),
                          _buildDetailRow('Date of Birth', taxpayer.dateOfBirth ?? 'N/A'),
                          _buildDetailRow('Gender', taxpayer.gender ?? 'N/A'),
                        ],
                );

                final authorizedRepCard = isBusiness
                    ? _buildDetailSection(
                        title: 'Authorized Representative',
                        icon: Icons.assignment_ind_outlined,
                        width: cardWidth,
                        theme: theme,
                        items: [
                          _buildDetailRow('Representative Name', taxpayer.authorizedPersonName ?? 'Mahadi Hasan'),
                          _buildDetailRow('Designation', 'MD'),
                          _buildDetailRow('National ID (NID)', taxpayer.authorizedPersonNid ?? '9581576478', isBadge: true),
                        ],
                      )
                    : const SizedBox.shrink();

                final contactInfoCard = _buildDetailSection(
                  title: 'Contact Information',
                  icon: Icons.phone_outlined,
                  width: cardWidth,
                  theme: theme,
                  items: [
                    _buildDetailRow('Email', taxpayer.email ?? 'N/A'),
                    _buildDetailRow('Phone', taxpayer.phone ?? 'N/A'),
                  ],
                );

                final addressCard = _buildDetailSection(
                  title: 'Address Details',
                  icon: Icons.location_on_outlined,
                  width: cardWidth,
                  theme: theme,
                  items: [
                    _buildDetailRow(
                      'Present Address',
                      taxpayer.presentAddress != null
                          ? '${taxpayer.presentAddress!.details}, ${taxpayer.presentAddress!.district}, ${taxpayer.presentAddress!.division}'
                          : 'N/A',
                    ),
                    _buildDetailRow('Permanent Address', 'Same as Present Address'),
                  ],
                );

                final accountStatusCard = _buildDetailSection(
                  title: 'Account Status',
                  icon: Icons.verified_user_outlined,
                  width: cardWidth,
                  theme: theme,
                  items: [
                    _buildDetailRow('Status', taxpayer.approvalStatus ?? 'Active', isStatusBadge: true),
                    _buildDetailRow('Registration Date', 'Jun 8, 2026'),
                  ],
                );

                if (isMobile) {
                  return Column(
                    children: [
                      companyOrPersonalCard,
                      const SizedBox(height: 16),
                      if (isBusiness) ...[
                        authorizedRepCard,
                        const SizedBox(height: 16),
                      ],
                      contactInfoCard,
                      const SizedBox(height: 16),
                      addressCard,
                      const SizedBox(height: 16),
                      accountStatusCard,
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        child: Column(
                          children: [
                            companyOrPersonalCard,
                            const SizedBox(height: 16),
                            contactInfoCard,
                            const SizedBox(height: 16),
                            accountStatusCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            if (isBusiness) ...[
                              authorizedRepCard,
                              const SizedBox(height: 16),
                            ],
                            addressCard,
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // ── APPLICATION REVIEW SECTION (Full width at bottom) ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Review Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 8),
                            Text(
                              'Application Review',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Approved',
                            style: TextStyle(color: Color(0xFF065F46), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Review Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TIN Issued Successfully',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'TIN: ${taxpayer.tin}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Notes: Approved',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerPill(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required double width,
    required ThemeData theme,
    required List<Widget> items,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(items.length, (index) {
                final isLast = index == items.length - 1;
                return Column(
                  children: [
                    items[index],
                    if (!isLast) ...[
                      const SizedBox(height: 10),
                      Divider(color: Colors.grey.shade100, height: 1),
                      const SizedBox(height: 10),
                    ]
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBadge = false,
    bool isStatusBadge = false,
  }) {
    Widget valueWidget;

    if (isBadge) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF), // Soft Blue badge background
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      );
    } else if (isStatusBadge) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF065F46),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        textAlign: TextAlign.end,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: valueWidget),
      ],
    );
  }
}
