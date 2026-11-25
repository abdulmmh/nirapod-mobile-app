import 'package:file_picker/file_picker.dart';
import '../core/utils/document_upload.dart';
import 'session_data_provider.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../data/models/portal_records.dart';

class PortalProvider extends SessionDataProvider {
  List<ItrRecord> _itrs = [];
  List<AitRecord> _aits = [];
  List<Business> _businesses = [];
  List<Notice> _notices = [];
  List<Payment> _payments = [];
  List<Audit> _audits = [];
  List<Appeal> _appeals = [];
  List<VatRegistration> _vatRegistrations = [];
  List<VatReturn> _vatReturns = [];
  List<OutstandingItem> _outstandingItems = [];

  bool _isLoading = false;
  bool _isLoadingOutstanding = false;
  String? _errorMessage;

  List<ItrRecord> get itrs => _itrs;
  List<AitRecord> get aits => _aits;
  List<Business> get businesses => _businesses;
  List<Notice> get notices => _notices;
  List<Payment> get payments => _payments;
  List<Audit> get audits => _audits;
  List<Appeal> get appeals => _appeals;
  List<VatRegistration> get vatRegistrations => _vatRegistrations;
  List<VatReturn> get vatReturns => _vatReturns;
  List<OutstandingItem> get outstandingItems => _outstandingItems;

  bool get isLoading => _isLoading;
  bool get isLoadingOutstanding => _isLoadingOutstanding;
  String? get errorMessage => _errorMessage;

  int _loadVersion = 0;

  // Initialize and load all modules for a taxpayer
  Future<void> loadAllData(int taxpayerId) async {
    final version = ++_loadVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    Future<void> load<T>(String path, T Function(Map<String, dynamic>) parse,
        void Function(List<T>) apply) async {
      try {
        final response = await apiClient.get(path);
        final items = (response.data as List).cast<Map<String, dynamic>>().map(parse).toList();
        if (version == _loadVersion) apply(items);
      } catch (_) {
        if (version == _loadVersion) _errorMessage = 'Some dashboard data could not be refreshed.';
      }
    }

    await Future.wait([
      load('${ApiEndpoints.incomeTaxReturns}/my-returns', ItrRecord.fromJson, (v) => _itrs = v),
      load('${ApiEndpoints.aitRecords}/my-records', AitRecord.fromJson, (v) => _aits = v),
      load(ApiEndpoints.businessByTaxpayer(taxpayerId), Business.fromJson, (v) => _businesses = v),
      load(ApiEndpoints.noticesMy, Notice.fromJson, (v) => _notices = v),
      load(ApiEndpoints.payments, Payment.fromJson, (v) => _payments = v),
      load(ApiEndpoints.auditsMy, Audit.fromJson, (v) => _audits = v),
      load(ApiEndpoints.appealsMy, Appeal.fromJson, (v) => _appeals = v),
      load(ApiEndpoints.vatRegistrations, VatRegistration.fromJson, (v) => _vatRegistrations = v),
      load(ApiEndpoints.vatReturns, VatReturn.fromJson, (v) => _vatReturns = v),
    ]);
    if (version != _loadVersion) return;
    _isLoading = false;
    notifyListeners();
  }

  // File a new Income Tax Return (ITR)
  Future<bool> createItr(ItrRecord itr) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.incomeTaxReturns, data: itr.toJson());
      if (response.data != null) {
        _itrs.insert(0, ItrRecord.fromJson(response.data));
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

  // Preview ITR calculations
  Future<Map<String, dynamic>?> previewItr(ItrRecord itr) async {
    try {
      final response = await apiClient.post(ApiEndpoints.itrPreview, data: itr.toJson());
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return null;
  }


  // Get IT-10B statement by return ID
  Future<IT10BRecord?> getIt10bByReturnId(int returnId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.it10bByReturn(returnId));
      if (response.data != null) {
        return IT10BRecord.fromJson(response.data);
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return null;
  }

  // Save or update IT-10B statement
  Future<IT10BRecord?> saveIt10b(IT10BRecord it10b) async {
    _isLoading = true;
    notifyListeners();
    try {
      Response response;
      if (it10b.id != null && it10b.id! > 0) {
        response = await apiClient.put('${ApiEndpoints.it10b}/${it10b.id}', data: it10b.toJson());
      } else {
        response = await apiClient.post(ApiEndpoints.it10b, data: it10b.toJson());
      }
      if (response.data != null) {
        _isLoading = false;
        notifyListeners();
        return IT10BRecord.fromJson(response.data);
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // Update ITR return fields
  Future<ItrRecord?> updateItr(int id, ItrRecord itr) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await apiClient.put('${ApiEndpoints.incomeTaxReturns}/$id', data: itr.toJson());
      if (response.data != null) {
        final updated = ItrRecord.fromJson(response.data);
        final index = _itrs.indexWhere((element) => element.id == id);
        if (index != -1) {
          _itrs[index] = updated;
        }
        _isLoading = false;
        notifyListeners();
        return updated;
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // Patch status transition
  Future<ItrRecord?> patchItrStatus(int id, String status, String remarks, String action) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await apiClient.dio.patch('${ApiEndpoints.incomeTaxReturns}/$id/status', data: {
        'status': status,
        'remarks': remarks,
        'action': action,
      });
      if (response.data != null) {
        final updated = ItrRecord.fromJson(response.data);
        final index = _itrs.indexWhere((element) => element.id == id);
        if (index != -1) {
          _itrs[index] = updated;
        }
        _isLoading = false;
        notifyListeners();
        return updated;
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // Delete ITR return
  Future<bool> deleteItr(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await apiClient.delete('${ApiEndpoints.incomeTaxReturns}/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _itrs.removeWhere((element) => element.id == id);
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

  // Create Business
  Future<bool> createBusiness(Business business) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.businessList, data: business.toJson());
      if (response.data != null) {
        _businesses.insert(0, Business.fromJson(response.data));
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

  // Add AIT record
  Future<bool> createAit(AitRecord ait) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.aitRecords, data: ait.toJson());
      if (response.data != null) {
        _aits.insert(0, AitRecord.fromJson(response.data));
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

  // Submit draft AIT record
  Future<bool> submitAit(int id, String challanNo, String bankName, List<int> documentIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.aitSubmit(id), data: {
        'attachmentIds': documentIds,
        if (challanNo.isNotEmpty) 'challanNumber': challanNo,
        if (bankName.isNotEmpty) 'bankName': bankName,
      });
      if (response.data != null) {
        final idx = _aits.indexWhere((element) => element.id == id);
        if (idx != -1) {
          _aits[idx] = AitRecord.fromJson(response.data);
        }
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

  // Reply/respond to notice
  Future<bool> replyNotice(int noticeId, String replyMsg) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.patch(ApiEndpoints.noticeRespond(noticeId), data: {'responseNote': replyMsg});
      if (response.statusCode == 200) {
        final idx = _notices.indexWhere((n) => n.id == noticeId);
        if (idx != -1) {
          _notices[idx] = Notice.fromJson(response.data);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      _errorMessage = 'Server confirmation unavailable. Refresh before retrying.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Pay challan
  Future<bool> makePayment(Payment payment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.payments, data: payment.toJson());
      if (response.data != null) {
        _payments.insert(0, Payment.fromJson(response.data));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      _errorMessage = 'Server confirmation unavailable. Refresh before retrying.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Fetch outstanding items
  Future<void> loadOutstandingItems(int taxpayerId) async {
    _isLoadingOutstanding = true;
    _outstandingItems = [];
    notifyListeners();

    try {
      final r = await apiClient.get(ApiEndpoints.outstandingPayments(taxpayerId));
      if (r.data != null) {
        _outstandingItems = (r.data as List).map((x) => OutstandingItem.fromJson(x)).toList();
      }
    } catch (e) {
      _errorMessage = 'Could not load outstanding payments.';
    }

    _isLoadingOutstanding = false;
    notifyListeners();
  }


  // Create appeal
  Future<bool> createAppeal(Appeal appeal) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.appealsMy, data: appeal.toJson());
      if (response.data != null) {
        _appeals.insert(0, Appeal.fromJson(response.data));
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

  Future<List<AppealDocument>> getAppealDocuments(int appealId) async {
    if (_appealDocsCache.containsKey(appealId)) {
      return _appealDocsCache[appealId]!;
    }
    try {
      final r = await apiClient.get('/my-portal/appeals/$appealId/documents');
      if (r.data != null) {
        final list = (r.data as List).map((x) => AppealDocument.fromJson(x)).toList();
        _appealDocsCache[appealId] = list;
        return list;
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return [];
  }

  Future<bool> uploadAppealDocument(int appealId, PlatformFile file, String description) async {
    try {
      await apiClient.post('/my-portal/appeals/$appealId/documents', data: FormData.fromMap({
        'file': await documentPart(file), 'description': description,
      }));
      _appealDocsCache.remove(appealId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAppealDocument(int appealId, int docId) async {
    try {
      await apiClient.delete('/my-portal/appeals/$appealId/documents/$docId');
    } catch (_) {
      return false;
    }

    if (_appealDocsCache.containsKey(appealId)) {
      _appealDocsCache[appealId]!.removeWhere((d) => d.id == docId);
      notifyListeners();
    }
    return true;
  }

  Future<bool> withdrawAppeal(int appealId, String reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/my-portal/appeals/$appealId/withdraw',
        data: reason.isNotEmpty ? {'reason': reason} : {},
      );
      if (response.data != null) {
        final idx = _appeals.indexWhere((a) => a.id == appealId);
        if (idx != -1) {
          _appeals[idx] = Appeal.fromJson(response.data);
        }
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

  

  // Audit details helpers
  final Map<int, List<AuditQuery>> _queriesCache = {};
  final Map<int, List<AuditDocumentRequest>> _docsCache = {};
  final Map<int, List<AppealDocument>> _appealDocsCache = {};

  Future<List<AuditQuery>> getQueries(int caseId) async {
    if (_queriesCache.containsKey(caseId)) {
      return _queriesCache[caseId]!;
    }
    try {
      final r = await apiClient.get('/audits/$caseId/queries');
      if (r.data != null) {
        final list = (r.data as List).map((x) => AuditQuery.fromJson(x)).toList();
        _queriesCache[caseId] = list;
        return list;
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return [];
  }

  Future<List<AuditDocumentRequest>> getDocumentRequests(int caseId) async {
    if (_docsCache.containsKey(caseId)) {
      return _docsCache[caseId]!;
    }
    try {
      final r = await apiClient.get('/audits/$caseId/document-requests');
      if (r.data != null) {
        final list = (r.data as List).map((x) => AuditDocumentRequest.fromJson(x)).toList();
        _docsCache[caseId] = list;
        return list;
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return [];
  }

  Future<Assessment?> getMyAssessment(int caseId) async {
    try {
      final r = await apiClient.get('/my-portal/audits/$caseId/assessment');
      if (r.data != null) {
        return Assessment.fromJson(r.data);
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return null;
  }

  Future<DemandNotice?> getMyDemandNotice(int caseId) async {
    try {
      final r = await apiClient.get('/my-portal/audits/$caseId/demand-notice');
      if (r.data != null) {
        return DemandNotice.fromJson(r.data);
      }
    } catch (_) {
      _errorMessage = 'Could not confirm the server response.';
    }
    return null;
  }

  Future<bool> respondToQuery(int caseId, int queryId, String text) async {
    try {
      await apiClient.post('/my-portal/audits/$caseId/respond', data: {
        'queryId': queryId,
        'responseText': text,
      });
      _queriesCache.remove(caseId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadDocumentForRequest(int caseId, int requestId, List<PlatformFile> files, String notes) async {
    try {
      final data = FormData.fromMap({'documentRequestId': requestId, 'description': notes});
      for (final file in files) {
        data.files.add(MapEntry('files', await documentPart(file)));
      }
      await apiClient.post('/my-portal/audits/$caseId/upload-documents', data: data);
      _docsCache.remove(caseId);
      return true;
    } catch (_) {
      return false;
    }
  }

}
