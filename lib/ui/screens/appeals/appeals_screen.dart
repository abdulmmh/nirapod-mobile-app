import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

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
    final portalProv = Provider.of<PortalProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final taxpayerId = auth.currentUser?.taxpayerId ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('My Appeals & Hearings')),
      body: portalProv.appeals.isEmpty
          ? const Center(child: Text('No ongoing tax appeals filed.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.appeals.length,
              itemBuilder: (context, index) {
                final appeal = portalProv.appeals[index];
                Color statusColor;
                switch (appeal.status.toLowerCase()) {
                  case 'decided':
                    statusColor = AppColors.success;
                    break;
                  case 'filed':
                    statusColor = AppColors.info;
                    break;
                  case 'hearing scheduled':
                    statusColor = AppColors.warning;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Case No: ${appeal.caseNo}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                appeal.status,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (appeal.description != null) ...[
                          Text(
                            'Statement / Grounds:',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appeal.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Hearing Date: ${appeal.hearingDate ?? "Pending Schedule"}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFileAppealSheet(context, taxpayerId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.gavel_outlined),
        label: const Text('File Appeal'),
      ),
    );
  }
}
