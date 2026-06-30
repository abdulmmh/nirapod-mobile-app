import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

class AitScreen extends StatefulWidget {
  const AitScreen({Key? key}) : super(key: key);

  @override
  State<AitScreen> createState() => _AitScreenState();
}

class _AitScreenState extends State<AitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _challanController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _challanController.dispose();
    super.dispose();
  }

  void _openAddAitSheet(BuildContext context, int taxpayerId) {
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
                        'Claim Advance Tax (AIT)',
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
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'AIT Amount (৳)',
                      hintText: 'Enter tax amount deducted',
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      labelText: 'Source of Deduction',
                      hintText: 'e.g. Bank interest, vehicle registration, imports',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Source is required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _challanController,
                    decoration: const InputDecoration(
                      labelText: 'Challan / Ref Number',
                      hintText: 'Enter NBR treasury challan code',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Challan is required' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Verify & Claim',
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      final ait = AitRecord(
                        id: 0,
                        taxpayerId: taxpayerId,
                        amount: double.parse(_amountController.text),
                        source: _sourceController.text,
                        challanNo: _challanController.text,
                        status: 'Pending',
                      );

                      final success = await Provider.of<PortalProvider>(context, listen: false).createAit(ait);
                      if (success && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AIT claim submitted for challan verification.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _amountController.clear();
                        _sourceController.clear();
                        _challanController.clear();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Advance Income Tax')),
      body: portalProv.aits.isEmpty
          ? const Center(child: Text('No AIT records found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.aits.length,
              itemBuilder: (context, index) {
                final ait = portalProv.aits[index];
                Color statusColor = ait.status.toLowerCase() == 'verified' 
                    ? AppColors.success 
                    : AppColors.warning;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ait.source,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(ait.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Challan: ${ait.challanNo}', style: const TextStyle(fontFamily: 'monospace')),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: ${ait.date ?? "N/A"}'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ait.status,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddAitSheet(context, taxpayerId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_moderator),
        label: const Text('Claim AIT'),
      ),
    );
  }
}
