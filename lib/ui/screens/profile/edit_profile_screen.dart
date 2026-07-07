import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/taxpayer_provider.dart';
import '../../../data/models/taxpayer.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/portal_shell.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _nidController;
  late TextEditingController _fathersNameController;
  late TextEditingController _mothersNameController;
  late TextEditingController _dobController;
  late TextEditingController _professionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressDetailsController;

  // Selected values
  String? _selectedTaxpayerType;
  String? _selectedGender;
  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedStatus;
  String? _photoPath;

  bool _initialized = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _statuses = ['Active', 'Pending', 'Suspended'];
  final List<String> _taxpayerTypes = ['Resident Individual', 'Non-Resident Individual', 'Local Company', 'Foreign Company', 'Partnership', 'NGO'];
  final List<String> _divisions = ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'];
  final List<String> _districts = ['Dhaka', 'Gazipur', 'Narayanganj', 'Chattogram', 'Cox\'s Bazar', 'Sylhet', 'Bogura', 'Khulna'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final taxpayer = Provider.of<TaxpayerProvider>(context, listen: false).taxpayer;
      if (taxpayer != null) {
        _fullNameController = TextEditingController(text: taxpayer.fullName ?? taxpayer.companyName ?? '');
        _nidController = TextEditingController(text: taxpayer.nid ?? taxpayer.authorizedPersonNid ?? '');
        _fathersNameController = TextEditingController(text: taxpayer.fathersName ?? '');
        _mothersNameController = TextEditingController(text: taxpayer.mothersName ?? '');
        _dobController = TextEditingController(text: taxpayer.dateOfBirth ?? '');
        _professionController = TextEditingController(text: taxpayer.profession ?? taxpayer.natureOfBusiness ?? '');
        _emailController = TextEditingController(text: taxpayer.email ?? '');
        _phoneController = TextEditingController(text: taxpayer.phone ?? '');
        _addressDetailsController = TextEditingController(text: taxpayer.presentAddress?.details ?? '');

        _selectedTaxpayerType = taxpayer.taxpayerType?.typeName ?? 'Resident Individual';
        if (!_taxpayerTypes.contains(_selectedTaxpayerType)) {
          if (_selectedTaxpayerType != null) {
            _taxpayerTypes.add(_selectedTaxpayerType!);
          } else {
            _selectedTaxpayerType = 'Resident Individual';
          }
        }
        
        _selectedGender = taxpayer.gender;
        if (!_genders.contains(_selectedGender)) _selectedGender = null;

        _selectedDivision = taxpayer.presentAddress?.division;
        if (!_divisions.contains(_selectedDivision)) _selectedDivision = null;

        _selectedDistrict = taxpayer.presentAddress?.district;
        if (!_districts.contains(_selectedDistrict)) _selectedDistrict = null;

        _selectedStatus = taxpayer.approvalStatus ?? 'Pending';
        if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'Pending';

        _photoPath = taxpayer.photoPath;
      } else {
        _fullNameController = TextEditingController();
        _nidController = TextEditingController();
        _fathersNameController = TextEditingController();
        _mothersNameController = TextEditingController();
        _dobController = TextEditingController();
        _professionController = TextEditingController();
        _emailController = TextEditingController();
        _phoneController = TextEditingController();
        _addressDetailsController = TextEditingController();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nidController.dispose();
    _fathersNameController.dispose();
    _mothersNameController.dispose();
    _dobController.dispose();
    _professionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressDetailsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _updateProfilePhoto() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        List<int>? fileBytes;
        String? fileName;

        if (result.files.single.bytes != null) {
          fileBytes = result.files.single.bytes!;
          fileName = result.files.single.name;
        } else if (result.files.single.path != null) {
          final ioFile = io.File(result.files.single.path!);
          fileBytes = await ioFile.readAsBytes();
          fileName = result.files.single.name;
        }

        if (fileBytes != null && fileName != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading photo...'), duration: Duration(seconds: 2)),
          );

          final provider = Provider.of<TaxpayerProvider>(context, listen: false);
          final success = await provider.uploadPhoto(fileBytes, fileName);

          if (success && mounted) {
            setState(() {
              _photoPath = provider.taxpayer?.photoPath;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo uploaded successfully!')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage ?? 'Upload failed.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select file: $e')),
        );
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<TaxpayerProvider>(context, listen: false);
      final currentTaxpayer = provider.taxpayer;

      if (currentTaxpayer == null) return;

      final updatedAddress = Address(
        division: _selectedDivision,
        district: _selectedDistrict,
        details: _addressDetailsController.text,
      );

      final updatedType = TaxpayerType(
        category: currentTaxpayer.taxpayerType?.category ?? 'Individual',
        typeName: _selectedTaxpayerType,
      );

      final updatedTaxpayer = Taxpayer(
        id: currentTaxpayer.id,
        fullName: _fullNameController.text,
        companyName: currentTaxpayer.companyName,
        tin: currentTaxpayer.tin,
        nid: _nidController.text,
        dateOfBirth: _dobController.text,
        gender: _selectedGender,
        phone: _phoneController.text,
        email: _emailController.text,
        profession: _professionController.text,
        fathersName: _fathersNameController.text,
        mothersName: _mothersNameController.text,
        presentAddress: updatedAddress,
        photoPath: _photoPath,
        approvalStatus: _selectedStatus,
        taxpayerType: updatedType,
        rjscNo: currentTaxpayer.rjscNo,
        natureOfBusiness: currentTaxpayer.natureOfBusiness,
        authorizedPersonName: currentTaxpayer.authorizedPersonName,
        authorizedPersonNid: currentTaxpayer.authorizedPersonNid,
      );

      final success = await provider.updateProfile(updatedTaxpayer);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taxpayer profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PortalShell(
      breadcrumbs: const ['My Portal', 'Edit Profile'],
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Page Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Taxpayer Details',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update registration details, photo, contact, and address logs.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Card Form Container
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. TAXPAYER IDENTITY ---
                    _buildSectionHeader('Taxpayer Identity', Icons.badge_outlined),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildDropdownField(
                          label: 'Taxpayer Type *',
                          value: _selectedTaxpayerType,
                          items: _taxpayerTypes,
                          onChanged: (val) => setState(() => _selectedTaxpayerType = val),
                        ),
                        _buildTextField(
                          label: 'Full Name *',
                          controller: _fullNameController,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildTextField(
                          label: 'National ID (NID) *',
                          controller: _nidController,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsPointerTextField(
                            label: 'Date of Birth *',
                            controller: _dobController,
                            suffixIcon: const Icon(Icons.calendar_today, size: 16),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildDropdownField(
                          label: 'Gender *',
                          value: _selectedGender,
                          items: _genders,
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        _buildTextField(
                          label: 'Profession *',
                          controller: _professionController,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildTextField(
                          label: 'Father\'s Name',
                          controller: _fathersNameController,
                        ),
                        _buildTextField(
                          label: 'Mother\'s Name',
                          controller: _mothersNameController,
                        ),
                      ],
                    ),

                    const Divider(height: 40),

                    // --- 2. CONTACT INFORMATION ---
                    _buildSectionHeader('Contact Information', Icons.contact_mail_outlined),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildTextField(
                          label: 'Email Address *',
                          controller: _emailController,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                        _buildTextField(
                          label: 'Phone Number *',
                          controller: _phoneController,
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),

                    const Divider(height: 40),

                    // --- 3. ADDRESS DETAILS ---
                    _buildSectionHeader('Address Details', Icons.home_outlined),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      children: [
                        _buildDropdownField(
                          label: 'Division *',
                          value: _selectedDivision,
                          items: _divisions,
                          onChanged: (val) => setState(() => _selectedDivision = val),
                        ),
                        _buildDropdownField(
                          label: 'District *',
                          value: _selectedDistrict,
                          items: _districts,
                          onChanged: (val) => setState(() => _selectedDistrict = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Thana / Road / Village details *',
                      controller: _addressDetailsController,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),

                    const Divider(height: 40),

                    // --- 4. PROFILE PHOTO ---
                    _buildSectionHeader('Profile Photo', Icons.photo_camera_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.teal.shade50,
                          backgroundImage: _photoPath != null
                              ? NetworkImage('${ApiEndpoints.baseUrl.replaceAll('/api', '')}$_photoPath')
                              : null,
                          child: _photoPath == null
                              ? const Icon(Icons.person, size: 36, color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _updateProfilePhoto,
                              icon: const Icon(Icons.upload, size: 16),
                              label: const Text('Select Photo'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG or PNG. Max size 5MB.',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 40),

                    // --- 5. ACCOUNT STATUS ---
                    _buildSectionHeader('Account Status', Icons.security_outlined),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'Approval Status *',
                      value: _selectedStatus,
                      items: _statuses,
                      onChanged: (val) => setState(() => _selectedStatus = val),
                    ),

                    const SizedBox(height: 40),

                    // --- ACTION BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 160,
                          child: CustomButton(
                            text: 'Update Profile',
                            onPressed: _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal.shade900),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((child) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: child,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class AbsPointerTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AbsPointerTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.suffixIcon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
