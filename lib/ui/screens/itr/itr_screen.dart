import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

class ItrScreen extends StatefulWidget {
  const ItrScreen({Key? key}) : super(key: key);

  @override
  State<ItrScreen> createState() => _ItrScreenState();
}

class _ItrScreenState extends State<ItrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController(text: '2025-2026');
  final _grossTaxController = TextEditingController();
  final _rebateController = TextEditingController();
  final _advancePaidController = TextEditingController();
  final _taxPaidController = TextEditingController();

  @override
  void dispose() {
    _yearController.dispose();
    _grossTaxController.dispose();
    _rebateController.dispose();
    _advancePaidController.dispose();
    _taxPaidController.dispose();
    super.dispose();
  }

  void _openFileReturnSheet(BuildContext context, int taxpayerId) {
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
                        'File Income Tax Return',
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
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Assessment Year'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _grossTaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gross Tax (৳)',
                      hintText: 'Enter total tax liability',
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid number' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _rebateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tax Rebate / Discount (৳)',
                      hintText: 'Enter total investment rebates',
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid number' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _advancePaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Advance Tax Paid / AIT (৳)',
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid number' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _taxPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Remaining Tax Paid with Return (৳)',
                    ),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid number' : null,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Submit Tax Return',
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      final gross = double.parse(_grossTaxController.text);
                      final rebate = double.parse(_rebateController.text);
                      final advance = double.parse(_advancePaidController.text);
                      final paid = double.parse(_taxPaidController.text);

                      final itr = ItrRecord(
                        id: 0,
                        taxpayerId: taxpayerId,
                        assessmentYear: _yearController.text,
                        grossTax: gross,
                        rebate: rebate,
                        netTaxPayable: gross - rebate,
                        advanceTaxPaid: advance,
                        withholdingTax: 0,
                        taxPaid: paid,
                        status: 'Submitted',
                      );

                      final success = await Provider.of<PortalProvider>(context, listen: false).createItr(itr);
                      if (success && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tax return filed successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _grossTaxController.clear();
                        _rebateController.clear();
                        _advancePaidController.clear();
                        _taxPaidController.clear();
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
      appBar: AppBar(
        title: const Text('Income Tax Returns'),
      ),
      body: portalProv.itrs.isEmpty
          ? const Center(child: Text('No return filings found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.itrs.length,
              itemBuilder: (context, index) {
                final itr = portalProv.itrs[index];
                return ItrCard(itr: itr, isDark: isDark, theme: theme);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFileReturnSheet(context, taxpayerId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('File Return'),
      ),
    );
  }
}

class ItrCard extends StatelessWidget {
  final ItrRecord itr;
  final bool isDark;
  final ThemeData theme;

  const ItrCard({
    Key? key,
    required this.itr,
    required this.isDark,
    required this.theme,
  }) : super(key: key);

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(double? amt) {
    if (amt == null) return '৳ 0';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (itr.status.toLowerCase()) {
      case 'accepted':
        statusColor = AppColors.success;
        break;
      case 'submitted':
        statusColor = AppColors.info;
        break;
      case 'under audit':
        statusColor = AppColors.warning;
        break;
      default:
        statusColor = Colors.grey;
    }

    final double netTax = itr.netTaxPayable ?? ((itr.grossTax ?? 0) - (itr.rebate ?? 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Assessment Year: ${itr.assessmentYear}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  itr.status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filed: ${_formatDate(itr.submissionDate)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildItrDetailRow('Gross Tax Amount', _formatAmount(itr.grossTax), theme),
                _buildItrDetailRow('Investment Rebate', _formatAmount(itr.rebate), theme),
                const Divider(),
                _buildItrDetailRow('Net Tax Payable', _formatAmount(netTax), theme, isBold: true),
                _buildItrDetailRow('Advance Tax / AIT Paid', _formatAmount(itr.advanceTaxPaid), theme),
                _buildItrDetailRow('Tax Paid with Return', _formatAmount(itr.taxPaid), theme),
                const Divider(),
                _buildItrDetailRow(
                  'Outstanding Dues',
                  _formatAmount(MathMax(0.0, netTax - ((itr.advanceTaxPaid ?? 0) + (itr.taxPaid ?? 0)))),
                  theme,
                  accentColor: netTax - ((itr.advanceTaxPaid ?? 0) + (itr.taxPaid ?? 0)) > 0
                      ? AppColors.error
                      : AppColors.success,
                  isBold: true,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  double MathMax(double a, double b) => a > b ? a : b;

  Widget _buildItrDetailRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
