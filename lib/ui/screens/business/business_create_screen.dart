import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/portal_provider.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../../data/models/portal_records.dart';

class BusinessCreateScreen extends StatefulWidget {
  const BusinessCreateScreen({Key? key}) : super(key: key);

  @override
  State<BusinessCreateScreen> createState() => _BusinessCreateScreenState();
}

class _BusinessCreateScreenState extends State<BusinessCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  bool _isAutoFilled = false;
  String? _autoFilledName;
  String? _autoFilledTin;

  // Form Field Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _turnoverController = TextEditingController();
  final TextEditingController _employeesController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedType;
  String? _selectedCategory;
  String _selectedStatus = 'Active';
  String? _selectedDivision;
  String? _selectedDistrict;

  String? _incorporationDate;
  String? _registrationDate = DateTime.now().toIso8601String().substring(0, 10);
  String? _expiryDate;

  final List<String> _businessTypes = ['Textile Manufacturing', 'Retail', 'Service', 'Agribusiness', 'Wholesale', 'IT & Tech'];
  final List<String> _businessCategories = ['Garments & Textile', 'Agriculture', 'Software & IT', 'Food & Beverage', 'Trading'];
  final List<String> _divisions = ['Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Sylhet', 'Barisal'];
  final List<String> _districts = ['Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Sylhet', 'Gazipur'];

  @override
  void initState() {
    super.initState();
    // Auto populate defaults if user profile already has TIN details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taxpayer = Provider.of<TaxpayerProvider>(context, listen: false).taxpayer;
      if (taxpayer != null && taxpayer.tin != null) {
        _searchController.text = taxpayer.tin!;
        _triggerAutoFill(taxpayer.fullName ?? taxpayer.companyName ?? 'Tasrif Zaman', taxpayer.tin!);
      }
    });
  }

  void _triggerAutoFill(String name, String tin) {
    setState(() {
      _isAutoFilled = true;
      _autoFilledName = name;
      _autoFilledTin = tin;
      _emailController.text = 'business@example.com';
      _phoneController.text = '01820318364';
    });
  }

  void _searchTaxpayer() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final taxpayerProv = Provider.of<TaxpayerProvider>(context, listen: false);
    final tp = taxpayerProv.taxpayer;
    if (tp != null && (query == tp.tin || query.toLowerCase() == (tp.fullName ?? '').toLowerCase())) {
      _triggerAutoFill(tp.fullName ?? tp.companyName ?? 'Tasrif Zaman', tp.tin!);
    } else {
      // Mock lookup success for standard demo cases
      _triggerAutoFill('Tasrif Zaman', 'TIN-000000005');
    }
  }

  Future<void> _selectDate(BuildContext context, int dateType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        final formatted = picked.toIso8601String().substring(0, 10);
        if (dateType == 1) {
          _incorporationDate = formatted;
        } else if (dateType == 2) {
          _registrationDate = formatted;
        } else {
          _expiryDate = formatted;
        }
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAutoFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please find and auto-fill taxpayer details first.'), backgroundColor: AppColors.error),
      );
      return;
    }

    final newBiz = Business(
      id: 0,
      name: _nameController.text.trim(),
      tradeLicenseNo: _licenseController.text.trim(),
      vatStatus: _selectedStatus,
      address: _addressController.text.trim(),
      ownerName: _autoFilledName,
      tinNumber: _autoFilledTin,
      businessType: _selectedType,
      businessCategory: _selectedCategory,
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      division: _selectedDivision,
      district: _selectedDistrict,
      incorporationDate: _incorporationDate,
      registrationDate: _registrationDate,
      expiryDate: _expiryDate,
      annualTurnover: double.tryParse(_turnoverController.text) ?? 0.0,
      numberOfEmployees: int.tryParse(_employeesController.text) ?? 0,
      remarks: _remarksController.text.trim(),
    );

    final portalProv = Provider.of<PortalProvider>(context, listen: false);
    final success = await portalProv.createBusiness(newBiz);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business registered successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _licenseController.clear();
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _turnoverController.clear();
      _employeesController.clear();
      _remarksController.clear();
      _selectedType = null;
      _selectedCategory = null;
      _selectedStatus = 'Active';
      _selectedDivision = null;
      _selectedDistrict = null;
      _incorporationDate = null;
      _registrationDate = DateTime.now().toIso8601String().substring(0, 10);
      _expiryDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Register Business'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Register Business',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register a new business entity.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card: Find Taxpayer
                  _buildFormSection(
                    title: 'Find Taxpayer',
                    subtitle: 'Search by TIN number or name — details will auto-fill',
                    icon: Icons.search,
                    isDark: isDark,
                    children: [
                      _buildResponsiveRow(
                        context,
                        [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Enter TIN number or taxpayer name',
                                hintStyle: const TextStyle(fontSize: 13),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _searchTaxpayer,
                            child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        spacing: 8,
                      ),
                      if (_isAutoFilled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flash_on, color: AppColors.success, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_autoFilledName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                                    Text('TIN: $_autoFilledTin', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Auto-filled', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Business Identity
                  _buildFormSection(
                    title: 'Business Identity',
                    subtitle: 'Basic business identification details',
                    icon: Icons.business,
                    isDark: isDark,
                    children: [
                      _buildLabel('Business Name *'),
                      TextFormField(
                        controller: _nameController,
                        validator: (val) => val == null || val.isEmpty ? 'Business name is required' : null,
                        decoration: _inputDecoration('Enter business name', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('TIN Number'),
                      TextFormField(
                        controller: TextEditingController(text: _autoFilledTin ?? 'Not Auto-filled'),
                        readOnly: true,
                        decoration: _inputDecoration('', isDark, isLocked: true),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Owner Name'),
                      TextFormField(
                        controller: TextEditingController(text: _autoFilledName ?? 'Not Auto-filled'),
                        readOnly: true,
                        decoration: _inputDecoration('', isDark, isLocked: true),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveRow(
                        context,
                        [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Business Type *'),
                                _buildDropdownField(_selectedType, _businessTypes, (val) => setState(() => _selectedType = val), isDark),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Business Category *'),
                                _buildDropdownField(_selectedCategory, _businessCategories, (val) => setState(() => _selectedCategory = val), isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Status'),
                      _buildDropdownField(_selectedStatus, ['Active', 'Pending', 'Suspended'], (val) => setState(() => _selectedStatus = val ?? 'Active'), isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: License & Registration
                  _buildFormSection(
                    title: 'License & Registration',
                    subtitle: 'Trade license, BIN and dates',
                    icon: Icons.assignment_outlined,
                    isDark: isDark,
                    children: [
                      _buildLabel('Trade License No. *'),
                      TextFormField(
                        controller: _licenseController,
                        validator: (val) => val == null || val.isEmpty ? 'Trade license is required' : null,
                        decoration: _inputDecoration('e.g. TL-44821', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveRow(
                        context,
                        [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Incorporation Date'),
                                _buildDatePickerField(_incorporationDate, () => _selectDate(context, 1), isDark),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Registration Date *'),
                                _buildDatePickerField(_registrationDate, () => _selectDate(context, 2), isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Trade License Expiry Date'),
                      _buildDatePickerField(_expiryDate, () => _selectDate(context, 3), isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Contact & Location
                  _buildFormSection(
                    title: 'Contact & Location',
                    subtitle: 'Contact details and business address',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                    children: [
                      _buildLabel('Email'),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('business@example.com', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Phone *'),
                      TextFormField(
                        controller: _phoneController,
                        validator: (val) => val == null || val.isEmpty ? 'Phone is required' : null,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('01xxx-xxxxxx', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildResponsiveRow(
                        context,
                        [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Division *'),
                                _buildDropdownField(_selectedDivision, _divisions, (val) => setState(() => _selectedDivision = val), isDark),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('District *'),
                                _buildDropdownField(_selectedDistrict, _districts, (val) => setState(() => _selectedDistrict = val), isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Full Address'),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: _inputDecoration('Enter full business address...', isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Financial & Workforce
                  _buildFormSection(
                    title: 'Financial & Workforce',
                    subtitle: 'Turnover and employee information',
                    icon: Icons.monetization_on_outlined,
                    isDark: isDark,
                    children: [
                      _buildLabel('Annual Turnover (৳) *'),
                      TextFormField(
                        controller: _turnoverController,
                        keyboardType: TextInputType.number,
                        validator: (val) => val == null || val.isEmpty ? 'Annual turnover is required' : null,
                        decoration: _inputDecoration('0', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Number of Employees'),
                      TextFormField(
                        controller: _employeesController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('0', isDark),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('Remarks'),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _inputDecoration('Optional remarks...', isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons (Register, Cancel, Reset)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Register Business', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          ),
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
      fillColor: isLocked
          ? Colors.grey.shade100
          : Colors.white,
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
              dateValue ?? 'mm/dd/yyyy',
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
