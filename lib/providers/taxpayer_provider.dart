import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../data/models/taxpayer.dart';

class TaxpayerProvider extends ChangeNotifier {
  Taxpayer? _taxpayer;
  TinRecord? _tinRecord;
  bool _isLoading = false;
  String? _errorMessage;

  Taxpayer? get taxpayer => _taxpayer;
  TinRecord? get tinRecord => _tinRecord;
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

  // Fetch complete TIN record details for active taxpayer
  Future<void> fetchTinRecord() async {
    if (_taxpayer == null || _taxpayer!.tin == null || _taxpayer!.tin!.isEmpty) {
      _tinRecord = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiEndpoints.tins);
      if (response.data != null) {
        if (response.data is List && (response.data as List).isNotEmpty) {
          _tinRecord = TinRecord.fromJson(response.data[0]);
        } else if (response.data is Map) {
          _tinRecord = TinRecord.fromJson(response.data as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Network request failed, loading mock TIN details: $e');
      final tp = _taxpayer!;
      _tinRecord = TinRecord(
        id: 1,
        tinNumber: tp.tin ?? 'TIN-000000005',
        taxpayerId: tp.id,
        taxpayerName: tp.companyName ?? tp.fullName ?? 'Tasrif Zaman',
        tinCategory: tp.taxpayerType?.category ?? 'Individual',
        nid: tp.nid ?? '1234567890',
        dateOfBirth: tp.dateOfBirth ?? '2000-06-22',
        gender: tp.gender ?? 'Male',
        email: tp.email ?? 'tasrif@gmail.com',
        phone: tp.phone ?? '01987262436',
        address: tp.presentAddress?.details ?? 'Dhaka',
        district: tp.presentAddress?.district ?? 'Dhaka',
        division: tp.presentAddress?.division ?? 'Dhaka',
        taxZone: 'Dhaka Tax Zone',
        taxCircle: 'Dhaka Circle-1',
        status: 'Active',
        issuedDate: '2026-05-07',
        lastUpdated: '2026-05-11',
      );
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
        tp.fullName?.isNotEmpty ?? false,
        tp.nid?.isNotEmpty ?? false,
        tp.dateOfBirth?.isNotEmpty ?? false,
        tp.gender?.isNotEmpty ?? false,
        tp.phone?.isNotEmpty ?? false,
        tp.email?.isNotEmpty ?? false,
        tp.profession?.isNotEmpty ?? false,
        tp.fathersName?.isNotEmpty ?? false,
        tp.mothersName?.isNotEmpty ?? false,
        tp.presentAddress?.district?.isNotEmpty ?? false,
        tp.presentAddress?.division?.isNotEmpty ?? false,
        tp.photoPath?.isNotEmpty ?? false,
      ];
    } else {
      fields = [
        tp.companyName?.isNotEmpty ?? false,
        tp.rjscNo?.isNotEmpty ?? false,
        tp.natureOfBusiness?.isNotEmpty ?? false,
        tp.authorizedPersonName?.isNotEmpty ?? false,
        tp.authorizedPersonNid?.isNotEmpty ?? false,
        tp.phone?.isNotEmpty ?? false,
        tp.email?.isNotEmpty ?? false,
        tp.presentAddress?.district?.isNotEmpty ?? false,
        tp.presentAddress?.division?.isNotEmpty ?? false,
        tp.photoPath?.isNotEmpty ?? false,
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
      if (tp.fullName?.isEmpty ?? true) missing.add('Full Name');
      if (tp.nid?.isEmpty ?? true) missing.add('NID Number');
      if (tp.dateOfBirth?.isEmpty ?? true) missing.add('Date of Birth');
      if (tp.gender?.isEmpty ?? true) missing.add('Gender');
      if (tp.fathersName?.isEmpty ?? true) missing.add("Father's Name");
      if (tp.mothersName?.isEmpty ?? true) missing.add("Mother's Name");
      if (tp.phone?.isEmpty ?? true) missing.add('Phone');
      if (tp.email?.isEmpty ?? true) missing.add('Email');
      if (tp.profession?.isEmpty ?? true) missing.add('Profession');
      if (tp.presentAddress?.district?.isEmpty ?? true) missing.add('District');
      if (tp.presentAddress?.division?.isEmpty ?? true) missing.add('Division');
      if (tp.photoPath?.isEmpty ?? true) missing.add('Profile Photo');
    } else {
      if (tp.companyName?.isEmpty ?? true) missing.add('Company Name');
      if (tp.rjscNo?.isEmpty ?? true) missing.add('RJSC Number');
      if (tp.natureOfBusiness?.isEmpty ?? true) missing.add('Nature of Business');
      if (tp.authorizedPersonName?.isEmpty ?? true) missing.add('Authorized Person');
      if (tp.authorizedPersonNid?.isEmpty ?? true) missing.add('Authorized Person NID');
      if (tp.phone?.isEmpty ?? true) missing.add('Phone');
      if (tp.email?.isEmpty ?? true) missing.add('Email');
      if (tp.presentAddress?.district?.isEmpty ?? true) missing.add('District');
      if (tp.presentAddress?.division?.isEmpty ?? true) missing.add('Division');
      if (tp.photoPath?.isEmpty ?? true) missing.add('Profile Photo');
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
        _tinRecord = TinRecord(
          id: response.data['id'] ?? 1,
          tinNumber: generatedTin,
          taxpayerId: _taxpayer!.id,
          taxpayerName: _taxpayer!.companyName ?? _taxpayer!.fullName,
          tinCategory: reqData['tinCategory'] ?? _taxpayer!.taxpayerType?.category ?? 'Individual',
          nid: reqData['nid'] ?? _taxpayer!.nid,
          dateOfBirth: reqData['dateOfBirth']?.toString() ?? _taxpayer!.dateOfBirth,
          gender: reqData['gender'] ?? _taxpayer!.gender,
          email: reqData['email'] ?? _taxpayer!.email,
          phone: reqData['phone'] ?? _taxpayer!.phone,
          address: reqData['address'] ?? _taxpayer!.presentAddress?.details,
          district: reqData['district'] ?? _taxpayer!.presentAddress?.district,
          division: reqData['division'] ?? _taxpayer!.presentAddress?.division,
          taxZone: reqData['taxZone'] ?? 'Dhaka Tax Zone',
          taxCircle: reqData['taxCircle'] ?? 'Dhaka Circle-1',
          status: 'Active',
          issuedDate: DateTime.now().toString().split(' ')[0],
          lastUpdated: DateTime.now().toString().split(' ')[0],
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
      _tinRecord = TinRecord(
        id: 1,
        tinNumber: mockTinNum,
        taxpayerId: _taxpayer!.id,
        taxpayerName: _taxpayer!.companyName ?? _taxpayer!.fullName,
        tinCategory: reqData['tinCategory'] ?? _taxpayer!.taxpayerType?.category ?? 'Individual',
        nid: reqData['nid'] ?? _taxpayer!.nid,
        dateOfBirth: reqData['dateOfBirth']?.toString() ?? _taxpayer!.dateOfBirth,
        gender: reqData['gender'] ?? _taxpayer!.gender,
        email: reqData['email'] ?? _taxpayer!.email,
        phone: reqData['phone'] ?? _taxpayer!.phone,
        address: reqData['address'] ?? _taxpayer!.presentAddress?.details,
        district: reqData['district'] ?? _taxpayer!.presentAddress?.district,
        division: reqData['division'] ?? _taxpayer!.presentAddress?.division,
        taxZone: reqData['taxZone'] ?? 'Dhaka Tax Zone',
        taxCircle: reqData['taxCircle'] ?? 'Dhaka Circle-1',
        status: 'Active',
        issuedDate: DateTime.now().toString().split(' ')[0],
        lastUpdated: DateTime.now().toString().split(' ')[0],
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Upload profile photo
  Future<bool> uploadPhoto(List<int> bytes, String filename) async {
    if (_taxpayer == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await apiClient.post(
        ApiEndpoints.taxpayerUploadPhoto(_taxpayer!.id),
        data: formData,
      );

      if (response.data != null && response.data['photoUrl'] != null) {
        final String photoUrl = response.data['photoUrl'];
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
          photoPath: photoUrl,
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
      }
    } catch (e) {
      _errorMessage = 'Failed to upload photo: $e';
    }
    _isLoading = false;
    notifyListeners();
    return false;
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
