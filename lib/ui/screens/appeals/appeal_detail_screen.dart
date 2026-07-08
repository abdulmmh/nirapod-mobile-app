import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class AppealDetailScreen extends StatefulWidget {
  const AppealDetailScreen({Key? key}) : super(key: key);

  @override
  State<AppealDetailScreen> createState() => _AppealDetailScreenState();
}

class _AppealDetailScreenState extends State<AppealDetailScreen> {
  bool _initialLoaded = false;
  late int _appealId;

  // Documents state variables
  List<AppealDocument>? _documents;
  bool _docsLoading = false;
  bool _uploading = false;
  bool _withdrawing = false;

  final List<String> _selectedFiles = [];
  final TextEditingController _uploadNoteController = TextEditingController();
  final TextEditingController _withdrawReasonController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoaded) {
      final int? argId = ModalRoute.of(context)?.settings.arguments as int?;
      if (argId != null) {
        _appealId = argId;
        _loadDocuments(_appealId);
      }
      _initialLoaded = true;
    }
  }

  @override
  void dispose() {
    _uploadNoteController.dispose();
    _withdrawReasonController.dispose();
    super.dispose();
  }

  void _loadDocuments(int appealId) async {
    setState(() => _docsLoading = true);
    final list = await Provider.of<PortalProvider>(context, listen: false).getAppealDocuments(appealId);
    if (mounted) {
      setState(() {
        _documents = list;
        _docsLoading = false;
      });
    }
  }

  String _formatLongDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatShortDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  int? _daysUntilDeadline(String? deadlineStr) {
    if (deadlineStr == null || deadlineStr.isEmpty) return null;
    try {
      final deadline = DateTime.parse(deadlineStr);
      final today = DateTime.now();
      final diff = deadline.difference(DateTime(today.year, today.month, today.day)).inDays;
      return diff;
    } catch (_) {
      return null;
    }
  }

  bool _canUpload(Appeal appeal) {
    final s = appeal.status.toUpperCase();
    return !['DECIDED', 'CLOSED', 'WITHDRAWN'].contains(s);
  }

  bool _canWithdraw(Appeal appeal) {
    final s = appeal.status.toUpperCase();
    return ['FILED', 'UNDER_REVIEW'].contains(s);
  }

  void _showSimulateFilePicker() {
    final mockFiles = [
      'Salary_Receipt_Form16.pdf',
      'Bank_Statement_NonTaxable_Transfers.pdf',
      'Tax_Source_Challan_Copy.jpg',
      'Family_Gift_Declaration.docx',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Simulated File Picker', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: mockFiles.map((filename) {
              return ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(filename, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    if (!_selectedFiles.contains(filename)) {
                      _selectedFiles.add(filename);
                    }
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String? type) {
    if (type == null) return Icons.insert_drive_file;
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('jpg') || t.contains('jpeg') || t.contains('png')) return Icons.image;
    if (t.contains('doc') || t.contains('docx')) return Icons.description;
    if (t.contains('xls') || t.contains('xlsx') || t.contains('csv')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showWithdrawDialog(BuildContext context, int appealId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Withdraw Appeal?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Once withdrawn, your appeal cannot be reinstated. The original demand notice will be restored.',
                    style: TextStyle(fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _withdrawReasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'State reason for withdrawing your appeal...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _withdrawing ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _withdrawing
                      ? null
                      : () async {
                          setDialogState(() => _withdrawing = true);
                          setState(() => _withdrawing = true);

                          final success = await Provider.of<PortalProvider>(context, listen: false)
                              .withdrawAppeal(appealId, _withdrawReasonController.text.trim());

                          if (mounted) {
                            setDialogState(() => _withdrawing = false);
                            setState(() => _withdrawing = false);
                            Navigator.pop(context);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Appeal withdrawn successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _withdrawing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Withdraw', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDecisionBanner(Appeal appeal, String Function(double?) formatCurrency) {
    final decision = appeal.decision?.toUpperCase() ?? '';
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    if (decision == 'UPHELD') {
      bgColor = const Color(0xFFF0FDF4); // light green
      borderColor = Colors.green.shade200;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      title = 'Appeal Successful!';
      message = 'Your appeal was successful. The demand has been cancelled.';
    } else if (decision == 'PARTIALLY_UPHELD') {
      bgColor = const Color(0xFFF7FEE7); // light lime
      borderColor = Colors.lime.shade300;
      textColor = Colors.lime.shade900;
      icon = Icons.shield_outlined;
      title = 'Partial Relief Granted.';
      message = 'Your appeal was partially successful. Relief amount: ${formatCurrency(appeal.reliefGranted)} BDT';
    } else {
      // DISMISSED
      bgColor = const Color(0xFFFEF2F2); // light red
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade900;
      icon = Icons.cancel;
      title = 'Appeal Dismissed.';
      message = 'Your appeal was dismissed. The original demand remains in effect.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHearingBanner(Appeal appeal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // light blue
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.blue.shade800, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.blue.shade900, fontSize: 13.5, height: 1.4),
                children: [
                  const TextSpan(text: 'Hearing Scheduled: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${_formatShortDate(appeal.hearingDate)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBanner(Appeal appeal) {
    final days = _daysUntilDeadline(appeal.deadline);
    if (days == null) return const SizedBox.shrink();

    Color bgColor;
    Color borderColor;
    Color textColor;
    String message;

    if (days < 0) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = Colors.red.shade200;
      textColor = Colors.red.shade900;
      message = 'Appeal deadline expired ${days.abs()} days ago.';
    } else if (days == 0) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      message = 'Appeal deadline is today!';
    } else if (days <= 7) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      message = 'Urgent: $days days remaining to appeal.';
    } else {
      bgColor = const Color(0xFFF9FAFB);
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      message = '$days days remaining to appeal.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.alarm, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                children: [
                  const TextSpan(text: 'Appeal Deadline: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: '${_formatShortDate(appeal.deadline)} — $message'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Appeal appeal, String Function(double?) formatCurrency, bool isDark) {
    final status = appeal.status.toUpperCase();
    if (status != 'DECIDED' && status != 'CLOSED') {
      return const SizedBox.shrink();
    }

    final decision = appeal.decision?.toUpperCase() ?? '';

    if (decision == 'DISMISSED') {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        color: const Color(0xFFFEF2F2),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Payment Required',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your appeal was dismissed. The full demanded amount of ${formatCurrency(appeal.demandedAmount)} BDT must be paid by the original due date.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _simulatePaymentRedirect(context, appeal.demandedAmount, appeal.appealNo ?? appeal.caseNo),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (decision == 'PARTIALLY_UPHELD') {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.amber.shade200),
        ),
        color: const Color(0xFFFEFDF6),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partial Payment Required',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accepted amount of ${formatCurrency(appeal.acceptedAmount)} BDT. Relief granted: ${formatCurrency(appeal.reliefGranted)} BDT.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _simulatePaymentRedirect(context, appeal.acceptedAmount, appeal.appealNo ?? appeal.caseNo),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Pay Accepted Amount'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (decision == 'UPHELD') {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade200),
        ),
        color: const Color(0xFFF4FBF7),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade800, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Payment Required',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your appeal was fully upheld. The demand has been cancelled.',
                      style: TextStyle(color: Colors.green.shade900, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _simulatePaymentRedirect(BuildContext context, double? amount, String referenceNo) {
    Navigator.pushNamed(
      context,
      '/payment-create',
      arguments: {
        'amount': amount ?? 0.0,
        'paymentType': 'Demand Notice',
        'returnNo': referenceNo,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);

    // Get appeal ID from route settings arguments
    final int? appealId = ModalRoute.of(context)?.settings.arguments as int?;

    if (appealId == null) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Appeals', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Error: No Appeal Selected',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    // Find appeal from provider list
    final appeal = portalProv.appeals.firstWhere(
      (a) => a.id == appealId,
      orElse: () => Appeal(
        id: 0,
        taxpayerId: 0,
        caseNo: 'Unknown',
        status: 'Unknown',
      ),
    );

    if (appeal.id == 0) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Appeals', 'Details'],
        showBackButton: true,
        body: Center(
          child: Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Error: Appeal Record Not Found',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatCurrency(double? val) {
      if (val == null) return '0.00';
      return val.toStringAsFixed(2).replaceAllMapped(formatter, (Match m) => '${m[1]},');
    }

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Appeals', 'Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Back Button Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appeal Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track the status of your filed appeal.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Dynamic Decision Alert Banner
            if (appeal.decision != null) ...[
              _buildDecisionBanner(appeal, formatCurrency),
              const SizedBox(height: 16),
            ],

            // 2. Hearing Scheduled Alert Banner
            if (appeal.status.toUpperCase() == 'HEARING_SCHEDULED') ...[
              _buildHearingBanner(appeal),
              const SizedBox(height: 16),
            ],

            // 3. Deadline Alert Banner
            if (['FILED', 'UNDER_REVIEW', 'HEARING_SCHEDULED'].contains(appeal.status.toUpperCase()) &&
                appeal.deadline != null) ...[
              _buildDeadlineBanner(appeal),
              const SizedBox(height: 16),
            ],

            // Status Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          appeal.appealNo ?? appeal.caseNo,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            appeal.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildStatusMetaItem(Icons.label_outline, 'DEMAND NOTICE', isDark),
                        _buildStatusMetaItem(Icons.calendar_today_outlined, 'Filed ${_formatShortDate(appeal.filedAt)}', isDark),
                        _buildStatusMetaItem(Icons.hourglass_empty_outlined, 'Deadline: ${_formatShortDate(appeal.deadline)}', isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Financial Details Grid Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Financial Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amounts involved in this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    isMobile
                        ? Column(
                            children: [
                              _buildFinancialBox('Total Demanded', '${formatCurrency(appeal.demandedAmount)} BDT', const Color(0xFFFEF2F2), Colors.red.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Amount Disputed', '${formatCurrency(appeal.disputedAmount)} BDT', const Color(0xFFFFFBEB), Colors.amber.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Relief Granted', '${formatCurrency(appeal.reliefGranted)} BDT', const Color(0xFFF0FDF4), Colors.green.shade900),
                              const SizedBox(height: 8),
                              _buildFinancialBox('Accepted Amount', '${formatCurrency(appeal.acceptedAmount)} BDT', const Color(0xFFEFF6FF), Colors.blue.shade900),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildFinancialBox('Total Demanded', '${formatCurrency(appeal.demandedAmount)} BDT', const Color(0xFFFEF2F2), Colors.red.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Amount Disputed', '${formatCurrency(appeal.disputedAmount)} BDT', const Color(0xFFFFFBEB), Colors.amber.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Relief Granted', '${formatCurrency(appeal.reliefGranted)} BDT', const Color(0xFFF0FDF4), Colors.green.shade900)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildFinancialBox('Accepted Amount', '${formatCurrency(appeal.acceptedAmount)} BDT', const Color(0xFFEFF6FF), Colors.blue.shade900)),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Dynamic Payment Section
            _buildPaymentSection(appeal, formatCurrency, isDark),

            // Grounds & Relief sought card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Your Grounds',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reasons submitted for this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      appeal.groundsText ?? appeal.description ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (appeal.reliefSought != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FBF7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          'Relief Sought: ${appeal.reliefSought}',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Supporting Documents Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Supporting Documents',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Documents submitted in support of this appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // File picker simulation if allowed
                    if (_canUpload(appeal)) ...[
                      InkWell(
                        onTap: _uploading ? null : _showSimulateFilePicker,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Colors.blue.shade700, size: 32),
                              const SizedBox(height: 8),
                              const Text('Click to pick mock files to upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text('PDF, JPG, PNG, XLSX — max 10MB each', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ),

                      // Selected files listing
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ..._selectedFiles.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final name = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                Icon(Icons.insert_drive_file, color: Colors.blue.shade700, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedFiles.removeAt(idx);
                                    });
                                  },
                                  child: const Icon(Icons.close, color: Colors.red, size: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Description textfield
                      const SizedBox(height: 12),
                      const Text('Description / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _uploadNoteController,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Brief description of uploaded documents...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                      ),

                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _selectedFiles.isEmpty || _uploading
                            ? null
                            : () async {
                                setState(() => _uploading = true);
                                final provider = Provider.of<PortalProvider>(context, listen: false);

                                for (final file in _selectedFiles) {
                                  await provider.uploadAppealDocument(
                                    appeal.id,
                                    file,
                                    _uploadNoteController.text.trim().isNotEmpty
                                        ? _uploadNoteController.text.trim()
                                        : 'Supporting document: $file',
                                  );
                                }

                                if (mounted) {
                                  setState(() {
                                    _uploading = false;
                                    _selectedFiles.clear();
                                    _uploadNoteController.clear();
                                    _loadDocuments(appeal.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Documents uploaded successfully!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  });
                                }
                              },
                        icon: _uploading
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_upload_outlined, size: 14),
                        label: const Text('Upload Documents', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const Divider(height: 24),
                    ],

                    // Documents List
                    if (_docsLoading) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ] else if (_documents == null || _documents!.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No documents uploaded yet.',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _documents!.length,
                        itemBuilder: (context, index) {
                          final doc = _documents![index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                              child: Icon(_getFileIcon(doc.fileType), color: Colors.teal.shade700, size: 20),
                            ),
                            title: Text(doc.originalFileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${_formatFileSize(doc.fileSize)} · ${doc.uploadedByName ?? doc.uploadedBy ?? "Taxpayer"} · ${_formatShortDate(doc.uploadedAt)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download, size: 18),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Downloading file: ${doc.originalFileName}')),
                                    );
                                  },
                                ),
                                if (_canUpload(appeal))
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () async {
                                      final success = await Provider.of<PortalProvider>(context, listen: false).deleteAppealDocument(appeal.id, doc.id);
                                      if (success && mounted) {
                                        _loadDocuments(appeal.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Document deleted successfully!'), backgroundColor: AppColors.success),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Decision outcome Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
              ),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, color: Colors.teal.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Decision',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Official decision on your appeal',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      'Outcome',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appeal.decision ?? 'PENDING DECISION',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decided By',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  appeal.decidedBy ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Decided On',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatShortDate(appeal.decidedAt),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (appeal.decisionNotes != null && appeal.decisionNotes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Decision Notes',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          appeal.decisionNotes!,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Withdraw Button
            if (_canWithdraw(appeal)) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showWithdrawDialog(context, appeal.id),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Withdraw Appeal', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetaItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBox(String title, String val, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
