import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/utils/api_client.dart';
import '../../../core/utils/document_upload.dart';
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
  final _bankController = TextEditingController();
  bool _isSubmitting = false;
  bool _uploading = false;
  Map<String, dynamic>? _detail;
  bool _detailFailed = false;
  List<dynamic> get _documents => _detail?['documents'] ?? [];

  @override
  void initState() {
    super.initState();
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    try {
      final response = await apiClient.get('/ait-records/${widget.aitId}');
      if (mounted) setState(() { _detail = response.data; _detailFailed = false; });
    } catch (_) {
      if (mounted) setState(() => _detailFailed = true);
    }
  }

  Future<void> _uploadDocuments() async {
    setState(() => _uploading = true);
    try {
      final files = await pickDocuments();
      for (final file in files) {
        await apiClient.post('/ait-records/${widget.aitId}/documents', data: FormData.fromMap({'file': await documentPart(file)}));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload could not be confirmed. Check the document list.')));
    } finally {
      if (mounted) { setState(() => _uploading = false); await _refreshDetail(); }
    }
  }

  Future<void> _saveDocument(Map doc) async {
    try {
      final bytes = await apiClient.dio.get<List<int>>('/ait-records/${widget.aitId}/documents/${doc["id"]}/download', options: Options(responseType: ResponseType.bytes));
      if (mounted) await FilePicker.saveFile(fileName: doc['fileName'], bytes: Uint8List.fromList(bytes.data!));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this document.')));
    }
  }

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
            if (_detailFailed) TextButton(onPressed: _refreshDetail, child: const Text('Could not load AIT details. Retry')),
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
                            _buildAuditTrailCard(),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      if (ait.status.toUpperCase() == 'DRAFT') ...[
                        _buildSubmitRecordCard(ait),
                        const SizedBox(height: 16),
                      ],
                      _buildAuditTrailCard(),
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
          _buildInfoRow('Name', context.watch<AuthProvider>().currentUser?.fullName ?? '—'),
          _buildDivider(),
          _buildInfoRow('TIN', context.watch<AuthProvider>().currentUser?.tinNumber ?? '—', isMono: true),
          _buildDivider(),
          _buildInfoRow('Fiscal Year', _detail?['fiscalYearName'] ?? '—'),
          _buildDivider(),
          _buildInfoRow('Submitted', _formatDate(ait.date)),
        ],
      ),
    );
  }

  // ── 3. AIT Record Card ──
  Widget _buildAitRecordCard(AitRecord ait, Map<String, dynamic> sourceInfo, Map<String, dynamic> statusInfo) {
    final isImport = ait.source.toUpperCase().contains('IMPORT');
    return _buildCard(
      title: _detail?['aitReferenceNo'] ?? 'AIT Record',
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
            _buildInfoRow('Import Duty Record', _detail?['importDutyRecordId']?.toString() ?? '—', isMono: true),
            _buildDivider(),
            _buildInfoRow('HS Code', _detail?['hsCode']?.toString() ?? '—', isMono: true),
          ] else ...[
            _buildInfoRow('Deductor', _detail?['deductorName']?.toString() ?? '—'),
          ],
          _buildDivider(),
          _buildInfoRow('Taxable Value', _detail?['taxableValue']?.toString() ?? '—'),
          _buildDivider(),
          _buildInfoRow('AIT Rate', _detail?['aitRate'] == null ? '—' : '${_detail!["aitRate"]}%'),
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
                  _detail?['approvedAitAmount']?.toString() ?? '—',
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
  Widget _buildChallanVerificationCard(AitRecord ait) => _buildCard(
    title: 'Challan Verification', subtitle: 'Treasury payment proof', icon: Icons.receipt_outlined, iconColor: Colors.teal,
    child: Column(children: [
      _buildInfoRow('Challan No.', ait.challanNo),
      _buildInfoRow('Bank', _detail?['bankName'] ?? '—'),
      _buildInfoRow('Verified', _detail == null ? '—' : _detail!['challanVerified'] == true ? 'Yes' : 'No'),
    ]),
  );

  // ── 5. Supporting Documents Card ──
  Widget _buildSupportingDocsCard() => _buildCard(
    title: 'Supporting Documents', subtitle: 'Uploaded proof attachments', icon: Icons.attach_file, iconColor: Colors.teal,
    child: Column(children: [
      if (_detail != null && _documents.isEmpty) const Text('No documents uploaded.'),
      for (final doc in _documents) ListTile(title: Text(doc['fileName'] ?? 'Document'), trailing: IconButton(icon: const Icon(Icons.download), onPressed: () => _saveDocument(doc))),
      if (_detail?['status'] == 'DRAFT') TextButton.icon(onPressed: _uploading ? null : _uploadDocuments, icon: const Icon(Icons.upload), label: const Text('Upload documents')),
    ]),
  );

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
              if (_documents.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload a document before submitting.')));
                return;
              }
              setState(() => _isSubmitting = true);
              // Submit Draft AIT record
              final success = await Provider.of<PortalProvider>(context, listen: false).submitAit(
                ait.id,
                _challanController.text.trim(), _bankController.text.trim(),
                _documents.map((doc) => doc['id'] as int).toList(),
              );
              if (!mounted) return;
              setState(() => _isSubmitting = false);
              if (success) await _refreshDetail();
              if (!success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission could not be confirmed.')));
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
  Widget _buildAuditTrailCard() => _buildCard(
    title: 'Audit Trail', subtitle: 'Recorded status changes', icon: Icons.history, iconColor: Colors.purple,
    child: Column(children: [
      for (final event in (_detail?['statusHistory'] as List? ?? [])) ListTile(
        title: Text(event['toStatus'] ?? '—'),
        subtitle: Text([event['changedBy'], _formatDate(event['changedAt']), event['changeReason']].whereType<String>().join(' · ')),
      ),
    ]),
  );

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
