import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/portal_shell.dart';

class AppealsScreen extends StatefulWidget {
  const AppealsScreen({Key? key}) : super(key: key);

  @override
  State<AppealsScreen> createState() => _AppealsScreenState();
}
class _AppealsScreenState extends State<AppealsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseNoController = TextEditingController();
  final _descController = TextEditingController();
  bool _prefillTriggered = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // 'ALL', 'ACTIVE', 'CLOSED'
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefillTriggered) {
      _prefillTriggered = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final caseNo = args['caseNo'] as String?;
        final demandNoticeId = args['demandNoticeId'] as int?;
        final demandedAmount = args['demandedAmount'] as double?;
        final auditCaseId = args['auditCaseId'] as int?;
        final assessmentNo = args['assessmentNo'] as String?;
        final assessmentId = args['assessmentId'] as int?;

        if (caseNo != null) {
          _caseNoController.text = caseNo;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final taxpayerId = auth.currentUser?.taxpayerId ?? 0;
            _openFileAppealSheet(
              context,
              taxpayerId,
              auditCaseId: auditCaseId,
              demandNoticeId: demandNoticeId,
              demandedAmount: demandedAmount,
              caseNo: caseNo,
              assessmentNo: assessmentNo,
              assessmentId: assessmentId,
            );
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _caseNoController.dispose();
    _descController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFileAppealSheet(BuildContext context, int taxpayerId, {int? auditCaseId, int? demandNoticeId, double? demandedAmount, String? caseNo, String? assessmentNo, int? assessmentId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        final caseNoCtrl = TextEditingController(text: caseNo ?? _caseNoController.text);
        final disputedAmtCtrl = TextEditingController(text: demandedAmount != null ? demandedAmount.toStringAsFixed(0) : '');
        final groundsCtrl = TextEditingController();
        final reliefCtrl = TextEditingController();
        final evidenceCtrl = TextEditingController();
        final remarksCtrl = TextEditingController();
        String appealType = 'DEMAND_NOTICE';
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File an Appeal',
                                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submit your appeal against the audit assessment or demand notice.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Main Scrollable Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Context Banner (matching Angular appeal-context-banner)
                            if (caseNo != null || assessmentNo != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue.shade800, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                          children: [
                                            const TextSpan(
                                              text: 'Filing appeal for: ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            if (caseNo != null)
                                              TextSpan(text: 'Case $caseNo'),
                                            if (assessmentNo != null)
                                              TextSpan(text: ' · Assessment $assessmentNo'),
                                            if (demandedAmount != null) ...[
                                              const TextSpan(text: ' · Demanded Amount: '),
                                              TextSpan(
                                                text: '${demandedAmount.toStringAsFixed(2)} BDT',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // SECTION 1: Appeal Information
                            _buildSectionHeader(
                              icon: Icons.shield_outlined,
                              iconBg: Colors.cyan.shade50,
                              iconColor: Colors.cyan.shade800,
                              title: 'Appeal Information',
                              subtitle: 'Type of appeal and disputed amount',
                            ),
                            const SizedBox(height: 14),
                            
                            // If caseNo wasn't prefilled, let them enter it
                            if (caseNo == null) ...[
                              Text(
                                'Assessment Reference Case No *',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: caseNoCtrl,
                                decoration: InputDecoration(
                                  hintText: 'e.g. NBR/REF/2026/023',
                                  prefixIcon: const Icon(Icons.bookmark_outline, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Case number required' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Appeal Type (Dropdown)
                            Text(
                              'Appeal Type *',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: appealType,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'DEMAND_NOTICE', child: Text('Against Demand Notice')),
                                DropdownMenuItem(value: 'ASSESSMENT_ORDER', child: Text('Against Assessment Order')),
                                DropdownMenuItem(value: 'PENALTY', child: Text('Against Penalty')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setSheetState(() {
                                    appealType = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Disputed Amount
                            Text(
                              'Disputed Amount (BDT)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: disputedAmtCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                                hintText: '0.00',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Amount you are disputing.',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(),
                            ),
                            
                            // SECTION 2: Grounds for Appeal
                            _buildSectionHeader(
                              icon: Icons.description_outlined,
                              iconBg: Colors.amber.shade50,
                              iconColor: Colors.amber.shade800,
                              title: 'Grounds for Appeal',
                              subtitle: 'Explain clearly why you are disputing this assessment (minimum 50 characters)',
                            ),
                            const SizedBox(height: 14),
                            
                            // Grounds/Reasons Textarea
                            Text(
                              'Grounds / Reasons *',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: groundsCtrl,
                              maxLines: 6,
                              decoration: InputDecoration(
                                hintText: 'Explain your grounds for appeal in detail...',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 90),
                                  child: Icon(Icons.edit_note, size: 18),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) {
                                setSheetState(() {
                                  // Triggers character count update
                                });
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Grounds for appeal are required.';
                                }
                                if (v.trim().length < 50) {
                                  return 'Please provide at least 50 characters explaining your grounds.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${groundsCtrl.text.length} characters',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: groundsCtrl.text.length < 50 ? Colors.red.shade700 : Colors.grey.shade500,
                                    fontWeight: groundsCtrl.text.length < 50 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Relief Sought
                            Text(
                              'Relief Sought',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: reliefCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'What outcome are you requesting?...',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Icon(Icons.back_hand_outlined, size: 18),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Supporting Evidence
                            Text(
                              'Supporting Evidence (optional)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: evidenceCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'List documents you are attaching...',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Icon(Icons.attach_file, size: 18),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Additional Remarks
                            Text(
                              'Additional Remarks (optional)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: remarksCtrl,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Any other information...',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 25),
                                  child: Icon(Icons.chat_bubble_outline, size: 18),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Appeal Rights Notice Banner
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.green.shade800, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
                                        children: const [
                                          TextSpan(
                                            text: 'Appeal Rights: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: 'You have ',
                                          ),
                                          TextSpan(
                                            text: '45 days ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: 'from the date of the demand notice to file an appeal. Once submitted, your appeal will be reviewed by a tax officer and a hearing may be scheduled. The decision of the appeal authority is final unless further legal remedies are pursued.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Form Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            
                            final disputedAmt = double.tryParse(disputedAmtCtrl.text) ?? demandedAmount ?? 0.0;
                            
                            final appeal = Appeal(
                              id: 0,
                              taxpayerId: taxpayerId,
                              caseNo: caseNoCtrl.text,
                              description: groundsCtrl.text,
                              status: 'Filed',
                              auditCaseId: auditCaseId,
                              demandNoticeId: demandNoticeId,
                              assessmentId: assessmentId,
                              appealType: appealType,
                              demandedAmount: demandedAmount,
                              disputedAmount: disputedAmt,
                              groundsText: groundsCtrl.text,
                              reliefSought: reliefCtrl.text,
                              supportingEvidence: evidenceCtrl.text,
                              remarks: remarksCtrl.text,
                              appealNo: 'APPEAL-2026-${1000000 + DateTime.now().millisecondsSinceEpoch % 9000000}',
                              filedAt: DateTime.now().toIso8601String().substring(0, 10),
                              deadline: DateTime.now().add(const Duration(days: 45)).toIso8601String().substring(0, 10),
                            );

                            final success = await Provider.of<PortalProvider>(context, listen: false).createAppeal(appeal);
                            if (success && mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tax appeal case filed successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              _caseNoController.clear();
                              _descController.clear();
                            }
                          },
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('File Appeal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final taxpayerId = auth.currentUser?.taxpayerId ?? 0;
    final appeals = portalProv.appeals;

    // ── KPI calculations ──────────────────────────────────────────────────
    final totalAppeals = appeals.length;
    final activeAppeals = appeals.where((a) => a.status.toLowerCase() != 'closed' && a.status.toLowerCase() != 'decided').length;
    final totalDisputed = appeals.map((a) => a.disputedAmount ?? 0.0).fold(0.0, (sum, val) => sum + val);

    // ── Filtering Logic ───────────────────────────────────────────────────
    final filteredAppeals = appeals.where((appeal) {
      final matchesSearch = (appeal.appealNo ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          appeal.caseNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (appeal.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          appeal.status.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (appeal.appealType ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedFilter == 'ACTIVE') {
        return appeal.status.toLowerCase() != 'closed' && appeal.status.toLowerCase() != 'decided';
      }
      if (_selectedFilter == 'CLOSED') {
        return appeal.status.toLowerCase() == 'closed' || appeal.status.toLowerCase() == 'decided';
      }
      return true;
    }).toList();

    // ── Pagination Logic ──────────────────────────────────────────────────
    final int totalPages = (filteredAppeals.length / _pageSize).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    final int startIndex = (_currentPage - 1) * _pageSize;
    final List<Appeal> paginatedAppeals = filteredAppeals.skip(startIndex).take(_pageSize).toList();

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Appeals'],
      showBackButton: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFileAppealSheet(context, taxpayerId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.gavel_outlined),
        label: const Text('File Appeal'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Header
          Text(
            'My Appeals',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track legal tax appeals, hearing schedules, and official decisions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),

          // ── KPI CARDS ROW (Responsive Layout) ────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 600;
              final cards = [
                _buildKPICard(
                  title: 'Total Appeals',
                  value: '$totalAppeals',
                  icon: Icons.gavel_outlined,
                  color: Colors.teal,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
                _buildKPICard(
                  title: 'Active Appeals',
                  value: '$activeAppeals',
                  icon: Icons.hourglass_empty,
                  color: Colors.amber.shade800,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
                _buildKPICard(
                  title: 'Disputed Amount',
                  value: _formatAmt(totalDisputed),
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue,
                  isDark: isDark,
                  width: isWide ? null : 150,
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards.map((card) => Expanded(child: card)).toList(),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(children: cards),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ── SEARCH BAR ────────────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search appeals by number, status, details...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 16),

          // ── FILTER CHIPS ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Appeals'),
                _buildFilterChip('ACTIVE', 'Active / In Progress'),
                _buildFilterChip('CLOSED', 'Resolved / Closed'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── APPEALS LIST ──────────────────────────────────────────────────
          if (portalProv.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (paginatedAppeals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No tax appeals match your criteria.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginatedAppeals.length,
              itemBuilder: (context, index) {
                final appeal = paginatedAppeals[index];
                final isClosed = appeal.status.toLowerCase() == 'closed';
                final isHearing = appeal.status.toLowerCase() == 'hearing scheduled';

                Color statusColor = Colors.grey;
                if (isClosed) {
                  statusColor = Colors.black87;
                } else if (isHearing) {
                  statusColor = AppColors.warning;
                } else {
                  statusColor = AppColors.info;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                    ),
                  ),
                  elevation: 1,
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.backgroundDark : Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.gavel_outlined, color: Colors.amber.shade800, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Case number and status (Responsive text wrapping & spacing)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      appeal.appealNo ?? appeal.caseNo,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      appeal.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Description grounds statement
                              Text(
                                appeal.description ?? appeal.groundsText ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),

                              // Footer details and View Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 6,
                                      children: [
                                        _buildMetaInfoRow(Icons.calendar_today_outlined, 'Filed: ${appeal.filedAt ?? "—"}', isDark),
                                        _buildMetaInfoRow(Icons.gavel_outlined, 'Hearing: ${appeal.hearingDate ?? "Pending Schedule"}', isDark),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/appeal-details',
                                        arguments: appeal.id,
                                      );
                                    },
                                    icon: const Icon(Icons.visibility, size: 14),
                                    label: const Text('View', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── PAGINATION BAR ────────────────────────────────────────────────
            if (totalPages > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    double? width = 150,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = value;
              _currentPage = 1;
            });
          }
        },
      ),
    );
  }

  String _formatAmt(double? amt) {
    if (amt == null || amt == 0.0) return '৳ 0';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  Widget _buildMetaInfoRow(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark.withOpacity(0.8) : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
