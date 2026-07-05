import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';

class AitWizardScreen extends StatefulWidget {
  final int taxpayerId;
  final String taxpayerName;
  final String tinNumber;

  const AitWizardScreen({
    Key? key,
    required this.taxpayerId,
    required this.taxpayerName,
    required this.tinNumber,
  }) : super(key: key);

  @override
  State<AitWizardScreen> createState() => _AitWizardScreenState();
}

class _AitWizardScreenState extends State<AitWizardScreen> {
  int _currentStep = 1;
  final _formKeyStep2 = GlobalKey<FormState>();

  String _selectedSource = 'IMPORT'; // IMPORT, SUPPLIER, SALARY, CONTRACTOR, RENT
  final _recordIdController = TextEditingController();
  final _hsCodeController = TextEditingController();
  final _deductorNameController = TextEditingController();
  final _deductorTinController = TextEditingController();
  final _taxableValueController = TextEditingController();
  final _aitRateController = TextEditingController(text: '5');
  final _challanNoController = TextEditingController();
  final _bankNameController = TextEditingController(text: 'Sonali Bank');

  double _taxableValue = 0.0;
  double _aitRate = 5.0;
  double _calculatedAmount = 0.0;

  bool _isSaving = false;

  @override
  void dispose() {
    _recordIdController.dispose();
    _hsCodeController.dispose();
    _deductorNameController.dispose();
    _deductorTinController.dispose();
    _taxableValueController.dispose();
    _aitRateController.dispose();
    _challanNoController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final val = double.tryParse(_taxableValueController.text) ?? 0.0;
    final rate = double.tryParse(_aitRateController.text) ?? 0.0;
    setState(() {
      _taxableValue = val;
      _aitRate = rate;
      _calculatedAmount = (val * rate) / 100.0;
    });
  }

  String _getSourceLabel(String type) {
    switch (type) {
      case 'IMPORT':
        return 'Import Duty';
      case 'SUPPLIER':
        return 'Supplier Payment';
      case 'SALARY':
        return 'Salary Deduction';
      case 'CONTRACTOR':
        return 'Contractor Payment';
      case 'RENT':
        return 'Rent Payment';
      default:
        return type;
    }
  }

  InputDecoration _inputDecoration(String label, String hint, bool isDark, {bool isLocked = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: isLocked
          ? (isDark ? Colors.grey.shade800 : Colors.grey.shade100)
          : (isDark ? AppColors.surfaceDark : Colors.white),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Advance Income Tax (AIT) — 2025-26', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Rail
                  _buildStepRail(),
                  const SizedBox(height: 24),

                  // Steps Content
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                  if (_currentStep == 3) _buildStep3(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepItem(1, 'Taxpayer Info', _currentStep >= 1),
          _buildStepLine(_currentStep > 1),
          _buildStepItem(2, 'AIT Details', _currentStep >= 2),
          _buildStepLine(_currentStep > 2),
          _buildStepItem(3, 'Review & Submit', _currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isActive) {
    final isDone = _currentStep > step;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF166534)
                : (isActive ? AppColors.primary : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '$step',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.textPrimary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 2,
        color: isDone ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  // ── Step 1: Taxpayer Info ──
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCardSection(
          title: 'Taxpayer Profile',
          subtitle: 'Verified from registry',
          icon: Icons.person_outline,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.taxpayerName,
                    decoration: _inputDecoration('Full Name / Company', '', false, isLocked: true),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: widget.tinNumber,
                    decoration: _inputDecoration('TIN Number', '', false, isLocked: true),
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: 'Individual',
              decoration: _inputDecoration('Taxpayer Type', '', false, isLocked: true),
              readOnly: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 200,
              child: CustomButton(
                text: 'Next: AIT Details',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: AIT Details ──
  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AIT Source Type Picker Card
          _buildCardSection(
            title: 'AIT Source Type',
            subtitle: 'Select the source of this advance income tax',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSourceCardBtn('IMPORT', 'Import Duty', Icons.local_shipping_outlined),
                  _buildSourceCardBtn('SUPPLIER', 'Supplier Payment', Icons.business_outlined),
                  _buildSourceCardBtn('SALARY', 'Salary Deduction', Icons.badge_outlined),
                  _buildSourceCardBtn('CONTRACTOR', 'Contractor Payment', Icons.construction_outlined),
                  _buildSourceCardBtn('RENT', 'Rent Payment', Icons.home_outlined),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic details card
          if (_selectedSource == 'IMPORT')
            _buildCardSection(
              title: 'Import Details',
              subtitle: 'Link import duty record and HS code',
              icon: Icons.inventory_2_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _recordIdController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Import Duty Record ID *', 'e.g. 1042', false),
                        validator: (v) => _selectedSource == 'IMPORT' && (v == null || v.isEmpty) ? 'Record ID required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hsCodeController,
                        decoration: _inputDecoration('HS Code', 'e.g. 8471.30', false),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            _buildCardSection(
              title: 'Deductor Information',
              subtitle: 'Who deducted this tax at source?',
              icon: Icons.domain_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deductorNameController,
                        decoration: _inputDecoration('Deductor Name *', 'Company or individual name', false),
                        validator: (v) => _selectedSource != 'IMPORT' && (v == null || v.isEmpty) ? 'Deductor name required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _deductorTinController,
                        decoration: _inputDecoration('Deductor TIN', 'Optional', false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Financial details card
          _buildCardSection(
            title: 'Financial Details',
            subtitle: 'AIT is calculated automatically from taxable value and rate',
            icon: Icons.calculate_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxableValueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Taxable Value (৳) *', '0.00', false),
                      onChanged: (_) => _recalculate(),
                      validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0
                          ? 'Enter positive value'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _aitRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('AIT Rate (%) *', 'e.g. 5', false),
                      onChanged: (_) => _recalculate(),
                      validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0
                          ? 'Enter positive rate'
                          : null,
                    ),
                  ),
                ],
              ),
              if (_calculatedAmount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _buildCalcRow('Taxable Value', NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(_taxableValue)),
                      const SizedBox(height: 6),
                      _buildCalcRow('AIT Rate', '${_aitRate.toStringAsFixed(2)}%'),
                      const Divider(height: 16),
                      _buildCalcRow(
                        'AIT Amount',
                        NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(_calculatedAmount),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Challan Information
          _buildCardSection(
            title: 'Treasury Challan Details',
            subtitle: 'Enter treasury transaction matching information',
            icon: Icons.receipt_long_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _challanNoController,
                      decoration: _inputDecoration('Challan Number *', 'e.g. CH-89754B', false),
                      validator: (v) => v == null || v.isEmpty ? 'Challan required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bankNameController,
                      decoration: _inputDecoration('Bank Name', 'e.g. Sonali Bank', false),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Footer Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              SizedBox(
                width: 180,
                child: CustomButton(
                  text: 'Next: Review',
                  onPressed: () {
                    if (_formKeyStep2.currentState!.validate()) {
                      setState(() => _currentStep = 3);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceCardBtn(String type, String label, IconData icon) {
    final isSelected = _selectedSource == type;
    return InkWell(
      onTap: () => setState(() => _selectedSource = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 138,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Review & Submit ──
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCardSection(
          title: 'Review & Submit',
          subtitle: 'Confirm all details before submission',
          icon: Icons.assignment_turned_in_outlined,
          children: [
            // Taxpayer summary
            _buildReviewHeader('Taxpayer'),
            const SizedBox(height: 8),
            _buildReviewRow('Name', widget.taxpayerName),
            _buildReviewRow('TIN', widget.tinNumber, isMono: true),
            _buildReviewRow('Fiscal Year', '2025-2026'),
            const SizedBox(height: 20),

            // AIT details summary
            _buildReviewHeader('AIT Details'),
            const SizedBox(height: 8),
            _buildReviewRow('Source Type', _getSourceLabel(_selectedSource)),
            if (_selectedSource == 'IMPORT') ...[
              _buildReviewRow('Import Record ID', _recordIdController.text, isMono: true),
              if (_hsCodeController.text.isNotEmpty)
                _buildReviewRow('HS Code', _hsCodeController.text, isMono: true),
            ] else ...[
              _buildReviewRow('Deductor Name', _deductorNameController.text),
              if (_deductorTinController.text.isNotEmpty)
                _buildReviewRow('Deductor TIN', _deductorTinController.text, isMono: true),
            ],
            _buildReviewRow('Taxable Value', NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(_taxableValue)),
            _buildReviewRow('AIT Rate', '${_aitRate.toStringAsFixed(1)}%'),
            _buildReviewRow('Challan Number', _challanNoController.text, isMono: true),
            if (_bankNameController.text.isNotEmpty)
              _buildReviewRow('Bank Name', _bankNameController.text),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AIT Claim Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 2).format(_calculatedAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A3F8F)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Documents upload zone
            _buildReviewHeader('Supporting Documents'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                  const SizedBox(height: 8),
                  const Text('treasury_challan_receipt.pdf', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('(142 KB)', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Footer Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => setState(() => _currentStep = 2),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            SizedBox(
              width: 220,
              child: CustomButton(
                text: _isSaving ? 'Submitting...' : 'Submit AIT Record',
                onPressed: _isSaving ? null : _submitAitClaim,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submitAitClaim() async {
    setState(() => _isSaving = true);
    final ait = AitRecord(
      id: 0,
      taxpayerId: widget.taxpayerId,
      amount: _calculatedAmount,
      source: _selectedSource,
      challanNo: _challanNoController.text,
      status: 'Pending',
      date: DateTime.now().toIso8601String(),
    );

    final success = await Provider.of<PortalProvider>(context, listen: false).createAit(ait);
    setState(() => _isSaving = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AIT claim submitted successfully for challan verification.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _buildReviewHeader(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String val, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 12 : 11.5,
            color: isTotal ? Colors.black87 : Colors.grey.shade700,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: isTotal ? 13 : 11.5,
            color: isTotal ? const Color(0xFF1A3F8F) : Colors.black87,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
