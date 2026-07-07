import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class AuditDetailScreen extends StatefulWidget {
  const AuditDetailScreen({Key? key}) : super(key: key);

  @override
  State<AuditDetailScreen> createState() => _AuditDetailScreenState();
}

class _AuditDetailScreenState extends State<AuditDetailScreen> {
  String _activeTab = 'overview';
  bool _initialLoaded = false;
  late int _auditId;

  // Local caching variables
  List<AuditQuery>? _queries;
  List<AuditDocumentRequest>? _docRequests;
  Assessment? _assessment;
  DemandNotice? _demandNotice;

  bool _queriesLoading = false;
  bool _docsLoading = false;
  bool _assessmentLoading = false;
  bool _demandLoading = false;

  // Form handling variables
  final Map<int, TextEditingController> _queryTextControllers = {};
  final Map<int, String?> _queryRespondingError = {};
  final Map<int, bool> _queryResponding = {};

  final Map<int, List<String>> _selectedFiles = {};
  final Map<int, TextEditingController> _uploadNoteControllers = {};
  final Map<int, bool> _uploading = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoaded) {
      final int? argId = ModalRoute.of(context)?.settings.arguments as int?;
      if (argId != null) {
        _auditId = argId;
        final portalProv = Provider.of<PortalProvider>(context, listen: false);
        final audit = portalProv.audits.firstWhere(
          (a) => a.id == _auditId,
          orElse: () => Audit(id: 0, taxpayerId: 0, year: '', status: '', caseNo: '', auditType: '', taxType: ''),
        );
        if (audit.id != 0) {
          if (audit.hasDemandNotice) {
            _loadDemand(audit.id);
          }
          if (audit.hasAssessment) {
            _loadAssessment(audit.id);
          }
        }
      }
      _initialLoaded = true;
    }
  }

  @override
  void dispose() {
    for (var controller in _queryTextControllers.values) {
      controller.dispose();
    }
    for (var controller in _uploadNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadQueries(int caseId) async {
    if (_queries != null) return;
    setState(() => _queriesLoading = true);
    final list = await Provider.of<PortalProvider>(context, listen: false).getQueries(caseId);
    if (mounted) {
      setState(() {
        _queries = list;
        _queriesLoading = false;
      });
    }
  }

  void _loadDocRequests(int caseId) async {
    if (_docRequests != null) return;
    setState(() => _docsLoading = true);
    final list = await Provider.of<PortalProvider>(context, listen: false).getDocumentRequests(caseId);
    if (mounted) {
      setState(() {
        _docRequests = list;
        _docsLoading = false;
      });
    }
  }

  void _loadAssessment(int caseId) async {
    if (_assessment != null) return;
    setState(() => _assessmentLoading = true);
    final record = await Provider.of<PortalProvider>(context, listen: false).getMyAssessment(caseId);
    if (mounted) {
      setState(() {
        _assessment = record;
        _assessmentLoading = false;
      });
    }
  }

  void _loadDemand(int caseId) async {
    if (_demandNotice != null) return;
    setState(() => _demandLoading = true);
    final record = await Provider.of<PortalProvider>(context, listen: false).getMyDemandNotice(caseId);
    if (mounted) {
      setState(() {
        _demandNotice = record;
        _demandLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
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

  String _formatCurrency(double? val) {
    if (val == null) return '৳ 0.00';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(val);
  }

  bool _isOverdue(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _requiresAction(Audit c) {
    final status = c.status.toUpperCase();
    return ['DOCUMENT_REQUESTED', 'NOTICE_ISSUED', 'DEMAND_ISSUED'].contains(status) ||
        c.openQueryCount > 0;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CLOSED':
      case 'PAID':
        return AppColors.success;
      case 'DOCUMENT_REQUESTED':
        return Colors.orange.shade700;
      case 'NOTICE_ISSUED':
      case 'ASSESSMENT_PROPOSED':
        return Colors.amber.shade800;
      case 'DEMAND_ISSUED':
        return AppColors.error;
      case 'UNDER_REVIEW':
      case 'CASE_CREATED':
      default:
        return AppColors.info;
    }
  }

  String _getTypeLabel(String t) {
    switch (t.toUpperCase()) {
      case 'DESK': return 'Desk';
      case 'FIELD': return 'Field';
      case 'COMPREHENSIVE': return 'Comprehensive';
      case 'VAT': return 'VAT';
      case 'REFUND': return 'Refund';
      case 'SPECIAL': return 'Special';
      default: return t;
    }
  }

  String _getTaxTypeLabel(String t) {
    switch (t.toUpperCase()) {
      case 'INCOME_TAX': return 'Income Tax';
      case 'VAT': return 'VAT';
      case 'AIT': return 'AIT';
      default: return t;
    }
  }

  // Simulations
  void _simulateDownload(String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('$type downloaded successfully to Downloads folder.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            });
            return AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Text('Downloading $type...'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _simulateFileAppeal(Audit audit, String refNo, double amount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.error),
              const SizedBox(width: 10),
              const Text('Integrate File Appeal'),
            ],
          ),
          content: Text(
            'This action will redirect you to file a legal appeal for the Demand Notice ($refNo) of BDT ${amount.toStringAsFixed(0)}.\n\nWould you like to simulate launching the Appeal Creation wizard?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulation: Launching Appeal Creation Wizard'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    // Get audit ID from route settings arguments
    final int? argId = ModalRoute.of(context)?.settings.arguments as int?;
    if (argId == null) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Audits', 'Details'],
        showBackButton: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('Error: No active Audit Case ID provided.'),
          ),
        ),
      );
    }

    final audit = portalProv.audits.firstWhere(
      (a) => a.id == argId,
      orElse: () => Audit(id: 0, taxpayerId: 0, year: '', status: '', caseNo: 'Unknown', auditType: '', taxType: ''),
    );

    if (audit.id == 0) {
      return const PortalShell(
        breadcrumbs: ['My Portal', 'Audits', 'Details'],
        showBackButton: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('Error: Audit Case record not found.'),
          ),
        ),
      );
    }

    final hasAction = _requiresAction(audit);
    final statusColor = _getStatusColor(audit.status);

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Audits', 'Details'],
      showBackButton: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top breadcrumbs & Title Header block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        audit.caseNo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Audit Case Details',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildMetaChip(Icons.bookmark_outline, _getTypeLabel(audit.auditType)),
                        _buildMetaChip(Icons.calendar_today_outlined, audit.year),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            audit.status.replaceAll('_', ' '),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning Action Banner
            if (hasAction) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: Colors.orange.shade800, width: 4),
                    top: BorderSide(color: Colors.orange.shade200),
                    right: BorderSide(color: Colors.orange.shade200),
                    bottom: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Action Required',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            audit.status == 'DOCUMENT_REQUESTED'
                                ? 'Documents have been requested by the Audit Officer. Please upload them.'
                                : 'You have pending query responses. Please review and reply.',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (audit.status == 'DOCUMENT_REQUESTED') {
                          setState(() => _activeTab = 'documents');
                          _loadDocRequests(audit.id);
                        } else {
                          setState(() => _activeTab = 'queries');
                          _loadQueries(audit.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Respond Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // Outstanding Demand alert banner
            if (audit.status == 'DEMAND_ISSUED' && _demandNotice != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: Colors.red.shade600, width: 4),
                    top: BorderSide(color: Colors.red.shade200),
                    right: BorderSide(color: Colors.red.shade200),
                    bottom: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demand Notice Issued',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Amount Due: ${_formatCurrency(_demandNotice!.amountDue)} · Due: ${_formatShortDate(_demandNotice!.dueDate)}',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/payment-create',
                          arguments: {
                            'amount': _demandNotice!.amountDue,
                            'paymentType': 'Demand Notice',
                            'returnNo': _demandNotice!.demandNo,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Pay Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // Custom tab bar row selector inside white card wrapper
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    _buildTabButton('overview', 'Details', Icons.info_outline),
                    _buildTabButton('queries', 'Queries', Icons.chat_bubble_outline,
                        badgeCount: audit.openQueryCount > 0 ? audit.openQueryCount : null),
                    _buildTabButton('documents', 'Documents', Icons.folder_open_outlined),
                    if (audit.hasAssessment)
                      _buildTabButton('assessment', 'Assessment Order', Icons.calculate_outlined),
                    if (audit.hasDemandNotice)
                      _buildTabButton('demand', 'Demand Notice', Icons.receipt_long_outlined),
                  ],
                ),
              ),
            ),

            // Tab View content switcher
            _buildActiveTabContent(audit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String title, IconData icon, {int? badgeCount}) {
    final isActive = _activeTab == tabKey;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : Colors.grey.shade700,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade900,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        selected: isActive,
        selectedColor: Colors.blue.shade900,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? Colors.blue.shade900 : Colors.blue.shade100,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeTab = tabKey);
            if (tabKey == 'queries') _loadQueries(_auditId);
            if (tabKey == 'documents') _loadDocRequests(_auditId);
            if (tabKey == 'assessment') _loadAssessment(_auditId);
            if (tabKey == 'demand') _loadDemand(_auditId);
          }
        },
      ),
    );
  }

  Widget _buildActiveTabContent(Audit audit) {
    switch (_activeTab) {
      case 'queries':
        return _buildQueriesView(audit);
      case 'documents':
        return _buildDocumentsView(audit);
      case 'assessment':
        return _buildAssessmentView(audit);
      case 'demand':
        return _buildDemandView(audit);
      case 'overview':
      default:
        return _buildOverviewView(audit);
    }
  }

  // ── 1. OVERVIEW VIEW ──────────────────────────────────────────────────────
  Widget _buildOverviewView(Audit audit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isTwoCol = width > 700;

        final caseInfoCard = Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder, color: Colors.blue.shade800, size: 18),
                    const SizedBox(width: 8),
                    const Text('Case Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDetailsRow('Case No', audit.caseNo, isMonospaceValue: true),
                const SizedBox(height: 10),
                _buildDetailsRow('Audit Type', _getTypeLabel(audit.auditType)),
                const SizedBox(height: 10),
                _buildDetailsRow('Tax Type', _getTaxTypeLabel(audit.taxType)),
                const SizedBox(height: 10),
                _buildDetailsRow('Fiscal Year', audit.year),
                const SizedBox(height: 10),
                _buildDetailsRow(
                  'Period',
                  '${audit.taxPeriodStart ?? '—'} → ${audit.taxPeriodEnd ?? '—'}',
                ),
                const SizedBox(height: 10),
                _buildDetailsRow('Status', audit.status.replaceAll('_', ' ')),
              ],
            ),
          ),
        );

        final contactCard = Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue.shade800, size: 18),
                    const SizedBox(width: 8),
                    const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDetailsRow('Audit Officer', audit.assignedOfficerName ?? '—'),
                const SizedBox(height: 10),
                _buildDetailsRow('Supervisor', audit.supervisorName ?? '—'),
                const SizedBox(height: 10),
                _buildDetailsRow(
                  'Due Date',
                  _formatShortDate(audit.dueDate),
                  valueColor: _isOverdue(audit.dueDate) ? Colors.red.shade700 : null,
                ),
                const SizedBox(height: 10),
                _buildDetailsRow('Notice Issued', _formatShortDate(audit.createdAt)),
              ],
            ),
          ),
        );

        if (isTwoCol) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: caseInfoCard),
              const SizedBox(width: 16),
              Expanded(child: contactCard),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              caseInfoCard,
              const SizedBox(height: 16),
              contactCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildDetailsRow(String label, String value, {bool isMonospaceValue = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontFamily: isMonospaceValue ? 'monospace' : null,
              color: isMonospaceValue
                  ? Colors.blue.shade800
                  : (valueColor ?? Colors.grey.shade900),
              backgroundColor: isMonospaceValue ? Colors.blue.shade50 : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. QUERIES VIEW ───────────────────────────────────────────────────────
  Widget _buildQueriesView(Audit audit) {
    if (_queriesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_queries == null || _queries!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No queries have been raised yet.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Queries from Audit Officer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ..._queries!.map((q) => _buildQueryCard(audit.id, q)).toList(),
      ],
    );
  }

  Widget _buildQueryCard(int caseId, AuditQuery q) {
    final isOpen = q.status.toUpperCase() == 'OPEN';
    final hasResponse = q.responseText != null && q.responseText!.isNotEmpty;

    // Form controllers initializer
    if (!_queryTextControllers.containsKey(q.id)) {
      _queryTextControllers[q.id] = TextEditingController();
    }
    final textController = _queryTextControllers[q.id]!;
    final isResponding = _queryResponding[q.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header elements
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    q.queryNo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    q.queryType,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.amber.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isOpen ? Colors.amber.shade200 : Colors.green.shade200),
                  ),
                  child: Text(
                    q.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: isOpen ? Colors.amber.shade900 : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (q.deadline != null)
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatShortDate(q.deadline)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              q.queryText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.5),
            ),

            // Already Responded Block
            if (hasResponse) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border(left: BorderSide(color: Colors.green.shade600, width: 3)),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade800, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Your Response',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.responseText!,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Responded: ${_formatShortDate(q.respondedAt)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],

            // Submit Response Form
            if (isOpen) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Type your response here...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(8),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    if (_queryRespondingError[q.id] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _queryRespondingError[q.id]!,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isResponding
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) {
                                setState(() {
                                  _queryRespondingError[q.id] = 'Response cannot be empty.';
                                });
                                return;
                              }
                              setState(() {
                                _queryResponding[q.id] = true;
                                _queryRespondingError[q.id] = null;
                              });

                              final provider = Provider.of<PortalProvider>(context, listen: false);
                              final success = await provider.respondToQuery(caseId, q.id, text);

                              if (mounted) {
                                setState(() {
                                  _queryResponding[q.id] = false;
                                  if (success) {
                                    // Refresh cached queries lists
                                    _queries = null;
                                    _loadQueries(caseId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Response submitted successfully!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    _queryRespondingError[q.id] = 'Failed to submit response.';
                                  }
                                });
                              }
                            },
                      icon: isResponding
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, size: 14),
                      label: const Text('Submit Response', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. DOCUMENTS VIEW ────────────────────────────────────────────────────
  Widget _buildDocumentsView(Audit audit) {
    if (_docsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_docRequests == null || _docRequests!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No document requests yet.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Requests',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ..._docRequests!.map((dr) => _buildDocRequestCard(audit.id, dr)).toList(),
      ],
    );
  }

  Widget _buildDocRequestCard(int caseId, AuditDocumentRequest dr) {
    final isPending = dr.status.toUpperCase() == 'PENDING' || dr.status.toUpperCase() == 'PARTIALLY_FULFILLED';
    final isFulfilled = dr.status.toUpperCase() == 'FULFILLED';

    // State bindings
    if (!_selectedFiles.containsKey(dr.id)) {
      _selectedFiles[dr.id] = [];
    }
    final fileList = _selectedFiles[dr.id]!;

    if (!_uploadNoteControllers.containsKey(dr.id)) {
      _uploadNoteControllers[dr.id] = TextEditingController();
    }
    final noteController = _uploadNoteControllers[dr.id]!;
    final isUploading = _uploading[dr.id] ?? false;

    Color badgeColor;
    switch (dr.status.toUpperCase()) {
      case 'FULFILLED':
        badgeColor = AppColors.success;
        break;
      case 'PARTIALLY_FULFILLED':
        badgeColor = Colors.lime.shade800;
        break;
      default:
        badgeColor = Colors.orange.shade800;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header properties
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    dr.requestNo,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    dr.requestType,
                    style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    dr.status,
                    style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (dr.deadline != null)
                  Row(
                    children: [
                      Icon(Icons.alarm, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatShortDate(dr.deadline)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isOverdue(dr.deadline) ? Colors.red.shade700 : Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.blue.shade800, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dr.requestedDocuments,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            if (dr.requestReason != null && dr.requestReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                dr.requestReason!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
            ],

            // Fulfilled label
            if (isFulfilled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Fulfilled: ${dr.fulfillmentNotes ?? 'Documents submitted.'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],

            // Upload widget zone
            if (isPending) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload Documents', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // File picker simulation card
                    InkWell(
                      onTap: () {
                        // Show simulator files list choice
                        _showSimulateFilePicker(dr.id);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                    if (fileList.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...fileList.asMap().entries.map((entry) {
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
                                    fileList.removeAt(idx);
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
                      controller: noteController,
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
                      onPressed: fileList.isEmpty || isUploading
                          ? null
                          : () async {
                              setState(() {
                                _uploading[dr.id] = true;
                              });

                              final provider = Provider.of<PortalProvider>(context, listen: false);
                              final success = await provider.uploadDocumentForRequest(
                                caseId,
                                dr.id,
                                noteController.text.trim().isNotEmpty
                                    ? '${noteController.text.trim()} (${fileList.join(", ")})'
                                    : 'Uploaded: ${fileList.join(", ")}',
                              );

                              if (mounted) {
                                setState(() {
                                  _uploading[dr.id] = false;
                                  if (success) {
                                    _selectedFiles[dr.id] = [];
                                    noteController.clear();
                                    // Refresh doc request cached lists
                                    _docRequests = null;
                                    _loadDocRequests(caseId);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Documents uploaded successfully!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                      icon: isUploading
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
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSimulateFilePicker(int reqId) {
    final mockFiles = [
      'Bank_Statement_FY24_25.pdf',
      'DPS_Rebate_Certificate.jpg',
      'Form_16_TDS_Employer.pdf',
      'Vat_Returns_Credit_Ledger.xlsx',
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
                    if (!_selectedFiles[reqId]!.contains(filename)) {
                      _selectedFiles[reqId]!.add(filename);
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

  // ── 4. ASSESSMENT ORDER VIEW ─────────────────────────────────────────────
  Widget _buildAssessmentView(Audit audit) {
    if (_assessmentLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_assessment == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('No Assessment Order recorded for this case.')),
        ),
      );
    }

    final asm = _assessment!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letterhead
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.blue.shade800, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('NBR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'National Board of Revenue',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Government of the People's Republic of Bangladesh",
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ASSESSMENT ORDER',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 15, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${asm.assessmentNo}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.blue, thickness: 1.5),
            const SizedBox(height: 12),

            // Party Metadata
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _buildOrderPartyItem('TAXPAYER', asm.taxpayerName),
                  _buildOrderPartyItem('TIN', asm.tinNumber, isMonospace: true),
                  _buildOrderPartyItem('FISCAL YEAR', asm.fiscalYear),
                  _buildOrderPartyItem('TAX TYPE', _getTaxTypeLabel(asm.taxType)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Findings Summary
            _buildOrderSectionTitle('Findings Summary'),
            Text(
              asm.findingsSummary ?? 'As per audit findings.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),

            // Legal Basis
            _buildOrderSectionTitle('Legal Basis'),
            Text(
              asm.legalBasis ?? '—',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),

            // Demand Calculations
            _buildOrderSectionTitle('Demand Calculation'),
            const SizedBox(height: 6),
            Table(
              border: TableBorder(bottom: BorderSide(color: Colors.grey.shade200)),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              children: [
                _buildOrderTableRow('Declared Tax', _formatCurrency(asm.declaredTax)),
                _buildOrderTableRow('Assessed Tax', _formatCurrency(asm.assessedTax)),
                _buildOrderTableRow(
                  'Additional Tax',
                  _formatCurrency(asm.additionalTax),
                  bgColor: Colors.amber.shade50,
                  isBold: true,
                ),
                _buildOrderTableRow('Penalty (${asm.penaltyRate.toStringAsFixed(0)}%)', _formatCurrency(asm.penaltyAmount)),
                _buildOrderTableRow('Interest (${asm.interestRate.toStringAsFixed(0)}% × ${asm.interestMonths} months)', _formatCurrency(asm.interestAmount)),
                _buildOrderTableRow(
                  'TOTAL DEMAND',
                  _formatCurrency(asm.totalDemand),
                  bgColor: Colors.red.shade50,
                  isBold: true,
                  textColor: Colors.red.shade900,
                  fontSize: 14,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Appeal Rights Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border(left: BorderSide(color: Colors.blue.shade700, width: 3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade800, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asm.appealRights ?? 'Taxpayer may file an appeal within 45 days of this order.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOrderFooterItem('Payment Deadline', _formatShortDate(asm.paymentDeadline), isRed: true),
                _buildOrderFooterItem('Approved By', asm.approvedBy ?? '—'),
                _buildOrderFooterItem('Approved On', _formatShortDate(asm.approvedAt)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 6),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _simulateDownload('Assessment Order'),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _simulateFileAppeal(audit, asm.assessmentNo, asm.totalDemand),
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: const Text('File Appeal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderPartyItem(String label, String value, {bool isMonospace = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        isMonospace
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              )
            : Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
      ],
    );
  }

  Widget _buildOrderSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 4),
      ],
    );
  }

  TableRow _buildOrderTableRow(String desc, String amt, {Color? bgColor, bool isBold = false, Color? textColor, double fontSize = 13}) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: textColor ?? Colors.grey.shade900,
    );
    return TableRow(
      decoration: bgColor != null ? BoxDecoration(color: bgColor) : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(desc, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(amt, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }

  Widget _buildOrderFooterItem(String label, String value, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red.shade700 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ── 5. DEMAND NOTICE VIEW ────────────────────────────────────────────────
  Widget _buildDemandView(Audit audit) {
    if (_demandLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_demandNotice == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: Text('No Demand Notice issued for this case.')),
        ),
      );
    }

    final dm = _demandNotice!;
    final overdue = _isOverdue(dm.dueDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'DEMAND NOTICE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
                Text(
                  dm.demandNo,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Large Amount Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                children: [
                  Text(
                    'TOTAL AMOUNT DUE',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(dm.amountDue),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.red.shade800),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pay by: ${_formatDate(dm.dueDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                      ),
                      if (overdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                          child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Party Meta details
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildDemandMetaItem('TAXPAYER', dm.taxpayerName ?? '—'),
                  _buildDemandMetaItem('TIN', dm.tinNumber ?? '—', isMonospace: true),
                  _buildDemandMetaItem('ASSESSMENT NO', dm.assessmentNo ?? '—', isMonospace: true),
                  _buildDemandMetaItem('ISSUED BY', dm.issuedBy ?? '—'),
                  _buildDemandMetaItem('ISSUED ON', _formatShortDate(dm.issuedAt)),
                  _buildDemandMetaItem('STATUS', dm.status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Instructions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(left: BorderSide(color: Colors.green.shade600, width: 3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.green.shade900, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Instructions',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dm.paymentInstructions ?? 'Please deposit the demanded amount at any Sonali Bank branch.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 6),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _simulateDownload('Demand Notice'),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Notice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade800,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/payment-create',
                      arguments: {
                        'amount': dm.amountDue,
                        'paymentType': 'Demand Notice',
                        'returnNo': dm.demandNo,
                      },
                    );
                  },
                  icon: const Icon(Icons.credit_card, size: 16),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _simulateFileAppeal(audit, dm.demandNo, dm.amountDue),
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: const Text('File Appeal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandMetaItem(String label, String value, {bool isMonospace = false}) {
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
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
              )
            : Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
              ),
      ],
    );
  }
}
