import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/portal_shell.dart';

class AitDetailsScreen extends StatefulWidget {
  final int aitId;

  const AitDetailsScreen({Key? key, required this.aitId}) : super(key: key);

  @override
  State<AitDetailsScreen> createState() => _AitDetailsScreenState();
}

class _AitDetailsScreenState extends State<AitDetailsScreen> {
  final _challanController = TextEditingController();
  final _bankController = TextEditingController(text: 'Sonali Bank');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _challanController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
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
        'step': 1,
      };
    } else if (s.contains('SUBMITTED')) {
      return {
        'label': 'Submitted',
        'bg': const Color(0xFFDBEAFE),
        'text': const Color(0xFF1D4ED8),
        'step': 2,
      };
    } else if (s.contains('PENDING')) {
      return {
        'label': 'Pending',
        'bg': const Color(0xFFFEF3C7),
        'text': const Color(0xFF92400E),
        'step': 3,
      };
    } else if (s.contains('REVIEW') || s.contains('UNDER')) {
      return {
        'label': 'Under Review',
        'bg': const Color(0xFFEDE9FE),
        'text': const Color(0xFF5B21B6),
        'step': 4,
      };
    } else if (s.contains('APPROV') || s.contains('VERIFIED')) {
      return {
        'label': 'Approved',
        'bg': const Color(0xFFDCFCE7),
        'text': const Color(0xFF166534),
        'step': 5,
      };
    } else if (s.contains('CREDIT')) {
      return {
        'label': 'Credited to ITR',
        'bg': const Color(0xFFD1FAE5),
        'text': const Color(0xFF065F46),
        'step': 6,
      };
    } else {
      return {
        'label': status,
        'bg': const Color(0xFFF3F4F6),
        'text': const Color(0xFF6B7280),
        'step': 1,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final portalProv = Provider.of<PortalProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Find return record
    final aitIdx = portalProv.aits.indexWhere((element) => element.id == widget.aitId);
    if (aitIdx == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('AIT Details')),
        body: const Center(child: Text('Record not found.')),
      );
    }
    final ait = portalProv.aits[aitIdx];
    final sourceInfo = _getSourceInfo(ait.source);
    final statusInfo = _getStatusInfo(ait.status);
    final int currentStep = statusInfo['step'];

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

    return Theme(
      data: localTheme,
      child: PortalShell(
        breadcrumbs: const ['My Portal', 'AIT', 'Review'],
        showBackButton: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AIT Review',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review, verify, and process this advance income tax record.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Queue'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Progression Timeline Header
            _buildStatusTimeline(currentStep, screenWidth),
            const SizedBox(height: 20),

            // Content Section (Responsive Columns)
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoCols = constraints.maxWidth > 900;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: useTwoCols ? 2 : 3,
                      child: Column(
                        children: [
                          _buildTaxpayerInfoCard(ait),
                          const SizedBox(height: 16),
                          _buildAitRecordCard(ait, sourceInfo, statusInfo),
                          const SizedBox(height: 16),
                          if (currentStep >= 3 && ait.challanNo.isNotEmpty) ...[
                            _buildChallanVerificationCard(ait),
                            const SizedBox(height: 16),
                          ],
                          _buildSupportingDocsCard(),
                        ],
                      ),
                    ),
                    // Right Column
                    if (useTwoCols) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            if (ait.status.toUpperCase() == 'DRAFT') ...[
                              _buildSubmitRecordCard(ait),
                              const SizedBox(height: 16),
                            ],
                            _buildAuditTrailCard(currentStep),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      if (ait.status.toUpperCase() == 'DRAFT') ...[
                        _buildSubmitRecordCard(ait),
                        const SizedBox(height: 16),
                      ],
                      _buildAuditTrailCard(currentStep),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Status Progression Timeline ──
  Widget _buildStatusTimeline(int activeStep, double screenWidth) {
    final steps = ['Draft', 'Submitted', 'Pending', 'In Review', 'Approved', 'Credited'];

    if (screenWidth >= 600) {
      // Wide Screen (Desktop/Tablet) – stretching timeline
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildStepNode(1, 'Draft', activeStep),
            _buildTimelineLine(1, activeStep),
            _buildStepNode(2, 'Submitted', activeStep),
            _buildTimelineLine(2, activeStep),
            _buildStepNode(3, 'Pending', activeStep),
            _buildTimelineLine(3, activeStep),
            _buildStepNode(4, 'In Review', activeStep),
            _buildTimelineLine(4, activeStep),
            _buildStepNode(5, 'Approved', activeStep),
            _buildTimelineLine(5, activeStep),
            _buildStepNode(6, 'Credited', activeStep),
          ],
        ),
      );
    } else {
      // Narrow Screen (Mobile) – scrollable timeline
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final stepNum = index + 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStepNode(stepNum, steps[index], activeStep),
                  if (index < steps.length - 1)
                    Container(
                      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
                      width: 40,
                      height: 2.5,
                      color: activeStep > stepNum
                          ? (activeStep == 6 ? const Color(0xFF166534) : AppColors.primary)
                          : Colors.grey.shade200,
                    ),
                ],
              );
            }),
          ),
        ),
      );
    }
  }

  Widget _buildStepNode(int stepNum, String label, int activeStep) {
    final isCompleted = activeStep > stepNum;
    final isCurrent = activeStep == stepNum;
    final isAllCredited = activeStep == 6;

    IconData getIconForStep(int step) {
      switch (step) {
        case 1:
          return Icons.description_outlined;
        case 2:
          return Icons.send_outlined;
        case 3:
          return Icons.access_time;
        case 4:
          return Icons.search;
        case 5:
          return Icons.done_all;
        case 6:
          return Icons.account_balance_wallet_outlined;
        default:
          return Icons.circle;
      }
    }

    Color getNodeColor() {
      if (isAllCredited || isCompleted) {
        return const Color(0xFF166534); // Green for completed/credited
      }
      if (isCurrent) {
        return AppColors.primary; // Purple/Teal for current
      }
      return Colors.grey.shade200; // Grey for future
    }

    Color getIconColor() {
      if (isAllCredited || isCompleted || isCurrent) {
        return Colors.white;
      }
      return Colors.grey.shade500;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: getNodeColor(),
            border: isCurrent && !isAllCredited
                ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 4)
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: (isAllCredited || isCompleted)
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Icon(getIconForStep(stepNum), color: getIconColor(), size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: (isAllCredited || isCompleted || isCurrent)
                ? AppColors.textPrimary
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(int stepNum, int activeStep) {
    final isCompleted = activeStep > stepNum;
    final isAllCredited = activeStep == 6;
    final lineColor = (isAllCredited || isCompleted)
        ? const Color(0xFF166534)
        : Colors.grey.shade200;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2.5,
        color: lineColor,
      ),
    );
  }

  // ── 2. Taxpayer Info Card ──
  Widget _buildTaxpayerInfoCard(AitRecord ait) {
    return _buildCard(
      title: 'Taxpayer Information',
      subtitle: 'Verified taxpayer profile',
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      child: Column(
        children: [
          _buildInfoRow('Name', 'Tasrif Zaman'),
          _buildDivider(),
          _buildInfoRow('TIN', 'TIN-000000005', isMono: true),
          _buildDivider(),
          _buildInfoRow('Fiscal Year', '2025-26'),
          _buildDivider(),
          _buildInfoRow('Submitted', _formatDate(ait.date)),
        ],
      ),
    );
  }

  // ── 3. AIT Record Card ──
  Widget _buildAitRecordCard(AitRecord ait, Map<String, dynamic> sourceInfo, Map<String, dynamic> statusInfo) {
    final isImport = ait.source.toUpperCase().contains('IMPORT');
    // Calculate taxable value based on rate (simulated)
    final rate = 5.0;
    final taxableValue = (ait.amount * 100) / rate;

    return _buildCard(
      title: 'AIT Record — AIT-202526-${ait.challanNo.isNotEmpty ? ait.id : "DRAFT"}',
      subtitle: 'Source: ${_getSourceInfo(ait.source)['label']}',
      icon: Icons.receipt_long_outlined,
      iconColor: Colors.purple,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusInfo['bg'],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusInfo['label'],
          style: TextStyle(color: statusInfo['text'], fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Source Type', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: sourceInfo['bg'], borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Icon(sourceInfo['icon'], size: 12, color: sourceInfo['text']),
                    const SizedBox(width: 4),
                    Text(
                      sourceInfo['label'],
                      style: TextStyle(color: sourceInfo['text'], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildDivider(),
          if (isImport) ...[
            _buildInfoRow('Import Duty Record', '1220091', isMono: true),
            _buildDivider(),
            _buildInfoRow('HS Code', '1020098', isMono: true),
          ] else ...[
            _buildInfoRow('Deductor', 'Test Company'),
          ],
          _buildDivider(),
          _buildInfoRow('Taxable Value', NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(taxableValue)),
          _buildDivider(),
          _buildInfoRow('AIT Rate', '${rate.toStringAsFixed(0)}%'),
          _buildDivider(),
          // Calculated AIT highlighted box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calculated AIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6B21A8))),
                Text(
                  NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(ait.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6B21A8)),
                ),
              ],
            ),
          ),
          if (statusInfo['step'] >= 5) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Approved AIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                Text(
                  NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(ait.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Challan Verification Card ──
  Widget _buildChallanVerificationCard(AitRecord ait) {
    return _buildCard(
      title: 'Challan Verification',
      subtitle: 'Treasury payment proof',
      icon: Icons.check_circle_outline,
      iconColor: Colors.teal,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.check, size: 10, color: Color(0xFF166534)),
            SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow('Challan No.', ait.challanNo, isMono: true),
          _buildDivider(),
          _buildInfoRow('Bank', 'Sonali Bank'),
        ],
      ),
    );
  }

  // ── 5. Supporting Documents Card ──
  Widget _buildSupportingDocsCard() {
    return _buildCard(
      title: 'Supporting Documents',
      subtitle: 'Uploaded proof attachments',
      icon: Icons.attach_file_outlined,
      iconColor: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1 file(s) uploaded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('new-card.png', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('142 KB', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Submit Record Sidebar Card ──
  Widget _buildSubmitRecordCard(AitRecord ait) {
    return _buildCard(
      title: 'Submit Record',
      subtitle: 'Ready to submit to tax authority?',
      icon: Icons.send_outlined,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Make sure all documents are uploaded before submitting. Once submitted, you cannot edit this record.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _challanController,
            decoration: InputDecoration(
              labelText: 'Challan Number (optional)',
              hintText: 'e.g. CH-2026-001234',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bankController,
            decoration: InputDecoration(
              labelText: 'Bank Name (optional)',
              hintText: 'e.g. Sonali Bank',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Submit AIT Record',
            icon: Icons.send,
            isLoading: _isSubmitting,
            onPressed: () async {
              setState(() => _isSubmitting = true);
              // Submit Draft AIT record
              final success = await Provider.of<PortalProvider>(context, listen: false).submitAit(
                ait.id,
                _challanController.text.isNotEmpty ? _challanController.text : 'CH-${DateTime.now().millisecond}',
              );
              setState(() => _isSubmitting = false);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AIT Record submitted successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '▲ Upload at least one document before submitting.',
              style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── 7. Audit Trail Card ──
  Widget _buildAuditTrailCard(int activeStep) {
    final List<Map<String, dynamic>> auditEvents = [
      {
        'title': 'DRAFT',
        'user': 'Tasrif Zaman',
        'time': '23 Jun 2026, 09:49',
        'desc': 'AIT record created as draft',
        'step': 1,
      },
      {
        'title': 'DRAFT → SUBMITTED',
        'user': 'Tasrif Zaman',
        'time': '23 Jun 2026, 09:49',
        'desc': 'Submitted by taxpayer',
        'step': 2,
      },
      {
        'title': 'SUBMITTED → PENDING',
        'user': 'Tax Officer',
        'time': '15 Jun 2026, 03:23',
        'desc': 'Challan verified by officer: officer@vattax.gov.bd',
        'step': 3,
      },
      {
        'title': 'PENDING → UNDER_REVIEW',
        'user': 'Tax Officer',
        'time': '15 Jun 2026, 03:25',
        'desc': 'Assigned to officer: officer@vattax.gov.bd',
        'step': 4,
      },
      {
        'title': 'UNDER_REVIEW → APPROVED',
        'user': 'Tax Officer',
        'time': '15 Jun 2026, 03:25',
        'desc': 'Verified and approved',
        'step': 5,
      },
      {
        'title': 'APPROVED → CREDITED',
        'user': 'Tax Officer',
        'time': '15 Jun 2026, 03:26',
        'desc': 'AIT credit posted to taxpayer ledger',
        'step': 6,
      },
    ];

    // Filter events to only show what has occurred so far
    final visibleEvents = auditEvents.where((e) => e['step'] <= activeStep).toList();

    return _buildCard(
      title: 'Audit Trail',
      subtitle: '${visibleEvents.length} events',
      icon: Icons.history_outlined,
      iconColor: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleEvents.reversed.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline node
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1.5,
                      height: 50,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Event content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e['user']}  ·  ${e['time']}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e['desc'],
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper Card Builder
  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              if (badge != null) badge,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            fontFamily: isMono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}
