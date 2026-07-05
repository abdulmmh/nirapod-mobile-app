import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/portal_records.dart';
import '../../widgets/custom_button.dart';
import 'itr_details_screen.dart';

class ItrWizardScreen extends StatefulWidget {
  final int taxpayerId;
  final String taxpayerName;
  final String tinNumber;

  const ItrWizardScreen({
    Key? key,
    required this.taxpayerId,
    required this.taxpayerName,
    required this.tinNumber,
  }) : super(key: key);

  @override
  State<ItrWizardScreen> createState() => _ItrWizardScreenState();
}

class _ItrWizardScreenState extends State<ItrWizardScreen> {
  int _currentStep = 1;
  bool _isAutoFilled = true;
  bool _isLoading = false;

  // ── STEP 1: Profile ──
  final List<String> _assessmentYears = ['2025-2026', '2024-2025', '2023-2024'];
  final List<String> _incomeYears = ['2024-2025', '2023-2024', '2022-2023'];
  final List<String> _itrCategories = ['Individual', 'Company', 'Partnership', 'NGO'];
  final List<String> _companySubTypes = ['Private Limited', 'Publicly Traded Listed', 'Bank', 'NBFI', 'NGO'];
  final List<String> _returnPeriods = ['Annual', 'Quarterly'];

  late String _selectedAssessmentYear;
  late String _selectedIncomeYear;
  late String _selectedCategory;
  String _selectedCompanySubType = '';
  late String _selectedPeriod;
  final _tinController = TextEditingController();
  final _nameController = TextEditingController();
  final _submissionDateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _dueDateController = TextEditingController(text: '2025-11-30');

  // ── STEP 2: Income Sources ──
  final _salBasicController = TextEditingController(text: '0');
  final _salHraController = TextEditingController(text: '0');
  final _salBonusController = TextEditingController(text: '0');
  final _salTdsController = TextEditingController(text: '0');
  final _bizProfitController = TextEditingController(text: '0');
  final _bankInterestController = TextEditingController(text: '0');
  final _bankAitController = TextEditingController(text: '0');
  final _rentalIncomeController = TextEditingController(text: '0');
  final _capitalGainsController = TextEditingController(text: '0');

  // Computed values step 2
  double _salGross = 0.0;
  double _salNet = 0.0;
  double _bankNet = 0.0;
  double _totalGrossIncome = 0.0;
  double _totalTds = 0.0;

  // ── STEP 3: Deductions & Rebate ──
  final _lifeInsController = TextEditingController(text: '0');
  final _pfController = TextEditingController(text: '0');
  final _dpsController = TextEditingController(text: '0');
  final _bondsController = TextEditingController(text: '0');
  final _donationController = TextEditingController(text: '0');
  final _sharesController = TextEditingController(text: '0');

  // Computed step 3
  double _totalDeductions = 0.0;
  double _taxRebate = 0.0;

  // ── STEP 4: Tax Liability ──
  double _hraExemption = 0.0;
  double _taxableIncome = 0.0;
  double _grossTax = 0.0;
  double _netTaxPayable = 0.0;
  double _balanceDue = 0.0;
  double _refundable = 0.0;

  // ── STEP 5: IT-10B Assets & Liabilities ──
  final _landController = TextEditingController(text: '0');
  final _vehicleController = TextEditingController(text: '0');
  final _capitalController = TextEditingController(text: '0');
  final _bankBalancesController = TextEditingController(text: '0');
  final _cashController = TextEditingController(text: '0');
  final _goldController = TextEditingController(text: '0');
  final _otherAssetsController = TextEditingController(text: '0');
  final _bankLoanController = TextEditingController(text: '0');
  final _bizLoanController = TextEditingController(text: '0');
  final _otherLiabController = TextEditingController(text: '0');

  // Computed step 5
  double _totalAssets = 0.0;
  double _totalLiabilities = 0.0;
  double _netWorth = 0.0;

  // ── STEP 6: Review & Submit ──
  bool _declarationAccepted = false;
  final _remarksController = TextEditingController();
  String _paymentMethod = 'challan'; // challan, bkash, nagad, rocket
  final _challanBankController = TextEditingController(text: 'Sonali Bank');
  final _challanNoController = TextEditingController();
  final _challanDateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _mfsTxnController = TextEditingController();

  // Success response placeholder
  ItrRecord? _successRecord;

  @override
  void initState() {
    super.initState();
    // Initialize profile fields
    _selectedAssessmentYear = _assessmentYears[0];
    _selectedIncomeYear = _incomeYears[0];
    _selectedCategory = _itrCategories[0];
    _selectedPeriod = _returnPeriods[0];
    _tinController.text = widget.tinNumber;
    _nameController.text = widget.taxpayerName;

    // Listeners for income calculations
    _salBasicController.addListener(_calculateIncome);
    _salHraController.addListener(_calculateIncome);
    _salBonusController.addListener(_calculateIncome);
    _salTdsController.addListener(_calculateIncome);
    _bizProfitController.addListener(_calculateIncome);
    _bankInterestController.addListener(_calculateIncome);
    _bankAitController.addListener(_calculateIncome);
    _rentalIncomeController.addListener(_calculateIncome);
    _capitalGainsController.addListener(_calculateIncome);

    // Listeners for deductions
    _lifeInsController.addListener(_calculateDeductions);
    _pfController.addListener(_calculateDeductions);
    _dpsController.addListener(_calculateDeductions);
    _bondsController.addListener(_calculateDeductions);
    _donationController.addListener(_calculateDeductions);
    _sharesController.addListener(_calculateDeductions);

    // Listeners for IT-10B net worth
    _landController.addListener(_calculateNetWorth);
    _vehicleController.addListener(_calculateNetWorth);
    _capitalController.addListener(_calculateNetWorth);
    _bankBalancesController.addListener(_calculateNetWorth);
    _cashController.addListener(_calculateNetWorth);
    _goldController.addListener(_calculateNetWorth);
    _otherAssetsController.addListener(_calculateNetWorth);
    _bankLoanController.addListener(_calculateNetWorth);
    _bizLoanController.addListener(_calculateNetWorth);
    _otherLiabController.addListener(_calculateNetWorth);
  }

  @override
  void dispose() {
    _tinController.dispose();
    _nameController.dispose();
    _submissionDateController.dispose();
    _dueDateController.dispose();
    _salBasicController.dispose();
    _salHraController.dispose();
    _salBonusController.dispose();
    _salTdsController.dispose();
    _bizProfitController.dispose();
    _bankInterestController.dispose();
    _bankAitController.dispose();
    _rentalIncomeController.dispose();
    _capitalGainsController.dispose();
    _lifeInsController.dispose();
    _pfController.dispose();
    _dpsController.dispose();
    _bondsController.dispose();
    _donationController.dispose();
    _sharesController.dispose();
    _landController.dispose();
    _vehicleController.dispose();
    _capitalController.dispose();
    _bankBalancesController.dispose();
    _cashController.dispose();
    _goldController.dispose();
    _otherAssetsController.dispose();
    _bankLoanController.dispose();
    _bizLoanController.dispose();
    _otherLiabController.dispose();
    _remarksController.dispose();
    _challanBankController.dispose();
    _challanNoController.dispose();
    _challanDateController.dispose();
    _mfsTxnController.dispose();
    super.dispose();
  }

  void _calculateIncome() {
    final double basic = double.tryParse(_salBasicController.text) ?? 0.0;
    final double hra = double.tryParse(_salHraController.text) ?? 0.0;
    final double bonus = double.tryParse(_salBonusController.text) ?? 0.0;
    final double salTds = double.tryParse(_salTdsController.text) ?? 0.0;
    final double biz = double.tryParse(_bizProfitController.text) ?? 0.0;
    final double bankInterest = double.tryParse(_bankInterestController.text) ?? 0.0;
    final double bankAit = double.tryParse(_bankAitController.text) ?? 0.0;
    final double rent = double.tryParse(_rentalIncomeController.text) ?? 0.0;
    final double capital = double.tryParse(_capitalGainsController.text) ?? 0.0;

    setState(() {
      _salGross = basic + hra + bonus;
      _salNet = _salGross - salTds;
      _bankNet = bankInterest - bankAit;
      _totalGrossIncome = _salGross + biz + bankInterest + rent + capital;
      _totalTds = salTds + bankAit;
    });
  }

  void _calculateDeductions() {
    final double life = double.tryParse(_lifeInsController.text) ?? 0.0;
    final double pf = double.tryParse(_pfController.text) ?? 0.0;
    final double dpsInput = double.tryParse(_dpsController.text) ?? 0.0;
    final double dps = dpsInput > 60000 ? 60000 : dpsInput; // Capped at 60k
    final double bonds = double.tryParse(_bondsController.text) ?? 0.0;
    final double donation = double.tryParse(_donationController.text) ?? 0.0;
    final double sharesInput = double.tryParse(_sharesController.text) ?? 0.0;
    final double shares = sharesInput > 50000 ? 50000 : sharesInput; // Capped at 50k

    setState(() {
      _totalDeductions = life + pf + dps + bonds + donation + shares;
      _taxRebate = _totalDeductions * 0.15; // 15% investment tax credit
    });
  }

  void _calculateTaxLiability() {
    // 50% of Basic salary housing rent allowance is exempt, up to max 50k
    final double basic = double.tryParse(_salBasicController.text) ?? 0.0;
    final double hra = double.tryParse(_salHraController.text) ?? 0.0;
    _hraExemption = MathMin(hra, MathMin(basic * 0.5, 50000));

    _taxableIncome = MathMax(0.0, _totalGrossIncome - _hraExemption);

    // Bangladesh progressive slabs calculation
    double tempTaxable = _taxableIncome;
    double calcTax = 0.0;

    // Slab 1: First 3,50,000 @ 0%
    if (tempTaxable > 350000) {
      tempTaxable -= 350000;

      // Slab 2: Next 1,00,000 @ 5%
      if (tempTaxable > 100000) {
        calcTax += 100000 * 0.05;
        tempTaxable -= 100000;

        // Slab 3: Next 3,00,000 @ 10%
        if (tempTaxable > 300000) {
          calcTax += 300000 * 0.10;
          tempTaxable -= 300000;

          // Slab 4: Next 4,00,000 @ 15%
          if (tempTaxable > 400000) {
            calcTax += 400000 * 0.15;
            tempTaxable -= 400000;

            // Slab 5: Next 5,00,000 @ 20%
            if (tempTaxable > 500000) {
              calcTax += 500000 * 0.20;
              tempTaxable -= 500000;

              // Slab 6: Remaining @ 25%
              calcTax += tempTaxable * 0.25;
            } else {
              calcTax += tempTaxable * 0.20;
            }
          } else {
            calcTax += tempTaxable * 0.15;
          }
        } else {
          calcTax += tempTaxable * 0.10;
        }
      } else {
        calcTax += tempTaxable * 0.05;
      }
    }

    _grossTax = calcTax;
    _netTaxPayable = MathMax(0.0, _grossTax - _taxRebate);

    final double result = _netTaxPayable - _totalTds;
    if (result > 0) {
      _balanceDue = result;
      _refundable = 0.0;
    } else {
      _balanceDue = 0.0;
      _refundable = result.abs();
    }
  }

  void _calculateNetWorth() {
    final double land = double.tryParse(_landController.text) ?? 0.0;
    final double vehicle = double.tryParse(_vehicleController.text) ?? 0.0;
    final double capital = double.tryParse(_capitalController.text) ?? 0.0;
    final double bank = double.tryParse(_bankBalancesController.text) ?? 0.0;
    final double cash = double.tryParse(_cashController.text) ?? 0.0;
    final double gold = double.tryParse(_goldController.text) ?? 0.0;
    final double otherAssets = double.tryParse(_otherAssetsController.text) ?? 0.0;

    final double bankLoan = double.tryParse(_bankLoanController.text) ?? 0.0;
    final double bizLoan = double.tryParse(_bizLoanController.text) ?? 0.0;
    final double otherLiab = double.tryParse(_otherLiabController.text) ?? 0.0;

    setState(() {
      _totalAssets = land + vehicle + capital + bank + cash + gold + otherAssets;
      _totalLiabilities = bankLoan + bizLoan + otherLiab;
      _netWorth = _totalAssets - _totalLiabilities;
    });
  }

  double MathMin(double a, double b) => a < b ? a : b;
  double MathMax(double a, double b) => a > b ? a : b;

  String _formatAmount(double amt) {
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_tinController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TIN and Taxpayer Name are required!'), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    if (_currentStep == 3) {
      _calculateTaxLiability();
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _submitReturn() async {
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the verification declaration first!'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<PortalProvider>(context, listen: false);

    // Build the new return object
    final itr = ItrRecord(
      id: 0,
      taxpayerId: widget.taxpayerId,
      returnNo: 'ITR-${_selectedAssessmentYear.replaceAll('-', '')}-${DateTime.now().millisecond}D',
      tinNumber: _tinController.text,
      taxpayerName: _nameController.text,
      itrCategory: _selectedCategory,
      companySubType: _selectedCategory == 'Company' ? _selectedCompanySubType : null,
      assessmentYear: _selectedAssessmentYear,
      incomeYear: _selectedIncomeYear,
      returnPeriod: _selectedPeriod,
      grossIncome: _totalGrossIncome,
      exemptIncome: _hraExemption,
      rebate: _taxRebate,
      taxRebate: _taxRebate,
      advanceTaxPaid: double.tryParse(_salTdsController.text) ?? 0.0,
      withholdingTax: double.tryParse(_bankAitController.text) ?? 0.0,
      taxPaid: _balanceDue,
      taxRate: _taxableIncome > 0 ? (_grossTax / _taxableIncome) * 100 : 0.0,
      grossTax: _grossTax,
      status: 'Submitted',
      submissionDate: _submissionDateController.text,
      dueDate: _dueDateController.text,
      submittedBy: widget.taxpayerName,
      remarks: _remarksController.text,
    );

    // Call create return
    final success = await provider.createItr(itr);
    
    // Save IT-10B if assets exist
    if (success && _totalAssets > 0) {
      final newReturnId = provider.itrs.first.id;
      final it10b = IT10BRecord(
        nonAgriculturalProperty: double.tryParse(_landController.text) ?? 0.0,
        agriculturalProperty: 0.0,
        investments: double.tryParse(_capitalController.text) ?? 0.0,
        motorVehicles: double.tryParse(_vehicleController.text) ?? 0.0,
        bankBalances: double.tryParse(_bankBalancesController.text) ?? 0.0,
        personalLiabilities: double.tryParse(_bankLoanController.text) ?? 0.0,
        netWealth: _netWorth,
        returnId: newReturnId,
      );
      await provider.saveIt10b(it10b);
    }

    setState(() {
      _isLoading = false;
      if (success) {
        _successRecord = provider.itrs.first;
        _currentStep = 7; // Success pane
      }
    });
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

    final isMobile = MediaQuery.of(context).size.width < 800;
    final theme = localTheme;
    const isDark = false;

    return Theme(
      data: localTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Filing Income Tax Return'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Progressive Wizard Rail (1 to 6 steps)
            if (_currentStep < 7) _buildStepRail(isMobile, isDark),
            const SizedBox(height: 24),
  
            // Wizard step panes
            if (_currentStep == 1) _buildStep1(isDark, theme),
            if (_currentStep == 2) _buildStep2(isDark, theme),
            if (_currentStep == 3) _buildStep3(isDark, theme),
            if (_currentStep == 4) _buildStep4(isDark, theme),
            if (_currentStep == 5) _buildStep5(isDark, theme),
            if (_currentStep == 6) _buildStep6(isDark, theme),
            if (_currentStep == 7) _buildStep7(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRail(bool isMobile, bool isDark) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Step $_currentStep of 6', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_getStepTitle(_currentStep), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(6, (index) {
        final stepNum = index + 1;
        final isDone = _currentStep > stepNum;
        final isActive = _currentStep == stepNum;
        
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.success
                          : isActive
                              ? AppColors.primary
                              : (isDark ? Colors.grey.shade800 : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone
                            ? AppColors.success
                            : isActive
                                ? AppColors.primary
                                : Colors.grey,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              stepNum.toString(),
                              style: TextStyle(
                                color: isDone || isActive ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getStepTitle(stepNum),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? AppColors.primary : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (stepNum < 6)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      height: 2,
                      color: isDone ? AppColors.success : Colors.grey.shade300,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Profile';
      case 2:
        return 'Income';
      case 3:
        return 'Deductions';
      case 4:
        return 'Tax Liability';
      case 5:
        return 'IT-10B';
      case 6:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  Widget _buildStep1(bool isDark, ThemeData theme) {
    return _buildCard(
      title: 'Taxpayer Profile',
      icon: Icons.person_outline,
      isDark: isDark,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedAssessmentYear,
          decoration: const InputDecoration(labelText: 'Assessment Year *'),
          items: _assessmentYears.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedAssessmentYear = v ?? _assessmentYears[0]),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedIncomeYear,
          decoration: const InputDecoration(labelText: 'Income Year'),
          items: _incomeYears.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedIncomeYear = v ?? _incomeYears[0]),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(labelText: 'Category *'),
          items: _itrCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() {
            _selectedCategory = v ?? _itrCategories[0];
            if (_selectedCategory != 'Company') _selectedCompanySubType = '';
          }),
        ),
        if (_selectedCategory == 'Company') ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCompanySubType.isEmpty ? null : _selectedCompanySubType,
            decoration: const InputDecoration(labelText: 'Company Type *'),
            items: _companySubTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedCompanySubType = v ?? ''),
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPeriod,
          decoration: const InputDecoration(labelText: 'Return Period'),
          items: _returnPeriods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedPeriod = v ?? _returnPeriods[0]),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tinController,
          decoration: const InputDecoration(labelText: 'TIN Number *', hintText: 'e.g. TIN-000000005'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Taxpayer Name *'),
        ),
        const SizedBox(height: 24),
        _buildStepNavigation(),
      ],
    );
  }

  Widget _buildStep2(bool isDark, ThemeData theme) {
    return _buildCard(
      title: 'Income Sources',
      icon: Icons.monetization_on_outlined,
      isDark: isDark,
      children: [
        const Text('Enter gross income and source deductions before rebate.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('SALARY INCOME', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        _buildTextField(_salBasicController, 'Basic Salary (৳)'),
        _buildTextField(_salHraController, 'House Rent Allowance (৳)'),
        _buildTextField(_salBonusController, 'Festival Bonus / Other Allowances (৳)'),
        _buildTextField(_salTdsController, 'TDS Deducted from Salary (৳)'),
        
        const SizedBox(height: 16),
        const Divider(),
        const Text('BUSINESS INCOME', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        _buildTextField(_bizProfitController, 'Net Business Profits (৳)'),

        const SizedBox(height: 16),
        const Divider(),
        const Text('OTHER SOURCES', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        _buildTextField(_bankInterestController, 'Bank Interest (৳)'),
        _buildTextField(_bankAitController, 'Bank AIT Paid (৳)'),
        _buildTextField(_rentalIncomeController, 'House Property Rental Income (৳)'),
        _buildTextField(_capitalGainsController, 'Capital Gains (৳)'),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Gross Income Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatAmount(_totalGrossIncome), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStepNavigation(),
      ],
    );
  }

  Widget _buildStep3(bool isDark, ThemeData theme) {
    return _buildCard(
      title: 'Deductions & Rebates',
      icon: Icons.savings_outlined,
      isDark: isDark,
      children: [
        const Text('Investments qualifying for Section 44 tax credit (rebate).', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        _buildTextField(_lifeInsController, 'Life Insurance Premium (৳)'),
        _buildTextField(_pfController, 'Provident Fund (৳)'),
        _buildTextField(_dpsController, 'DPS / Savings Deposit (৳, max 60k limit)'),
        _buildTextField(_bondsController, 'Government Bonds / Sanchaypatra (৳)'),
        _buildTextField(_donationController, 'Approved Charity Zakat / Donations (৳)'),
        _buildTextField(_sharesController, 'Listed Company Stocks / Shares (৳, max 50k limit)'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.teal.shade50.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Allowable Investments:', style: TextStyle(fontSize: 13)),
                  Text(_formatAmount(_totalDeductions), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tax Rebate (15% of investments):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatAmount(_taxRebate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 15)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStepNavigation(),
      ],
    );
  }

  Widget _buildStep4(bool isDark, ThemeData theme) {
    final isPositive = _refundable > 0;
    return Column(
      children: [
        // Slabs table
        _buildCard(
          title: 'Bangladesh Individual Tax Slab Bracket (FY 2024-25)',
          icon: Icons.table_rows_outlined,
          isDark: isDark,
          children: [
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.teal),
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text('Income Slab', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                _buildSlabRow('First ৳ 3,50,000', '0%', _taxableIncome > 0),
                _buildSlabRow('Next ৳ 1,00,000', '5%', _taxableIncome > 350000),
                _buildSlabRow('Next ৳ 3,00,000', '10%', _taxableIncome > 450000),
                _buildSlabRow('Next ৳ 4,00,000', '15%', _taxableIncome > 750000),
                _buildSlabRow('Next ৳ 5,00,000', '20%', _taxableIncome > 1150000),
                _buildSlabRow('Above ৳ 16,50,000', '25%', _taxableIncome > 1650000),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Calculations summary
        _buildCard(
          title: 'Tax liability calculations',
          icon: Icons.calculate_outlined,
          isDark: isDark,
          children: [
            _buildCalcSummaryRow('Gross Income', _formatAmount(_totalGrossIncome)),
            _buildCalcSummaryRow('Less: Housing Rent Exemption', '- ${_formatAmount(_hraExemption)}', color: AppColors.success),
            _buildCalcSummaryRow('Taxable Income', _formatAmount(_taxableIncome), isBold: true),
            _buildCalcSummaryRow('Gross Tax Liability', _formatAmount(_grossTax)),
            _buildCalcSummaryRow('Less: Investment Rebate', '- ${_formatAmount(_taxRebate)}', color: AppColors.success),
            _buildCalcSummaryRow('Net Tax Payable', _formatAmount(_netTaxPayable), isBold: true),
            _buildCalcSummaryRow('Less: TDS & AIT already paid', '- ${_formatAmount(_totalTds)}', color: AppColors.success),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isPositive ? 'Refund receivable' : 'Outstanding tax payable', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  _formatAmount(isPositive ? _refundable : _balanceDue),
                  style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? AppColors.success : AppColors.error, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStepNavigation(),
          ],
        ),
      ],
    );
  }

  Widget _buildStep5(bool isDark, ThemeData theme) {
    return _buildCard(
      title: 'IT-10B Statement of Assets & Liabilities',
      icon: Icons.home_work_outlined,
      isDark: isDark,
      children: [
        const Text('Mandatory asset declaration statement. Cost value.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        const Text('ASSETS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        _buildTextField(_landController, 'Land / Building properties (৳)'),
        _buildTextField(_vehicleController, 'Motor Vehicle Value (৳)'),
        _buildTextField(_capitalController, 'Business Capital (৳)'),
        _buildTextField(_bankBalancesController, 'FDR & Bank Balance (৳)'),
        _buildTextField(_cashController, 'Cash in Hand (৳)'),
        _buildTextField(_goldController, 'Gold / Jewellery Value (৳)'),
        _buildTextField(_otherAssetsController, 'Other Assets (৳)'),
        
        const SizedBox(height: 16),
        const Divider(),
        const Text('LIABILITIES', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        _buildTextField(_bankLoanController, 'Bank Loan / Mortgages (৳)'),
        _buildTextField(_bizLoanController, 'Business Loans (৳)'),
        _buildTextField(_otherLiabController, 'Other Liabilities (৳)'),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Computed Net Worth (Assets - Liabilities):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_formatAmount(_netWorth), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStepNavigation(),
      ],
    );
  }

  Widget _buildStep6(bool isDark, ThemeData theme) {
    final hasTaxDue = _balanceDue > 0;
    return Column(
      children: [
        // Summary box
        _buildCard(
          title: 'ITR Review Summary',
          icon: Icons.visibility_outlined,
          isDark: isDark,
          children: [
            _buildCalcSummaryRow('TIN Number', _tinController.text),
            _buildCalcSummaryRow('Taxpayer Name', _nameController.text),
            _buildCalcSummaryRow('Filing Period', 'FY $_selectedAssessmentYear ($_selectedPeriod)'),
            _buildCalcSummaryRow('Gross Income', _formatAmount(_totalGrossIncome)),
            _buildCalcSummaryRow('Taxable Income', _formatAmount(_taxableIncome)),
            _buildCalcSummaryRow('Net Tax Payable', _formatAmount(_netTaxPayable)),
            _buildCalcSummaryRow('TDS & AIT credits applied', _formatAmount(_totalTds)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(hasTaxDue ? 'Total balance payable' : 'Refund balance due', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _formatAmount(hasTaxDue ? _balanceDue : _refundable),
                  style: TextStyle(fontWeight: FontWeight.bold, color: hasTaxDue ? AppColors.error : AppColors.success, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment form
        if (hasTaxDue)
          _buildCard(
            title: 'Tax Payment Options',
            icon: Icons.payment_outlined,
            isDark: isDark,
            children: [
              Row(
                children: [
                  _buildPaymentRadio('challan', 'Bank Challan'),
                  const SizedBox(width: 12),
                  _buildPaymentRadio('bkash', 'bKash Merchant'),
                ],
              ),
              const SizedBox(height: 16),
              if (_paymentMethod == 'challan') ...[
                _buildTextField(_challanBankController, 'Bank Name *'),
                _buildTextField(_challanNoController, 'Challan Serial No. *'),
                _buildTextField(_challanDateController, 'Payment Date *'),
              ] else ...[
                _buildTextField(_mfsTxnController, 'MFS Transaction ID *'),
              ]
            ],
          ),
        const SizedBox(height: 16),

        // Declarations
        _buildCard(
          title: 'Declaration consent',
          icon: Icons.assignment_turned_in_outlined,
          isDark: isDark,
          children: [
            Text(
              'I, ${_nameController.text} (TIN: ${_tinController.text}), solemnly declare that the information provided in this return of income is correct and complete to the best of my knowledge and belief.',
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _declarationAccepted,
              title: const Text('I confirm this declaration consent.', style: TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() => _declarationAccepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks (Optional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReturn,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_and_archive),
                  label: const Text('Submit Return Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep7(bool isDark, ThemeData theme) {
    if (_successRecord == null) return const SizedBox();

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.done_all, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            'ITR Filed Successfully!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
          ),
          const SizedBox(height: 6),
          Text(
            'Your tax return record has been saved.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Acknowledgement box (receipt design)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('ACKNOWLEDGEMENT RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('National Board of Revenue, Bangladesh', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
                const SizedBox(height: 16),
                const Divider(),
                _buildCalcSummaryRow('Acknowledgement No.', _successRecord!.returnNo ?? '—'),
                _buildCalcSummaryRow('TIN Number', _successRecord!.tinNumber ?? '—'),
                _buildCalcSummaryRow('Taxpayer Name', _successRecord!.taxpayerName ?? '—'),
                _buildCalcSummaryRow('Assessment Year', _successRecord!.assessmentYear),
                _buildCalcSummaryRow('Gross Income Declared', _formatAmount(_successRecord!.grossIncome ?? 0.0)),
                _buildCalcSummaryRow('Net Tax Payable', _formatAmount((_successRecord!.grossTax ?? 0.0) - (_successRecord!.rebate ?? 0.0))),
                _buildCalcSummaryRow('Self-Paid Tax', _formatAmount(_successRecord!.taxPaid ?? 0.0)),
                _buildCalcSummaryRow('Submission Date', _formatDate(_successRecord!.submissionDate)),
                const Divider(),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Status: Submitted', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.list_alt),
                label: const Text('Back to List'),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItrDetailsScreen(itrId: _successRecord!.id)),
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Return Details'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRadio(String value, String label) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v ?? 'challan'),
          activeColor: AppColors.primary,
        ),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  TableRow _buildSlabRow(String slab, String rate, bool isActive) {
    return TableRow(
      decoration: BoxDecoration(color: isActive ? Colors.teal.withOpacity(0.08) : null),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(slab, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(rate, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildCalcSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildStepNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 1)
          OutlinedButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          )
        else
          const SizedBox(),
        ElevatedButton.icon(
          onPressed: _nextStep,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
