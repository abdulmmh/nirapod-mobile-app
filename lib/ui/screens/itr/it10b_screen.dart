import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../data/models/portal_records.dart';

class It10bScreen extends StatefulWidget {
  final int returnId;
  final String returnNo;

  const It10bScreen({Key? key, required this.returnId, required this.returnNo}) : super(key: key);

  @override
  State<It10bScreen> createState() => _It10bScreenState();
}

class _It10bScreenState extends State<It10bScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  int? _existingId;

  // Controllers
  final _nonAgriController = TextEditingController(text: '0');
  final _agriController = TextEditingController(text: '0');
  final _investmentsController = TextEditingController(text: '0');
  final _vehiclesController = TextEditingController(text: '0');
  final _bankBalancesController = TextEditingController(text: '0');
  final _liabilitiesController = TextEditingController(text: '0');

  double _totalAssets = 0.0;
  double _netWealth = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingStatement();
    // Attach listeners to recalculate net wealth live
    _nonAgriController.addListener(_recalculateWealth);
    _agriController.addListener(_recalculateWealth);
    _investmentsController.addListener(_recalculateWealth);
    _vehiclesController.addListener(_recalculateWealth);
    _bankBalancesController.addListener(_recalculateWealth);
    _liabilitiesController.addListener(_recalculateWealth);
  }

  @override
  void dispose() {
    _nonAgriController.dispose();
    _agriController.dispose();
    _investmentsController.dispose();
    _vehiclesController.dispose();
    _bankBalancesController.dispose();
    _liabilitiesController.dispose();
    super.dispose();
  }

  void _recalculateWealth() {
    final double nonAgri = double.tryParse(_nonAgriController.text) ?? 0.0;
    final double agri = double.tryParse(_agriController.text) ?? 0.0;
    final double invest = double.tryParse(_investmentsController.text) ?? 0.0;
    final double vehicles = double.tryParse(_vehiclesController.text) ?? 0.0;
    final double bank = double.tryParse(_bankBalancesController.text) ?? 0.0;
    final double liab = double.tryParse(_liabilitiesController.text) ?? 0.0;

    setState(() {
      _totalAssets = nonAgri + agri + invest + vehicles + bank;
      _netWealth = _totalAssets - liab;
    });
  }

  Future<void> _loadExistingStatement() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final statement = await provider.getIt10bByReturnId(widget.returnId);
    
    if (statement != null) {
      _existingId = statement.id;
      _nonAgriController.text = statement.nonAgriculturalProperty.toStringAsFixed(0);
      _agriController.text = statement.agriculturalProperty.toStringAsFixed(0);
      _investmentsController.text = statement.investments.toStringAsFixed(0);
      _vehiclesController.text = statement.motorVehicles.toStringAsFixed(0);
      _bankBalancesController.text = statement.bankBalances.toStringAsFixed(0);
      _liabilitiesController.text = statement.personalLiabilities.toStringAsFixed(0);
      _recalculateWealth();
    }
    setState(() => _isLoading = false);
  }

  String _formatAmount(double amt) {
    return NumberFormat.currency(locale: 'en_BD', symbol: '৳ ', decimalDigits: 0).format(amt);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final provider = Provider.of<PortalProvider>(context, listen: false);

    final statement = IT10BRecord(
      id: _existingId,
      returnId: widget.returnId,
      nonAgriculturalProperty: double.parse(_nonAgriController.text),
      agriculturalProperty: double.parse(_agriController.text),
      investments: double.parse(_investmentsController.text),
      motorVehicles: double.parse(_vehiclesController.text),
      bankBalances: double.parse(_bankBalancesController.text),
      personalLiabilities: double.parse(_liabilitiesController.text),
      netWealth: _netWealth,
    );

    final result = await provider.saveIt10b(statement);
    setState(() => _isSaving = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_existingId != null ? 'IT-10B Statement updated successfully!' : 'IT-10B Statement filed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    _nonAgriController.text = '0';
    _agriController.text = '0';
    _investmentsController.text = '0';
    _vehiclesController.text = '0';
    _bankBalancesController.text = '0';
    _liabilitiesController.text = '0';
    _recalculateWealth();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form fields reset.')),
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

    final theme = localTheme;
    const isDark = false;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Theme(
      data: localTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('IT-10B Statement'),
              Text('Linked to Return: ${widget.returnNo}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Sticky/Floating Real-Time Net Wealth Summary Card
                    _buildStickySummaryCard(isDark, isMobile),
                    const SizedBox(height: 20),
  
                    // Core Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Assets Header
                          _buildSectionHeader(Icons.account_balance_outlined, 'ASSETS OWNED', isDark),
                          const SizedBox(height: 16),
  
                          // Assets Grid Inputs
                          isMobile
                              ? Column(
                                  children: _buildAssetFields(isDark),
                                )
                              : Table(
                                  children: [
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: _buildAssetFields(isDark)[0],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10),
                                          child: _buildAssetFields(isDark)[1],
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10, top: 16),
                                          child: _buildAssetFields(isDark)[2],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 10, top: 16),
                                          child: _buildAssetFields(isDark)[3],
                                        ),
                                      ],
                                    ),
                                    TableRow(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 10, top: 16),
                                          child: _buildAssetFields(isDark)[4],
                                        ),
                                        const SizedBox(), // Empty cell to keep alignment
                                      ],
                                    ),
                                  ],
                                ),
  
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
  
                          // Liabilities Section
                          _buildSectionHeader(Icons.payment_outlined, 'LIABILITIES & DEBTS', isDark),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: _liabilitiesController,
                            label: 'Personal Liabilities',
                            hint: 'Bank loan, mortgage, debts, credit card dues',
                            icon: Icons.money_off,
                            isDark: isDark,
                          ),
  
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
  
                          // Action Buttons Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _resetForm,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.amber.shade700,
                                  side: BorderSide(color: Colors.amber.shade700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _submitForm,
                                icon: _isSaving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save),
                                label: Text(_existingId != null ? 'Update Statement' : 'Submit Statement'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ),
    );
  }

  Widget _buildStickySummaryCard(bool isDark, bool isMobile) {
    final isPositive = _netWealth >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPositive
            ? (isDark ? Colors.teal.shade900.withOpacity(0.4) : Colors.teal.shade50)
            : (isDark ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive ? Colors.teal.shade300 : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Real-Time Net Wealth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Total Assets - Liabilities', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assets: ${_formatAmount(_totalAssets)}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('Liabilities: ${_formatAmount(double.tryParse(_liabilitiesController.text) ?? 0.0)}', style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Net Wealth:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      _formatAmount(_netWealth),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Real-Time Net Wealth Computation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Assets: ${_formatAmount(_totalAssets)}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const Text('-', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text('Liabilities: ${_formatAmount(double.tryParse(_liabilitiesController.text) ?? 0.0)}', style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  _formatAmount(_netWealth),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAssetFields(bool isDark) {
    return [
      _buildFormField(
        controller: _nonAgriController,
        label: 'Non-Agricultural Property',
        hint: 'Land, house, commercial properties',
        icon: Icons.house_outlined,
        isDark: isDark,
      ),
      _buildFormField(
        controller: _agriController,
        label: 'Agricultural Property',
        hint: 'Farmland, orchards, plots',
        icon: Icons.eco_outlined,
        isDark: isDark,
      ),
      _buildFormField(
        controller: _investmentsController,
        label: 'Investments',
        hint: 'Savings certificates, bonds, stocks, FDR',
        icon: Icons.analytics_outlined,
        isDark: isDark,
      ),
      _buildFormField(
        controller: _vehiclesController,
        label: 'Motor Vehicles',
        hint: 'Car, bike, transport vehicles cost/value',
        icon: Icons.directions_car_filled_outlined,
        isDark: isDark,
      ),
      _buildFormField(
        controller: _bankBalancesController,
        label: 'Bank Balances & Cash',
        hint: 'Cash in hand, bank accounts totals',
        icon: Icons.wallet_outlined,
        isDark: isDark,
      ),
    ];
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '৳ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Field cannot be empty';
              if (double.tryParse(v) == null) return 'Enter a valid amount';
              if (double.parse(v) < 0) return 'Amount cannot be negative';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
