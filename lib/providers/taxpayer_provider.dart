import 'session_data_provider.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../data/models/taxpayer.dart';

class TaxpayerProvider extends SessionDataProvider {
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
    } catch (_) {
      _errorMessage = 'Could not refresh the taxpayer profile.';
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
      _tinRecord = null;
      final response = await apiClient.get(ApiEndpoints.tins);
      if (response.data != null) {
        if (response.data is List && (response.data as List).isNotEmpty) {
          _tinRecord = TinRecord.fromJson(response.data[0]);
        } else if (response.data is Map) {
          _tinRecord = TinRecord.fromJson(response.data as Map<String, dynamic>);
        }
      }
    } catch (_) {
      _errorMessage = 'Could not refresh the TIN record.';
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
      _errorMessage = 'Could not confirm the server response.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
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
        final generatedTin = response.data['tinNumber']?.toString();
        if (generatedTin == null || generatedTin.isEmpty) throw const FormatException('Missing issued TIN');
        
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
      _errorMessage = 'Could not confirm the server response.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
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

}
