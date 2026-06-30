import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _amountController = TextEditingController();
  final _challanController = TextEditingController();
  String _paymentType = 'Income Tax Return Pay';

  @override
  void dispose() {
    _amountController.dispose();
    _challanController.dispose();
    super.dispose();
  }

  void _openPayTaxSheet(BuildContext context) {
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Simulate Tax Payment',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(labelText: 'Payment Category'),
                      items: const [
                        DropdownMenuItem(value: 'Income Tax Return Pay', child: Text('Income Tax Return Pay')),
                        DropdownMenuItem(value: 'Advance Income Tax', child: Text('Advance Income Tax')),
                        DropdownMenuItem(value: 'VAT Payment', child: Text('VAT Payment')),
                        DropdownMenuItem(value: 'Audit Demand Fine', child: Text('Audit Demand Fine')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _paymentType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment Amount (৳)',
                        hintText: 'Enter amount to deposit',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _challanController,
                      decoration: const InputDecoration(
                        labelText: 'Treasury Challan / TXN No',
                        hintText: 'e.g. TXN98273619',
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Confirm & Deposit',
                      onPressed: () async {
                        if (_amountController.text.isEmpty || _challanController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields')),
                          );
                          return;
                        }

                        final payment = Payment(
                          id: 0,
                          challanNo: _challanController.text,
                          amount: double.parse(_amountController.text),
                          status: 'Success',
                          paymentType: _paymentType,
                        );

                        final success = await Provider.of<PortalProvider>(context, listen: false).makePayment(payment);
                        if (success && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment registered successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _amountController.clear();
                          _challanController.clear();
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portalProv = Provider.of<PortalProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments & Deposits')),
      body: portalProv.payments.isEmpty
          ? const Center(child: Text('No payment logs found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: portalProv.payments.length,
              itemBuilder: (context, index) {
                final payment = portalProv.payments[index];
                final isSuccess = payment.status.toLowerCase() == 'success';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          payment.paymentType ?? 'Tax Payment',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(payment.amount),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Challan/TXN: ${payment.challanNo}', style: const TextStyle(fontFamily: 'monospace')),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: ${payment.date ?? "N/A"}'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isSuccess ? AppColors.success : AppColors.warning).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  payment.status,
                                  style: TextStyle(
                                    color: isSuccess ? AppColors.success : AppColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
        onPressed: () => _openPayTaxSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.payment_outlined),
        label: const Text('Pay Taxes'),
      ),
    );
  }
}
