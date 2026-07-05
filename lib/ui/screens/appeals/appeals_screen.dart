import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void dispose() {
    _caseNoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _openFileAppealSheet(BuildContext context, int taxpayerId) {
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
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File Legal Tax Appeal',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: _caseNoController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Reference Case No',
                      hintText: 'e.g. NBR/REF/2026/023',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Case number required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Grounds of Appeal / Description',
                      hintText: 'State legal arguments or justification for the appeal...',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Grounds of appeal required' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'File Appeal',
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      final appeal = Appeal(
                        id: 0,
                        taxpayerId: taxpayerId,
                        caseNo: _caseNoController.text,
                        description: _descController.text,
                        status: 'Filed',
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
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final taxpayerId = auth.currentUser?.taxpayerId ?? 0;

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
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
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

            // Appeals List
            portalProv.appeals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No ongoing tax appeals filed.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: portalProv.appeals.length,
                    itemBuilder: (context, index) {
                      final appeal = portalProv.appeals[index];
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
                        elevation: 0,
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
                                    // Case number and status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          appeal.appealNo ?? appeal.caseNo,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
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
                                              _buildMetaItem(Icons.calendar_today_outlined, 'Filed: ${appeal.filedAt ?? "—"}', isDark),
                                              _buildMetaItem(Icons.gavel_outlined, 'Hearing: ${appeal.hearingDate ?? "Pending Schedule"}', isDark),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark.withOpacity(0.8) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
