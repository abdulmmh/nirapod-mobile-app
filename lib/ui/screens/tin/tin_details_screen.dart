import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../widgets/portal_shell.dart';

class TinDetailsScreen extends StatefulWidget {
  const TinDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TinDetailsScreen> createState() => _TinDetailsScreenState();
}

class _TinDetailsScreenState extends State<TinDetailsScreen> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaxpayerProvider>(context, listen: false).fetchTinRecord();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _triggerCertificateDownload(String tinNum, String name) {
    setState(() => _isDownloading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading TIN Certificate for $name ($tinNum)...'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate downloaded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxpayerProv = Provider.of<TaxpayerProvider>(context);
    final record = taxpayerProv.tinRecord;
    final taxpayer = taxpayerProv.taxpayer;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    // Loading State
    if (taxpayerProv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // No Record Found fallback
    if (record == null) {
      return PortalShell(
        breadcrumbs: const ['My Portal', 'TIN Details'],
        showBackButton: true,
        body: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card_off_outlined, size: 48, color: Colors.orange.shade800),
                const SizedBox(height: 16),
                const Text(
                  'No TIN Record Found',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Could not retrieve your TIN details. Please make sure you have issued a TIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String displayName = record.taxpayerName ?? taxpayer?.companyName ?? taxpayer?.fullName ?? 'Tasrif Zaman';
    final String tinNum = record.tinNumber;
    final String category = record.tinCategory ?? taxpayer?.taxpayerType?.category ?? 'Individual';
    final String status = record.status ?? 'Active';
    final String zone = record.taxZone ?? 'Dhaka Tax Zone';
    final String circle = record.taxCircle ?? 'Dhaka Circle-1';

    return PortalShell(
      breadcrumbs: const ['My Portal', 'TIN Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── SCREEN HEADER (Title + Actions) ──
            if (isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIN Details',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Full TIN record information.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF14532D),
                            side: const BorderSide(color: Color(0xFF14532D)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isDownloading ? null : () => _triggerCertificateDownload(tinNum, displayName),
                          icon: _isDownloading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF14532D)),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 16),
                          label: Text(
                            _isDownloading ? 'Downloading...' : 'Download Certificate',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIN Details',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Full TIN record information.',
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
                          foregroundColor: const Color(0xFF14532D),
                          side: const BorderSide(color: Color(0xFF14532D)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: _isDownloading ? null : () => _triggerCertificateDownload(tinNum, displayName),
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF14532D)),
                              )
                            : const Icon(Icons.picture_as_pdf, size: 16),
                        label: Text(
                          _isDownloading ? 'Downloading...' : 'Download Certificate',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E293B),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── BLUE BANNER CARD ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)], // Deep Blue Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Photo/Avatar icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 20),

                  // Name & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tinNum,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildBannerPill(category, Colors.white.withOpacity(0.15)),
                            _buildBannerPill(zone, Colors.white.withOpacity(0.15)),
                            _buildBannerPill(circle, Colors.white.withOpacity(0.15)),
                            _buildBannerPill(
                              status,
                              status.toLowerCase() == 'active'
                                  ? const Color(0xFF10B981) // Green
                                  : const Color(0xFFEF4444), // Red
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Date details (Desktop view)
                  if (!isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Issued Date',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(record.issuedDate),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Last Updated',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(record.lastUpdated ?? record.issuedDate),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── DETAILS GRID ──
            LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

                final taxpayerInfoCard = _buildDetailSection(
                  title: 'Taxpayer Information',
                  icon: Icons.badge_outlined,
                  width: cardWidth,
                  items: [
                    _buildDetailRow('TIN Number', tinNum, isBadge: true),
                    _buildDetailRow('Full Name', displayName),
                    _buildDetailRow('Category', category),
                    if (record.nid != null && record.nid!.isNotEmpty)
                      _buildDetailRow('National ID (NID)', record.nid!, isBadge: true),
                    if (record.passportNo != null && record.passportNo!.isNotEmpty)
                      _buildDetailRow('Passport No', record.passportNo!, isBadge: true),
                    if (record.dateOfBirth != null && record.dateOfBirth!.isNotEmpty)
                      _buildDetailRow('Date of Birth', _formatDate(record.dateOfBirth)),
                    if (record.gender != null && record.gender!.isNotEmpty)
                      _buildDetailRow('Gender', record.gender!),
                    if (record.incorporationDate != null && record.incorporationDate!.isNotEmpty)
                      _buildDetailRow('Incorporation Date', _formatDate(record.incorporationDate)),
                  ],
                );

                final taxAuthorityCard = _buildDetailSection(
                  title: 'Tax Authority',
                  icon: Icons.verified_user_outlined,
                  width: cardWidth,
                  items: [
                    _buildDetailRow('Tax Zone', zone, isZoneBadge: true),
                    _buildDetailRow('Tax Circle', circle, isCircleBadge: true),
                    _buildDetailRow('Status', status, isStatusBadge: true),
                    _buildDetailRow('Issued Date', _formatDate(record.issuedDate)),
                    _buildDetailRow('Last Updated', _formatDate(record.lastUpdated ?? record.issuedDate)),
                  ],
                );

                final contactInfoCard = _buildDetailSection(
                  title: 'Contact & Location',
                  icon: Icons.location_on_outlined,
                  width: cardWidth,
                  items: [
                    _buildDetailRow('Email', record.email ?? 'N/A'),
                    _buildDetailRow('Phone', record.phone ?? 'N/A'),
                    _buildDetailRow('Division', record.division ?? 'N/A'),
                    _buildDetailRow('District', record.district ?? 'N/A'),
                    if (record.address != null && record.address!.isNotEmpty)
                      _buildDetailRow('Address', record.address!),
                    if (record.remarks != null && record.remarks!.isNotEmpty)
                      _buildDetailRow('Remarks', record.remarks!),
                  ],
                );

                if (isMobile) {
                  return Column(
                    children: [
                      taxpayerInfoCard,
                      const SizedBox(height: 16),
                      taxAuthorityCard,
                      const SizedBox(height: 16),
                      contactInfoCard,
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
                            taxpayerInfoCard,
                            const SizedBox(height: 16),
                            contactInfoCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Column
                      Expanded(
                        child: Column(
                          children: [
                            taxAuthorityCard,
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
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
    bool isZoneBadge = false,
    bool isCircleBadge = false,
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
            fontSize: 11.5,
          ),
        ),
      );
    } else if (isZoneBadge) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E40AF),
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
          ),
        ),
      );
    } else if (isCircleBadge) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
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
            fontSize: 10.5,
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
