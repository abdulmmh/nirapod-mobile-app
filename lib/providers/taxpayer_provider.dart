import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../data/models/taxpayer.dart';

class TaxpayerProvider extends ChangeNotifier {
  Taxpayer? _taxpayer;
  bool _isLoading = false;
  String? _errorMessage;

  Taxpayer? get taxpayer => _taxpayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load the taxpayer profile matching active credentials
  Future<void> fetchProfile(int? taxpayerId, String category) async {
    if (taxpayerId == null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiEndpoints.taxpayerDetails(taxpayerId));
      if (response.data != null) {
        _taxpayer = Taxpayer.fromJson(response.data);
      }
    } catch (e) {
      print('Network request failed, loading mock taxpayer details: $e');
      _taxpayer = _getMockTaxpayer(taxpayerId, category);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Calculate profile completion percentage based on Angular's formula
  int get profileCompletion {
    if (_taxpayer == null) return 0;
    final tp = _taxpayer!;
    final category = tp.taxpayerType?.category?.toLowerCase() ?? '';
    List<bool> fields;

    if (category == 'individual') {
      fields = [
        tp.fullName != null && tp.fullName!.isNotEmpty,
        tp.nid != null && tp.nid!.isNotEmpty,
        tp.dateOfBirth != null && tp.dateOfBirth!.isNotEmpty,
        tp.gender != null && tp.gender!.isNotEmpty,
        tp.phone != null && tp.phone!.isNotEmpty,
        tp.email != null && tp.email!.isNotEmpty,
        tp.profession != null && tp.profession!.isNotEmpty,
        tp.fathersName != null && tp.fathersName!.isNotEmpty,
        tp.mothersName != null && tp.mothersName!.isNotEmpty,
        tp.presentAddress?.district != null && tp.presentAddress!.district!.isNotEmpty,
        tp.presentAddress?.division != null && tp.presentAddress!.division!.isNotEmpty,
        tp.photoPath != null && tp.photoPath!.isNotEmpty,
      ];
    } else {
      fields = [
        tp.companyName != null && tp.companyName!.isNotEmpty,
        tp.rjscNo != null && tp.rjscNo!.isNotEmpty,
        tp.natureOfBusiness != null && tp.natureOfBusiness!.isNotEmpty,
        tp.authorizedPersonName != null && tp.authorizedPersonName!.isNotEmpty,
        tp.authorizedPersonNid != null && tp.authorizedPersonNid!.isNotEmpty,
        tp.phone != null && tp.phone!.isNotEmpty,
        tp.email != null && tp.email!.isNotEmpty,
        tp.presentAddress?.district != null && tp.presentAddress!.district!.isNotEmpty,
        tp.presentAddress?.division != null && tp.presentAddress!.division!.isNotEmpty,
        tp.photoPath != null && tp.photoPath!.isNotEmpty,
      ];
    }

    final filled = fields.where((f) => f).length;
    return ((filled / fields.length) * 100).round();
  }

  // Get list of missing fields
  List<String> get missingFields {
    if (_taxpayer == null) return [];
    final tp = _taxpayer!;
    final category = tp.taxpayerType?.category?.toLowerCase() ?? '';
    final missing = <String>[];

    if (category == 'individual') {
      if (tp.fullName == null || tp.fullName!.isEmpty) missing.add('Full Name');
      if (tp.nid == null || tp.nid!.isEmpty) missing.add('NID Number');
      if (tp.dateOfBirth == null || tp.dateOfBirth!.isEmpty) missing.add('Date of Birth');
      if (tp.gender == null || tp.gender!.isEmpty) missing.add('Gender');
      if (tp.fathersName == null || tp.fathersName!.isEmpty) missing.add("Father's Name");
      if (tp.mothersName == null || tp.mothersName!.isEmpty) missing.add("Mother's Name");
      if (tp.phone == null || tp.phone!.isEmpty) missing.add('Phone');
      if (tp.email == null || tp.email!.isEmpty) missing.add('Email');
      if (tp.profession == null || tp.profession!.isEmpty) missing.add('Profession');
      if (tp.presentAddress?.district == null || tp.presentAddress!.district!.isEmpty) missing.add('District');
      if (tp.presentAddress?.division == null || tp.presentAddress!.division!.isEmpty) missing.add('Division');
      if (tp.photoPath == null || tp.photoPath!.isEmpty) missing.add('Profile Photo');
    } else {
      if (tp.companyName == null || tp.companyName!.isEmpty) missing.add('Company Name');
      if (tp.rjscNo == null || tp.rjscNo!.isEmpty) missing.add('RJSC Number');
      if (tp.natureOfBusiness == null || tp.natureOfBusiness!.isEmpty) missing.add('Nature of Business');
      if (tp.authorizedPersonName == null || tp.authorizedPersonName!.isEmpty) missing.add('Authorized Person');
      if (tp.authorizedPersonNid == null || tp.authorizedPersonNid!.isEmpty) missing.add('Authorized Person NID');
      if (tp.phone == null || tp.phone!.isEmpty) missing.add('Phone');
      if (tp.email == null || tp.email!.isEmpty) missing.add('Email');
      if (tp.presentAddress?.district == null || tp.presentAddress!.district!.isEmpty) missing.add('District');
      if (tp.presentAddress?.division == null || tp.presentAddress!.division!.isEmpty) missing.add('Division');
      if (tp.photoPath == null || tp.photoPath!.isEmpty) missing.add('Profile Photo');
    }
    return missing;
  }

  // Update profile
  Future<bool> updateProfile(Taxpayer updated) async {
    if (_taxpayer == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.put(
        ApiEndpoints.taxpayerUpdate(_taxpayer!.id),
        data: updated.toJson(),
      );
      if (response.data != null) {
        _taxpayer = Taxpayer.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Offline fallback: Update local state
      _taxpayer = updated;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Issue TIN
  Future<bool> issueTin(Map<String, dynamic> reqData) async {
    if (_taxpayer == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.tins, data: reqData);
      if (response.data != null) {
        final generatedTin = response.data['tinNumber']?.toString() ?? 'TIN-000000005';
        
        // Update local taxpayer
        _taxpayer = Taxpayer(
          id: _taxpayer!.id,
          fullName: _taxpayer!.fullName,
          companyName: _taxpayer!.companyName,
          tin: generatedTin,
          nid: reqData['nid'] ?? _taxpayer!.nid,
          dateOfBirth: reqData['dateOfBirth']?.toString() ?? _taxpayer!.dateOfBirth,
          gender: reqData['gender'] ?? _taxpayer!.gender,
          phone: reqData['phone'] ?? _taxpayer!.phone,
          email: reqData['email'] ?? _taxpayer!.email,
          profession: _taxpayer!.profession,
          fathersName: _taxpayer!.fathersName,
          mothersName: _taxpayer!.mothersName,
          presentAddress: Address(
            division: reqData['division'] ?? _taxpayer!.presentAddress?.division,
            district: reqData['district'] ?? _taxpayer!.presentAddress?.district,
            details: reqData['address'] ?? _taxpayer!.presentAddress?.details,
          ),
          photoPath: _taxpayer!.photoPath,
          approvalStatus: 'Approved',
          taxpayerType: _taxpayer!.taxpayerType,
          rjscNo: _taxpayer!.rjscNo,
          natureOfBusiness: _taxpayer!.natureOfBusiness,
          authorizedPersonName: _taxpayer!.authorizedPersonName,
          authorizedPersonNid: _taxpayer!.authorizedPersonNid,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      // Offline fallback: Mock a TIN
      final String mockTinNum = 'TIN-000000005';
      _taxpayer = Taxpayer(
        id: _taxpayer!.id,
        fullName: _taxpayer!.fullName,
        companyName: _taxpayer!.companyName,
        tin: mockTinNum,
        nid: reqData['nid'] ?? _taxpayer!.nid,
        dateOfBirth: reqData['dateOfBirth']?.toString() ?? _taxpayer!.dateOfBirth,
        gender: reqData['gender'] ?? _taxpayer!.gender,
        phone: reqData['phone'] ?? _taxpayer!.phone,
        email: reqData['email'] ?? _taxpayer!.email,
        profession: _taxpayer!.profession,
        fathersName: _taxpayer!.fathersName,
        mothersName: _taxpayer!.mothersName,
        presentAddress: Address(
          division: reqData['division'] ?? _taxpayer!.presentAddress?.division,
          district: reqData['district'] ?? _taxpayer!.presentAddress?.district,
          details: reqData['address'] ?? _taxpayer!.presentAddress?.details,
        ),
        photoPath: _taxpayer!.photoPath,
        approvalStatus: 'Approved',
        taxpayerType: _taxpayer!.taxpayerType,
        rjscNo: _taxpayer!.rjscNo,
        natureOfBusiness: _taxpayer!.natureOfBusiness,
        authorizedPersonName: _taxpayer!.authorizedPersonName,
        authorizedPersonNid: _taxpayer!.authorizedPersonNid,
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Upload profile photo
  Future<bool> uploadPhoto(String base64Image) async {
    if (_taxpayer == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      // Mock upload success or call endpoint
      _taxpayer = Taxpayer(
        id: _taxpayer!.id,
        fullName: _taxpayer!.fullName,
        companyName: _taxpayer!.companyName,
        tin: _taxpayer!.tin,
        nid: _taxpayer!.nid,
        dateOfBirth: _taxpayer!.dateOfBirth,
        gender: _taxpayer!.gender,
        phone: _taxpayer!.phone,
        email: _taxpayer!.email,
        profession: _taxpayer!.profession,
        fathersName: _taxpayer!.fathersName,
        mothersName: _taxpayer!.mothersName,
        presentAddress: _taxpayer!.presentAddress,
        photoPath: '/uploads/profiles/mock_avatar.png',
        approvalStatus: _taxpayer!.approvalStatus,
        taxpayerType: _taxpayer!.taxpayerType,
        rjscNo: _taxpayer!.rjscNo,
        natureOfBusiness: _taxpayer!.natureOfBusiness,
        authorizedPersonName: _taxpayer!.authorizedPersonName,
        authorizedPersonNid: _taxpayer!.authorizedPersonNid,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load static mock details based on taxpayer category
  Taxpayer _getMockTaxpayer(int id, String category) {
    if (category.toLowerCase() == 'individual') {
      return Taxpayer(
        id: id,
        fullName: 'Abdul Karim',
        tin: '102345678912',
        nid: '19952618293746',
        dateOfBirth: '1995-10-12',
        gender: 'Male',
        phone: '01712345678',
        email: 'taxpayer@example.com',
        profession: 'Software Engineer',
        fathersName: 'Abul Kalam',
        mothersName: 'Sufia Begum',
        presentAddress: Address(
          division: 'Dhaka',
          district: 'Dhaka',
          details: 'Flat 4B, House 12, Road 5, Dhanmondi',
        ),
        photoPath: '', // Empty triggers incomplete field item
        approvalStatus: 'Approved',
        taxpayerType: TaxpayerType(
          category: 'Individual',
          typeName: 'Resident Individual',
        ),
      );
    } else {
      return Taxpayer(
        id: id,
        companyName: 'A.K. Traders Ltd.',
        tin: '302485967154',
        rjscNo: 'C-98765/2020',
        natureOfBusiness: 'Trading and Distribution',
        authorizedPersonName: 'Abdul Karim',
        authorizedPersonNid: '19952618293746',
        phone: '01812345678',
        email: 'business@example.com',
        presentAddress: Address(
          division: 'Dhaka',
          district: 'Dhaka',
          details: 'Plot 45, Sector 7, Uttara',
        ),
        photoPath: '/uploads/profiles/business_avatar.png',
        approvalStatus: 'Approved',
        taxpayerType: TaxpayerType(
          category: 'Business',
          typeName: 'Private Limited Company',
        ),
      );
    }
  }
}
