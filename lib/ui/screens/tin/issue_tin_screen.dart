import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../widgets/portal_shell.dart';

class IssueTinScreen extends StatefulWidget {
  const IssueTinScreen({Key? key}) : super(key: key);

  @override
  State<IssueTinScreen> createState() => _IssueTinScreenState();
}

class _IssueTinScreenState extends State<IssueTinScreen> {
  final _formKey = GlobalKey<FormState>();

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isAutoFilled = false;
  String? _autoFilledName;
  String? _autoFilledNid;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  String? _selectedCategory;
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedZone;
  String? _selectedCircle;
  String? _issueDate = DateTime.now().toIso8601String().substring(0, 10);

  final List<String> _categories = ['Individual', 'Company', 'Partnership', 'NGO', 'Government'];
  final List<String> _divisions = ['Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Sylhet', 'Barisal'];
  final List<String> _districts = ['Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Sylhet', 'Gazipur'];
  final List<String> _zones = ['Dhaka Tax Zone 11', 'Dhaka Tax Zone 12', 'Chittagong Tax Zone 1', 'Rajshahi Tax Zone 1'];
  final List<String> _circles = ['Dhaka Circle 22 (Dhanmondi)', 'Dhaka Circle 1 (Gulshan)', 'Chittagong Circle 5', 'Rajshahi Circle 2'];

  @override
  void initState() {
    super.initState();
    // Pre-populate search query if logged-in taxpayer has NID details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taxpayer = Provider.of<TaxpayerProvider>(context, listen: false).taxpayer;
      if (taxpayer != null) {
        if (taxpayer.nid != null) {
          _searchController.text = taxpayer.nid!;
          _triggerAutoFill(taxpayer.fullName ?? taxpayer.companyName ?? 'Tasrif Zaman', taxpayer.nid!);
        } else {
          _searchController.text = taxpayer.fullName ?? '';
        }
      }
    });
  }

  void _triggerAutoFill(String name, String nid) {
    setState(() {
      _isAutoFilled = true;
      _autoFilledName = name;
      _autoFilledNid = nid;
      _emailController.text = 'tasrif@gmail.com';
      _phoneController.text = '01987262436';
      _addressController.text = 'Flat 4B, House 12, Road 5, Dhanmondi, Dhaka';
    });
  }

  void _searchTaxpayer() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final taxpayerProv = Provider.of<TaxpayerProvider>(context, listen: false);
    final tp = taxpayerProv.taxpayer;
    if (tp != null && (query == tp.nid || query.toLowerCase() == (tp.fullName ?? '').toLowerCase())) {
      _triggerAutoFill(tp.fullName ?? tp.companyName ?? 'Tasrif Zaman', tp.nid!);
    } else {
      _triggerAutoFill('Tasrif Zaman', '1234567890');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _issueDate = picked.toIso8601String().substring(0, 10);
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

    final reqData = {
      'taxpayerId': Provider.of<TaxpayerProvider>(context, listen: false).taxpayer?.id ?? 1,
      'tinCategory': _selectedCategory ?? 'Individual',
      'nid': _autoFilledNid,
      'dateOfBirth': '2000-06-22',
      'gender': 'Male',
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'division': _selectedDivision,
      'district': _selectedDistrict,
      'taxZone': _selectedZone,
      'taxCircle': _selectedCircle,
      'status': 'Active',
      'remarks': _remarksController.text.trim(),
    };

    final taxpayerProv = Provider.of<TaxpayerProvider>(context, listen: false);
    final success = await taxpayerProv.issueTin(reqData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TIN Issued successfully!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    }
  }

  void _resetForm() {
    setState(() {
      _emailController.clear();
      _phoneController.clear();
      _addressController.clear();
      _remarksController.clear();
      _selectedCategory = null;
      _selectedDivision = null;
      _selectedDistrict = null;
      _selectedZone = null;
      _selectedCircle = null;
      _issueDate = DateTime.now().toIso8601String().substring(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Issue TIN'],
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Issue TIN',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Issue a new Taxpayer Identification Number.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

                  // Card: Find Taxpayer
                  _buildFormSection(
                    title: 'Find Taxpayer',
                    subtitle: 'Search by NID or name — details will auto-fill',
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
                                hintText: 'Enter NID number or taxpayer name',
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
                                    Text('NID: $_autoFilledNid', style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
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

                  // Card: Taxpayer Information
                  _buildFormSection(
                    title: 'Taxpayer Information',
                    subtitle: 'Name, category and identification',
                    icon: Icons.assignment_ind_outlined,
                    isDark: isDark,
                    children: [
                      _buildLabel('Taxpayer Name *'),
                      TextFormField(
                        controller: TextEditingController(text: _autoFilledName ?? 'Not Auto-filled'),
                        readOnly: true,
                        decoration: _inputDecoration('', isDark, isLocked: true),
                      ),
                      const SizedBox(height: 12),
                      _buildLabel('TIN Category *'),
                      _buildDropdownField(_selectedCategory, _categories, (val) => setState(() => _selectedCategory = val), isDark),
                      const SizedBox(height: 12),
                      _buildLabel('Issue Date'),
                      _buildDatePickerField(_issueDate, () => _selectDate(context), isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Location & Tax Authority
                  _buildFormSection(
                    title: 'Location & Tax Authority',
                    subtitle: 'Select division -> district -> tax zone -> tax circle',
                    icon: Icons.map_outlined,
                    isDark: isDark,
                    children: [
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
                      _buildLabel('Tax Zone *'),
                      _buildDropdownField(_selectedZone, _zones, (val) => setState(() => _selectedZone = val), isDark),
                      const SizedBox(height: 12),
                      _buildLabel('Tax Circle *'),
                      _buildDropdownField(_selectedCircle, _circles, (val) => setState(() => _selectedCircle = val), isDark),
                      const SizedBox(height: 12),
                      _buildLabel('Email'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Enter email', isDark),
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
                      _buildLabel('Address'),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: _inputDecoration('Enter full address...', isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card: Remarks
                  _buildFormSection(
                    title: 'Remarks',
                    subtitle: 'Optional notes',
                    icon: Icons.comment_outlined,
                    isDark: isDark,
                    children: [
                      _buildLabel('Remarks'),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: _inputDecoration('Optional remarks...', isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom buttons
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitForm,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Issue TIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
