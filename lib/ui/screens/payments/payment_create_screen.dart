import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/portal_shell.dart';

class PaymentCreateScreen extends StatefulWidget {
  const PaymentCreateScreen({Key? key}) : super(key: key);

  @override
  State<PaymentCreateScreen> createState() => _PaymentCreateScreenState();
}

class _PaymentCreateScreenState extends State<PaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // State fields
  bool _isAutoFilled = false;
  String? _autoFilledName;
  String? _autoFilledTin;
  int? _taxpayerId;

  OutstandingItem? _selectedOutstandingItem;

  // Controllers
  final TextEditingController _tinController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _returnNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();
  final TextEditingController _chequeNoController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _paymentType;
  String? _paymentMethod;
  String? _bankName;

  String? _paymentDate = DateTime.now().toIso8601String().substring(0, 10);
  String? _valueDate = DateTime.now().toIso8601String().substring(0, 10);

  final List<String> _paymentTypes = ['VAT', 'Income Tax', 'Penalty', 'Demand Notice', 'Other'];
  final List<String> _paymentMethods = ['Bank Transfer', 'Online Banking', 'Cheque', 'Cash', 'Mobile Banking'];
  final List<String> _banks = [
    'Sonali Bank', 'Agrani Bank', 'Janata Bank', 'Rupali Bank',
    'Dutch-Bangla Bank', 'BRAC Bank', 'Islami Bank', 'Prime Bank',
    'Eastern Bank', 'Mercantile Bank', 'bKash', 'Nagad', 'Rocket', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Auto populate logged in taxpayer details and load outstanding dues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taxpayer = Provider.of<TaxpayerProvider>(context, listen: false).taxpayer;
      if (taxpayer != null) {
        setState(() {
          _isAutoFilled = true;
          _taxpayerId = taxpayer.id;
          _autoFilledName = taxpayer.fullName ?? taxpayer.companyName ?? 'Abdul Karim';
          _autoFilledTin = taxpayer.tin ?? '102345678912';

          _tinController.text = _autoFilledTin!;
          _nameController.text = _autoFilledName!;
        });

        // Load outstanding items
        Provider.of<PortalProvider>(context, listen: false).loadOutstandingItems(taxpayer.id);
      }

      // Read navigation arguments if any (e.g. from Demand Notice screen)
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          if (args.containsKey('amount')) {
            _amountController.text = args['amount'].toString();
          }
          if (args.containsKey('paymentType')) {
            _paymentType = args['paymentType'];
          }
          if (args.containsKey('returnNo')) {
            _returnNoController.text = args['returnNo'];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tinController.dispose();
    _nameController.dispose();
    _returnNoController.dispose();
    _amountController.dispose();
    _referenceNoController.dispose();
    _chequeNoController.dispose();
    _branchController.dispose();
    _accountNoController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, int dateType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        final formatted = picked.toIso8601String().substring(0, 10);
        if (dateType == 1) {
          _paymentDate = formatted;
        } else {
          _valueDate = formatted;
        }
      });
    }
  }

  void _selectOutstandingItem(OutstandingItem item) {
    setState(() {
      _selectedOutstandingItem = item;
      _paymentType = item.type;
      _returnNoController.text = item.returnNo;
      _amountController.text = item.outstanding.toStringAsFixed(0);
    });
  }

  void _clearOutstandingSelection() {
    setState(() {
      _selectedOutstandingItem = null;
      _paymentType = null;
      _returnNoController.text = '';
      _amountController.text = '';
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'VAT':
        return Colors.teal;
      case 'Income Tax':
        return Colors.blue.shade700;
      case 'Penalty':
        return Colors.orange.shade700;
      case 'Demand Notice':
        return Colors.purple;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatAmount(double v) {
    if (v >= 100000) return '৳${(v / 100000).toStringAsFixed(2)}L';
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳', decimalDigits: 0).format(v);
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment date is required')),
      );
      return;
    }

    final provider = Provider.of<PortalProvider>(context, listen: false);

    // Format a transaction ID if reference number is empty
    final ref = _referenceNoController.text.trim();
    final txnId = ref.isNotEmpty ? ref : 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final payment = Payment(
      id: 0,
      challanNo: txnId,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      status: 'Success',
      date: _paymentDate,
      paymentType: _paymentType,
      tinNumber: _tinController.text.trim(),
      taxpayerName: _nameController.text.trim(),
      taxpayerId: _taxpayerId,
      paymentMethod: _paymentMethod,
      bankName: _bankName,
      bankBranch: _branchController.text.trim(),
      accountNo: _accountNoController.text.trim(),
      chequeNo: _chequeNoController.text.trim(),
      paymentDate: _paymentDate,
      valueDate: _valueDate,
      referenceNo: ref,
      returnNo: _returnNoController.text.trim(),
      remarks: _remarksController.text.trim(),
    );

    final success = await provider.makePayment(payment);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedOutstandingItem = null;
      _paymentType = null;
      _paymentMethod = null;
      _bankName = null;

      _returnNoController.clear();
      _amountController.clear();
      _referenceNoController.clear();
      _chequeNoController.clear();
      _branchController.clear();
      _accountNoController.clear();
      _remarksController.clear();

      _paymentDate = DateTime.now().toIso8601String().substring(0, 10);
      _valueDate = DateTime.now().toIso8601String().substring(0, 10);

      if (_isAutoFilled) {
        _tinController.text = _autoFilledTin!;
        _nameController.text = _autoFilledName!;
      } else {
        _tinController.clear();
        _nameController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portalProv = Provider.of<PortalProvider>(context);

    final showChequeField = _paymentMethod == 'Cheque';
    final isObligationLocked = _selectedOutstandingItem != null;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Payments', 'Record Payment'],
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Payment',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record a new tax payment transaction.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to List'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade800,
                    side: BorderSide(color: Colors.teal.shade200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section 0: Profile Autofilled details
            if (_isAutoFilled) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.person_outline, color: Colors.green.shade800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _autoFilledName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TIN: ${_autoFilledTin ?? ""}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Auto-filled', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 1: Outstanding Dues
            if (_isAutoFilled) ...[
              _buildFormSection(
                title: 'Outstanding Dues',
                subtitle: 'Select outstanding tax due item to auto-fill details',
                icon: Icons.error_outline,
                isDark: isDark,
                children: [
                  if (portalProv.isLoadingOutstanding)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (portalProv.outstandingItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'No outstanding dues found — all VAT, Income Tax and penalties are settled.',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isObligationLocked)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.teal.shade700, size: 20),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(_selectedOutstandingItem!.type),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedOutstandingItem!.type,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedOutstandingItem!.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedOutstandingItem!.returnNo,
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatAmount(_selectedOutstandingItem!.outstanding),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _clearOutstandingSelection,
                            child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: portalProv.outstandingItems.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: item.overdue ? Colors.red.shade200 : Colors.grey.shade200),
                          ),
                          color: item.overdue ? Colors.red.shade50 : Colors.white,
                          child: InkWell(
                            onTap: () => _selectOutstandingItem(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(item.type),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.label,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              item.returnNo,
                                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace'),
                                            ),
                                            if (item.dueDate != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '• Due: ${item.dueDate}',
                                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                              ),
                                            ],
                                            if (item.overdue) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('Overdue', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatAmount(item.outstanding),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: item.overdue ? Colors.red.shade900 : Colors.black87),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Select',
                                        style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Section 2: Taxpayer Information
            _buildFormSection(
              title: 'Taxpayer Information',
              subtitle: 'TIN, name and payment category details',
              icon: Icons.assignment_ind_outlined,
              isDark: isDark,
              children: [
                _buildLabel('TIN Number *'),
                TextFormField(
                  controller: _tinController,
                  validator: (val) => val == null || val.isEmpty ? 'TIN number is required' : null,
                  readOnly: _isAutoFilled,
                  decoration: _inputDecoration('e.g. TIN-102345678912', isDark, isLocked: _isAutoFilled),
                ),
                const SizedBox(height: 12),
                _buildLabel('Taxpayer Name *'),
                TextFormField(
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? 'Taxpayer name is required' : null,
                  readOnly: _isAutoFilled,
                  decoration: _inputDecoration('Enter taxpayer name', isDark, isLocked: _isAutoFilled),
                ),
                const SizedBox(height: 12),
                _buildResponsiveRow(
                  context,
                  [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Type *'),
                          if (isObligationLocked)
                            TextFormField(
                              controller: TextEditingController(text: _paymentType),
                              readOnly: true,
                              decoration: _inputDecoration('', isDark, isLocked: true),
                            )
                          else
                            _buildDropdownField(
                              _paymentType,
                              _paymentTypes,
                              (val) => setState(() => _paymentType = val),
                              isDark,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Return / Reference No.'),
                          TextFormField(
                            controller: _returnNoController,
                            readOnly: isObligationLocked,
                            decoration: _inputDecoration('e.g. ITR-2025-26-XXXX', isDark, isLocked: isObligationLocked),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3: Payment Details
            _buildFormSection(
              title: 'Payment Details',
              subtitle: 'Amount, method and date details',
              icon: Icons.payment_outlined,
              isDark: isDark,
              children: [
                _buildResponsiveRow(
                  context,
                  [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Amount (৳) *'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Amount is required';
                              final double? amt = double.tryParse(val);
                              if (amt == null || amt <= 0) return 'Enter a valid amount';
                              return null;
                            },
                            decoration: _inputDecoration('0', isDark),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Method *'),
                          _buildDropdownField(
                            _paymentMethod,
                            _paymentMethods,
                            (val) => setState(() => _paymentMethod = val),
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLabel('Reference / Challan No.'),
                TextFormField(
                  controller: _referenceNoController,
                  decoration: _inputDecoration('e.g. Bank slip or Challan reference', isDark),
                ),
                if (showChequeField) ...[
                  const SizedBox(height: 12),
                  _buildLabel('Cheque No. *'),
                  TextFormField(
                    controller: _chequeNoController,
                    validator: (val) => showChequeField && (val == null || val.isEmpty) ? 'Cheque number is required' : null,
                    decoration: _inputDecoration('e.g. CHQ-889921', isDark),
                  ),
                ],
                const SizedBox(height: 12),
                _buildResponsiveRow(
                  context,
                  [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Date *'),
                          _buildDatePickerField(_paymentDate, () => _selectDate(context, 1), isDark),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Value Date'),
                          _buildDatePickerField(_valueDate, () => _selectDate(context, 2), isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 4: Bank Details
            _buildFormSection(
              title: 'Bank Details',
              subtitle: 'Bank and account details where taxes are deposited',
              icon: Icons.account_balance_outlined,
              isDark: isDark,
              children: [
                _buildLabel('Bank Name *'),
                _buildDropdownField(
                  _bankName,
                  _banks,
                  (val) => setState(() => _bankName = val),
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildResponsiveRow(
                  context,
                  [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Branch'),
                          TextFormField(
                            controller: _branchController,
                            decoration: _inputDecoration('Enter branch name', isDark),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Account No.'),
                          TextFormField(
                            controller: _accountNoController,
                            decoration: _inputDecoration('Enter account number', isDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5: Remarks
            _buildFormSection(
              title: 'Remarks',
              subtitle: 'Any remarks or notes to record',
              icon: Icons.chat_bubble_outline,
              isDark: isDark,
              children: [
                _buildLabel('Remarks / Notes'),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: _inputDecoration('Optional remarks...', isDark),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons: Record Payment, Reset, Cancel
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitForm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.amber, width: 1.5),
                foregroundColor: Colors.amber.shade900,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _resetForm,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark, {bool isLocked = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: isLocked ? Colors.grey.shade100 : Colors.white,
      prefixIcon: isLocked ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildDropdownField(
    String? selected,
    List<String> items,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: const Text('Select Option', style: TextStyle(fontSize: 13, color: Colors.grey)),
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items.map((i) => DropdownMenuItem<String>(value: i, child: Text(i, style: const TextStyle(color: Colors.black87)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String? dateValue, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateValue ?? 'yyyy-mm-dd',
              style: TextStyle(fontSize: 13, color: dateValue == null ? Colors.grey : Colors.black87),
            ),
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(BuildContext context, List<Widget> children, {double spacing = 10}) {
    final width = MediaQuery.of(context).size.width;
    final cleanChildren = children.where((c) => c is! SizedBox).toList();
    if (width < 600) {
      final List<Widget> columnChildren = [];
      for (int i = 0; i < cleanChildren.length; i++) {
        var child = cleanChildren[i];
        if (child is Expanded) {
          child = child.child;
        }
        columnChildren.add(child);
        if (i < cleanChildren.length - 1) {
          columnChildren.add(SizedBox(height: spacing));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren,
      );
    } else {
      final List<Widget> rowChildren = [];
      for (int i = 0; i < cleanChildren.length; i++) {
        rowChildren.add(cleanChildren[i]);
        if (i < cleanChildren.length - 1) {
          rowChildren.add(SizedBox(width: spacing));
        }
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      );
    }
  }

  Widget _buildFormSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 8),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
