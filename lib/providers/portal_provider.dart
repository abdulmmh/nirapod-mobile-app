import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/api_client.dart';
import '../data/models/portal_records.dart';

class PortalProvider extends ChangeNotifier {
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

  String? _currentTaxpayerName;
  String? _currentTaxpayerTin;

  // Initialize and load all modules for a taxpayer
  Future<void> loadAllData(int taxpayerId, String category, {String? taxpayerName, String? tinNumber}) async {
    _currentTaxpayerName = taxpayerName;
    _currentTaxpayerTin = tinNumber;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch ITR returns
      try {
        final r = await apiClient.get('${ApiEndpoints.incomeTaxReturns}?taxpayerId=$taxpayerId');
        if (r.data != null && (r.data as List).isNotEmpty) {
          _itrs = (r.data as List).map((x) => ItrRecord.fromJson(x)).toList();
        } else {
          _itrs = _getMockItrs(taxpayerId);
        }
      } catch (_) {
        _itrs = _getMockItrs(taxpayerId);
      }

      // 2. Fetch AIT records
      try {
        final r = await apiClient.get('${ApiEndpoints.aitRecords}?taxpayerId=$taxpayerId');
        if (r.data != null && (r.data as List).isNotEmpty) {
          _aits = (r.data as List).map((x) => AitRecord.fromJson(x)).toList();
        } else {
          _aits = _getMockAits(taxpayerId);
        }
      } catch (_) {
        _aits = _getMockAits(taxpayerId);
      }

      // 3. Fetch Businesses
      try {
        final r = await apiClient.get(ApiEndpoints.businessByTaxpayer(taxpayerId));
        if (r.data != null && (r.data as List).isNotEmpty) {
          _businesses = (r.data as List).map((x) => Business.fromJson(x)).toList();
        } else {
          _businesses = _getMockBusinesses(taxpayerId);
        }
      } catch (_) {
        _businesses = _getMockBusinesses(taxpayerId);
      }

      // 4. Fetch Notices
      try {
        final r = await apiClient.get(ApiEndpoints.noticesMy);
        if (r.data != null && (r.data as List).isNotEmpty) {
          _notices = (r.data as List).map((x) => Notice.fromJson(x)).toList();
        } else {
          _notices = _getMockNotices(taxpayerId);
        }
      } catch (_) {
        _notices = _getMockNotices(taxpayerId);
      }

      // 5. Fetch Payments
      try {
        final r = await apiClient.get('${ApiEndpoints.payments}?taxpayerId=$taxpayerId');
        if (r.data != null && (r.data as List).isNotEmpty) {
          _payments = (r.data as List).map((x) => Payment.fromJson(x)).toList();
        } else {
          _payments = _getMockPayments(taxpayerId);
        }
      } catch (_) {
        _payments = _getMockPayments(taxpayerId);
      }

      // 6. Fetch Audits
      try {
        final r = await apiClient.get(ApiEndpoints.auditsMy);
        if (r.data != null && (r.data as List).isNotEmpty) {
          _audits = (r.data as List).map((x) => Audit.fromJson(x)).toList();
        } else {
          _audits = _getMockAudits(taxpayerId);
        }
      } catch (_) {
        _audits = _getMockAudits(taxpayerId);
      }

      // 7. Fetch Appeals
      try {
        final r = await apiClient.get(ApiEndpoints.appealsMy);
        if (r.data != null && (r.data as List).isNotEmpty) {
          _appeals = (r.data as List).map((x) => Appeal.fromJson(x)).toList();
        } else {
          _appeals = _getMockAppeals(taxpayerId);
        }
      } catch (_) {
        _appeals = _getMockAppeals(taxpayerId);
      }

      // 8. Fetch VAT Registrations
      try {
        final r = await apiClient.get('${ApiEndpoints.vatRegistrations}?taxpayerId=$taxpayerId');
        if (r.data != null && (r.data as List).isNotEmpty) {
          _vatRegistrations = (r.data as List).map((x) => VatRegistration.fromJson(x)).toList();
        } else {
          _vatRegistrations = _getMockVatRegistrations(taxpayerId);
        }
      } catch (_) {
        _vatRegistrations = _getMockVatRegistrations(taxpayerId);
      }

      // 9. Fetch VAT Returns
      try {
        final r = await apiClient.get('${ApiEndpoints.vatReturns}?taxpayerId=$taxpayerId');
        if (r.data != null && (r.data as List).isNotEmpty) {
          _vatReturns = (r.data as List).map((x) => VatReturn.fromJson(x)).toList();
        } else {
          _vatReturns = _getMockVatReturns(taxpayerId);
        }
      } catch (_) {
        _vatReturns = _getMockVatReturns(taxpayerId);
      }

    } catch (e) {
      _errorMessage = 'Failed to load details.';
    }

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
      // Offline fallback
      final mockNew = ItrRecord(
        id: _itrs.length + 103,
        taxpayerId: itr.taxpayerId,
        returnNo: itr.returnNo ?? 'ITR-2025-26-${_itrs.length + 1}A',
        tinNumber: itr.tinNumber ?? 'TIN-000000005',
        taxpayerName: itr.taxpayerName ?? 'Tasrif Zaman',
        itrCategory: itr.itrCategory ?? 'Individual',
        assessmentYear: itr.assessmentYear,
        incomeYear: itr.incomeYear ?? '2024-2025',
        returnPeriod: itr.returnPeriod ?? 'Annual',
        grossIncome: itr.grossIncome ?? 0,
        exemptIncome: itr.exemptIncome ?? 0,
        grossTax: itr.grossTax,
        rebate: itr.rebate,
        taxRebate: itr.taxRebate,
        advanceTaxPaid: itr.advanceTaxPaid,
        withholdingTax: itr.withholdingTax,
        taxPaid: itr.taxPaid,
        status: 'Submitted',
        submissionDate: DateTime.now().toIso8601String().substring(0, 10),
        dueDate: itr.dueDate ?? '2025-11-30',
        submittedBy: itr.submittedBy ?? 'Tasrif Zaman',
        actionHistory: [
          ItrAction(
            action: 'Submit',
            fromStatus: 'Draft',
            toStatus: 'Submitted',
            status: 'Submitted',
            performedBy: 'Tasrif Zaman',
            role: 'TAXPAYER',
            performedAt: DateTime.now().toIso8601String().substring(0, 10),
            remarks: 'Submitted via mobile app',
          )
        ],
      );
      _itrs.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Preview ITR calculations
  Future<Map<String, dynamic>?> previewItr(ItrRecord itr) async {
    try {
      final response = await apiClient.post(ApiEndpoints.itrPreview, data: itr.toJson());
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      // Offline tax calculation logic
      final gross = itr.grossIncome ?? 0.0;
      final exempt = itr.exemptIncome ?? 0.0;
      final taxable = MathMax(0.0, gross - exempt);
      // Simulate simple progressive tax slabs
      double calculatedTax = 0.0;
      if (taxable > 350000) {
        double remaining = taxable - 350000;
        if (remaining > 100000) {
          calculatedTax += 100000 * 0.05;
          remaining -= 100000;
          if (remaining > 300000) {
            calculatedTax += 300000 * 0.10;
            remaining -= 300000;
            calculatedTax += remaining * 0.15;
          } else {
            calculatedTax += remaining * 0.10;
          }
        } else {
          calculatedTax += remaining * 0.05;
        }
      }
      return {
        "taxableIncome": taxable,
        "effectiveRatePct": calculatedTax > 0 ? (calculatedTax / taxable) * 100 : 0.0,
        "grossTax": calculatedTax,
      };
    }
    return null;
  }

  double MathMax(double a, double b) => a > b ? a : b;

  // Get IT-10B statement by return ID
  Future<IT10BRecord?> getIt10bByReturnId(int returnId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.it10bByReturn(returnId));
      if (response.data != null) {
        return IT10BRecord.fromJson(response.data);
      }
    } catch (_) {
      // Offline fallback mock statement
      if (returnId == 101 || returnId == 102) {
        return IT10BRecord(
          id: returnId - 100,
          returnId: returnId,
          nonAgriculturalProperty: 2000000.0,
          agriculturalProperty: 500000.0,
          investments: 300000.0,
          motorVehicles: 800000.0,
          bankBalances: 400000.0,
          personalLiabilities: 1000000.0,
          netWealth: 3000000.0,
        );
      }
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
      _isLoading = false;
      notifyListeners();
      return it10b; // mock success for offline
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
      // offline fallback
      final index = _itrs.indexWhere((element) => element.id == id);
      if (index != -1) {
        _itrs[index] = itr;
      }
      _isLoading = false;
      notifyListeners();
      return itr;
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
      // offline simulation
      final index = _itrs.indexWhere((element) => element.id == id);
      if (index != -1) {
        final existing = _itrs[index];
        final updatedHistory = List<ItrAction>.from(existing.actionHistory ?? []);
        updatedHistory.add(ItrAction(
          action: action,
          fromStatus: existing.status,
          toStatus: status,
          status: status,
          performedBy: 'Tasrif Zaman',
          role: 'TAXPAYER',
          performedAt: DateTime.now().toIso8601String().substring(0, 10),
          remarks: remarks,
        ));
        final updated = ItrRecord(
          id: existing.id,
          taxpayerId: existing.taxpayerId,
          returnNo: existing.returnNo,
          tinNumber: existing.tinNumber,
          userId: existing.userId,
          taxpayerName: existing.taxpayerName,
          itrCategory: existing.itrCategory,
          companySubType: existing.companySubType,
          assessmentYear: existing.assessmentYear,
          incomeYear: existing.incomeYear,
          returnPeriod: existing.returnPeriod,
          grossIncome: existing.grossIncome,
          exemptIncome: existing.exemptIncome,
          rebate: existing.rebate,
          taxRebate: existing.taxRebate,
          advanceTaxPaid: existing.advanceTaxPaid,
          withholdingTax: existing.withholdingTax,
          taxPaid: existing.taxPaid,
          taxRate: existing.taxRate,
          grossTax: existing.grossTax,
          status: status,
          submissionDate: existing.submissionDate,
          dueDate: existing.dueDate,
          submittedBy: existing.submittedBy,
          remarks: remarks,
          actionHistory: updatedHistory,
        );
        _itrs[index] = updated;
        _isLoading = false;
        notifyListeners();
        return updated;
      }
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
      _itrs.removeWhere((element) => element.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
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
      final mockNew = Business(
        id: _businesses.length + 301,
        name: business.name,
        tradeLicenseNo: business.tradeLicenseNo,
        vatStatus: 'Active',
        address: business.address,
        ownerName: business.ownerName ?? 'Abdul Karim',
        tinNumber: business.tinNumber ?? '102345678912',
        businessType: business.businessType ?? 'Software Development',
        businessCategory: business.businessCategory ?? 'IT & ITES',
        email: business.email ?? 'tech@karim.com',
        phone: business.phone ?? '01712345678',
        division: business.division ?? 'Dhaka',
        district: business.district ?? 'Dhaka',
        incorporationDate: business.incorporationDate ?? '2026-01-10',
        registrationDate: business.registrationDate ?? '2026-03-01',
        expiryDate: business.expiryDate ?? '2027-03-01',
        annualTurnover: business.annualTurnover ?? 1500000.0,
        numberOfEmployees: business.numberOfEmployees ?? 10,
        remarks: business.remarks,
      );
      _businesses.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
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
      final mockNew = AitRecord(
        id: _aits.length + 1,
        taxpayerId: ait.taxpayerId,
        amount: ait.amount,
        source: ait.source,
        challanNo: ait.challanNo,
        date: DateTime.now().toIso8601String().substring(0, 10),
        status: 'Pending',
      );
      _aits.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Submit draft AIT record
  Future<bool> submitAit(int id, String challanNo) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.aitSubmit(id), data: {
        'challanNo': challanNo,
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
      final idx = _aits.indexWhere((element) => element.id == id);
      if (idx != -1) {
        final old = _aits[idx];
        _aits[idx] = AitRecord(
          id: old.id,
          taxpayerId: old.taxpayerId,
          amount: old.amount,
          source: old.source,
          challanNo: challanNo,
          date: old.date,
          status: 'Submitted',
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
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
          _notices[idx] = Notice(
            id: noticeId,
            title: _notices[idx].title,
            message: _notices[idx].message,
            status: 'Responded',
            date: _notices[idx].date,
            noticeType: _notices[idx].noticeType,
            replyMessage: replyMsg,
            replyDate: DateTime.now().toIso8601String().substring(0, 10),
            noticeNo: _notices[idx].noticeNo,
            priority: _notices[idx].priority,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {
      final idx = _notices.indexWhere((n) => n.id == noticeId);
      if (idx != -1) {
        _notices[idx] = Notice(
          id: noticeId,
          title: _notices[idx].title,
          message: _notices[idx].message,
          status: 'Responded',
          date: _notices[idx].date,
          noticeType: _notices[idx].noticeType,
          replyMessage: replyMsg,
          replyDate: DateTime.now().toIso8601String().substring(0, 10),
          noticeNo: _notices[idx].noticeNo,
          priority: _notices[idx].priority,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
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
      final mockNew = Payment(
        id: _payments.length + 1,
        challanNo: payment.challanNo,
        amount: payment.amount,
        status: 'Success',
        date: DateTime.now().toIso8601String().substring(0, 10),
        paymentType: payment.paymentType,
      );
      _payments.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
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
      print('Failed to load outstanding items, using offline fallback: $e');
      _outstandingItems = _getMockOutstandingItems(taxpayerId);
    }

    _isLoadingOutstanding = false;
    notifyListeners();
  }

  List<OutstandingItem> _getMockOutstandingItems(int taxpayerId) {
    return [
      OutstandingItem(
        type: 'VAT',
        returnNo: 'VAT-2026-06-0001',
        label: 'VAT Return — June 2026',
        totalDue: 15000.0,
        alreadyPaid: 0.0,
        outstanding: 15000.0,
        dueDate: '2026-06-15',
        status: 'Submitted',
        overdue: true,
      ),
      OutstandingItem(
        type: 'Income Tax',
        returnNo: 'ITR-2025-26-5E1D4ACB',
        label: 'Income Tax Return — AY 2025-2026',
        totalDue: 55000.0,
        alreadyPaid: 20000.0,
        outstanding: 35000.0,
        dueDate: '2026-11-30',
        status: 'Submitted',
        overdue: false,
      ),
      OutstandingItem(
        type: 'Penalty',
        returnNo: 'PN-2026-092',
        label: 'Late Filing Penalty — PN-2026-092',
        totalDue: 5000.0,
        alreadyPaid: 0.0,
        outstanding: 5000.0,
        dueDate: '2026-06-20',
        status: 'Unpaid',
        overdue: true,
      ),
    ];
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
      final mockNew = Appeal(
        id: _appeals.length + 700,
        taxpayerId: appeal.taxpayerId,
        caseNo: appeal.caseNo,
        status: 'Filed',
        description: appeal.description ?? appeal.groundsText,
        appealNo: appeal.appealNo ?? 'APPEAL-${DateTime.now().year}-${100 + _appeals.length}',
        demandedAmount: appeal.demandedAmount,
        disputedAmount: appeal.disputedAmount,
        acceptedAmount: appeal.acceptedAmount ?? 0.0,
        reliefGranted: appeal.reliefGranted ?? 0.0,
        groundsText: appeal.groundsText ?? appeal.description,
        reliefSought: appeal.reliefSought,
        filedAt: appeal.filedAt ?? DateTime.now().toIso8601String().substring(0, 10),
        deadline: appeal.deadline ?? DateTime.now().add(const Duration(days: 45)).toIso8601String().substring(0, 10),
        hearingDate: 'TBD',
      );
      _appeals.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
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
    } catch (_) {}

    // Fallback to empty mock list by default
    _appealDocsCache[appealId] = [];
    return [];
  }

  Future<bool> uploadAppealDocument(int appealId, String filename, String description) async {
    try {
      await apiClient.post('/my-portal/appeals/$appealId/documents', data: {
        'fileName': filename,
        'description': description,
      });
    } catch (_) {}

    // Update locally in mock cache
    if (!_appealDocsCache.containsKey(appealId)) {
      _appealDocsCache[appealId] = [];
    }
    final newDoc = AppealDocument(
      id: _appealDocsCache[appealId]!.length + 1,
      appealId: appealId,
      originalFileName: filename,
      description: description.isNotEmpty ? description : null,
      fileSize: 1024 * 342, // Mock 342 KB
      fileType: filename.split('.').last.toLowerCase(),
      uploadedBy: _currentTaxpayerName ?? 'Tasrif Zaman',
      uploadedByName: _currentTaxpayerName ?? 'Tasrif Zaman',
      uploadedAt: DateTime.now().toIso8601String().substring(0, 10),
    );
    _appealDocsCache[appealId]!.insert(0, newDoc);
    notifyListeners();
    return true;
  }

  Future<bool> deleteAppealDocument(int appealId, int docId) async {
    try {
      await apiClient.delete('/my-portal/appeals/$appealId/documents/$docId');
    } catch (_) {}

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
    } catch (_) {}

    // Fallback/offline mock update
    final idx = _appeals.indexWhere((a) => a.id == appealId);
    if (idx != -1) {
      final old = _appeals[idx];
      _appeals[idx] = Appeal(
        id: old.id,
        taxpayerId: old.taxpayerId,
        caseNo: old.caseNo,
        status: 'WITHDRAWN',
        description: old.description,
        appealNo: old.appealNo,
        demandedAmount: old.demandedAmount,
        disputedAmount: old.disputedAmount,
        acceptedAmount: 0.0,
        reliefGranted: 0.0,
        groundsText: old.groundsText,
        reliefSought: old.reliefSought,
        supportingEvidence: old.supportingEvidence,
        filedAt: old.filedAt,
        deadline: old.deadline,
        decidedAt: old.decidedAt,
        decidedBy: old.decidedBy,
        decision: old.decision,
        decisionNotes: old.decisionNotes,
        demandNo: old.demandNo,
      );
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Offline Mock Data Generators ─────────────────────────────────
  
  List<ItrRecord> _getMockItrs(int tpId) {
    final String targetName = _currentTaxpayerName ?? 'Tasrif Zaman';
    final String targetTin = _currentTaxpayerTin ?? 'TIN-000000005';
    return [
      ItrRecord(
        id: 101,
        taxpayerId: tpId,
        returnNo: 'ITR-2025-26-5E1D4ACB',
        tinNumber: targetTin,
        userId: 1,
        taxpayerName: targetName,
        itrCategory: 'Individual',
        assessmentYear: '2025-2026',
        incomeYear: '2024-2025',
        returnPeriod: 'Annual',
        grossIncome: 1200000.0,
        exemptIncome: 200000.0,
        rebate: 15000.0,
        taxRebate: 15000.0,
        advanceTaxPaid: 15000.0,
        withholdingTax: 5000.0,
        taxPaid: 20000.0,
        taxRate: 10.0,
        grossTax: 55000.0,
        status: 'Accepted',
        submissionDate: '2025-11-15',
        dueDate: '2025-11-30',
        submittedBy: targetName,
        remarks: 'Tax Return filed online',
        actionHistory: [
          ItrAction(
            action: 'Submit',
            fromStatus: 'Draft',
            toStatus: 'Submitted',
            status: 'Submitted',
            performedBy: targetName,
            role: 'TAXPAYER',
            performedAt: '2025-11-15 10:30 AM',
            remarks: 'Filing completed',
          ),
          ItrAction(
            action: 'Start Review',
            fromStatus: 'Submitted',
            toStatus: 'Under Review',
            status: 'Under Review',
            performedBy: 'Mr. Selim',
            role: 'TAX_OFFICER',
            performedAt: '2025-11-16 02:15 PM',
          ),
          ItrAction(
            action: 'Accept',
            fromStatus: 'Under Review',
            toStatus: 'Accepted',
            status: 'Accepted',
            performedBy: 'Commissioner Rahman',
            role: 'TAX_COMMISSIONER',
            performedAt: '2025-11-18 11:00 AM',
            remarks: 'All documents verified and accepted',
          )
        ],
      ),
      ItrRecord(
        id: 102,
        taxpayerId: tpId,
        returnNo: 'ITR-2024-25-A3DF928C',
        tinNumber: targetTin,
        userId: 1,
        taxpayerName: targetName,
        itrCategory: 'Individual',
        assessmentYear: '2024-2025',
        incomeYear: '2023-2024',
        returnPeriod: 'Annual',
        grossIncome: 1000000.0,
        exemptIncome: 150000.0,
        rebate: 12000.0,
        taxRebate: 12000.0,
        advanceTaxPaid: 10000.0,
        withholdingTax: 4000.0,
        taxPaid: 15000.0,
        taxRate: 9.5,
        grossTax: 41000.0,
        status: 'Accepted',
        submissionDate: '2024-11-20',
        dueDate: '2024-11-30',
        submittedBy: targetName,
        remarks: 'Previous year tax returns',
        actionHistory: [
          ItrAction(
            action: 'Submit',
            fromStatus: 'Draft',
            toStatus: 'Submitted',
            status: 'Submitted',
            performedBy: targetName,
            role: 'TAXPAYER',
            performedAt: '2024-11-20 11:15 AM',
          ),
          ItrAction(
            action: 'Accept',
            fromStatus: 'Submitted',
            toStatus: 'Accepted',
            status: 'Accepted',
            performedBy: 'Tax Officer Amin',
            role: 'TAX_OFFICER',
            performedAt: '2024-11-25 04:00 PM',
          )
        ],
      ),
    ];
  }

  List<AitRecord> _getMockAits(int tpId) {
    return [
      AitRecord(
        id: 201,
        taxpayerId: tpId,
        amount: 8500.0,
        source: 'Bank Interest',
        challanNo: 'CH-89754B',
        date: '2026-03-10',
        status: 'Verified',
      ),
      AitRecord(
        id: 202,
        taxpayerId: tpId,
        amount: 15000.0,
        source: 'Vehicle Registration',
        challanNo: 'CH-90875X',
        date: '2026-05-18',
        status: 'Pending',
      ),
    ];
  }

  List<Business> _getMockBusinesses(int tpId) {
    return [
      Business(
        id: 301,
        name: 'Garments Apparel',
        tradeLicenseNo: 'TL-23456-2026',
        vatStatus: 'Active',
        address: 'Puran Dhaka, Lalbagh, Dhaka',
        ownerName: 'Tasrif Zaman',
        tinNumber: 'TIN-000000005',
        businessType: 'Textile Manufacturing',
        businessCategory: 'Garments & Textile',
        email: 'abdul2mannan9@gmail.com',
        phone: '01820318364',
        division: 'Dhaka',
        district: 'Dhaka',
        incorporationDate: '2026-02-25',
        registrationDate: '2026-05-12',
        expiryDate: '2026-05-30',
        annualTurnover: 3009300000.0,
        numberOfEmployees: 200,
        remarks: 'Mock business imported from web version.',
      ),
      Business(
        id: 302,
        name: 'Karim Agro Industries',
        tradeLicenseNo: 'TRAD/DNCC/12304/2024',
        vatStatus: 'Pending',
        address: 'H-10, Block C, Uttara, Dhaka',
        ownerName: 'Abdul Karim',
        tinNumber: '102345678912',
        businessType: 'Agribusiness',
        businessCategory: 'Agriculture',
        email: 'agro@karim.com',
        phone: '01812345678',
        division: 'Dhaka',
        district: 'Dhaka',
        incorporationDate: '2024-05-15',
        registrationDate: '2024-06-01',
        expiryDate: '2025-06-01',
        annualTurnover: 85000000.0,
        numberOfEmployees: 45,
        remarks: 'Secondary business structure.',
      ),
    ];
  }

  List<Notice> _getMockNotices(int tpId) {
    return [
      Notice(
        id: 401,
        noticeNo: 'NTC-7F21C92D',
        title: 'Action Required: Upload Documents — AIT-202526-DF51CDEB',
        message: 'Your AIT record AIT-202526-DF51CDEB has been created. Please upload the required supporting documents before submitting. Submission is not allowed unless at least one document has been uploaded.',
        status: 'Unread',
        date: '2026-06-23',
        noticeType: 'Specific Taxpayer',
        priority: 'High',
      ),
      Notice(
        id: 402,
        noticeNo: 'NTC-283CF8F3',
        title: 'Payment Received — TXN-DB6ED4F9E9FD',
        message: 'Your Income Tax payment of ৳57,500 (TXN: TXN-DB6ED4F9E9FD) has been received and is awaiting officer review. Status: Pending Officer Remarks: Paid For queries, contact NBR Helpdesk: 16579',
        status: 'Unread',
        date: '2026-06-23',
        noticeType: 'Specific Taxpayer',
        priority: 'Normal',
      ),
      Notice(
        id: 403,
        noticeNo: 'NTC-D82CBB12',
        title: 'AIT Approved ✓ — AIT-202526-BB07CE18',
        message: 'Your AIT record AIT-202526-BB07CE18 has been approved. Please wait for credit posting.',
        status: 'Responded',
        date: '2026-06-15',
        noticeType: 'Specific Taxpayer',
        priority: 'High',
        replyMessage: 'Response submitted: Document uploads completed.',
        replyDate: '2026-06-16',
      ),
      Notice(
        id: 404,
        noticeNo: 'NTC-DA775CA7',
        title: 'Action Required: Upload Documents — AIT-202526-497333FD',
        message: 'Your AIT record AIT-202526-497333FD has been created. Please upload the required supporting documents before submitting. Submission is not allowed unless at least one document has been uploaded.',
        status: 'Unread',
        date: '2026-06-23',
        noticeType: 'Specific Taxpayer',
        priority: 'High',
      ),
      Notice(
        id: 405,
        noticeNo: 'NTC-219A4C0B',
        title: 'Action Required: Upload Documents — AIT-202526-EDED5D65',
        message: 'Your AIT record AIT-202526-EDED5D65 has been created. Please upload the required supporting documents before submitting. Submission is not allowed unless at least one document has been uploaded.',
        status: 'Unread',
        date: '2026-06-23',
        noticeType: 'Specific Taxpayer',
        priority: 'High',
      ),
      Notice(
        id: 406,
        noticeNo: 'NTC-8F12A7B5',
        title: 'System Update — Secure Login Features Active',
        message: 'National Board of Revenue portal has updated its login protocols. Dual-factor authentication is now active for all individual taxpayer classes.',
        status: 'Read',
        date: '2026-05-10',
        noticeType: 'System',
        priority: 'Normal',
      ),
      Notice(
        id: 407,
        noticeNo: 'NTC-9C12E5F2',
        title: 'Discrepancy Clarification — FY 2024-25 Return',
        message: 'Discrepancies were noted in your declared investment rebate documents. Please upload copy of DPS certificate to resolve this issue within 7 days.',
        status: 'Unread',
        date: '2026-06-24',
        noticeType: 'Discrepancy',
        priority: 'Normal',
      ),
    ];
  }

  List<Payment> _getMockPayments(int tpId) {
    return [
      Payment(
        id: 501,
        challanNo: 'PL-3829019',
        amount: 20000.0,
        date: '2025-11-15',
        status: 'Success',
        paymentType: 'Income Tax Return Pay',
      ),
      Payment(
        id: 502,
        challanNo: 'PL-2983719',
        amount: 8500.0,
        date: '2026-03-10',
        status: 'Success',
        paymentType: 'Advance Income Tax',
      ),
    ];
  }

  List<Audit> _getMockAudits(int tpId) {
    return [
      Audit(
        id: 601,
        taxpayerId: tpId,
        year: '2024-2025',
        status: 'DOCUMENT_REQUESTED',
        description: 'Discrepancy found in Bank credits vs declared earnings.',
        demandAmount: 0.0,
        caseNo: 'AUD-2026-8A3B2C1D',
        auditType: 'DESK',
        taxType: 'INCOME_TAX',
        fiscalYear: '2024-2025',
        taxPeriodStart: '2024-07-01',
        taxPeriodEnd: '2025-06-30',
        triggerReason: 'RISK_BASED',
        riskScore: 78,
        priority: 'HIGH',
        assignedOfficerName: 'Assraful Islam',
        supervisorName: 'Zamil Hossain',
        dueDate: '2026-08-15',
        createdAt: '2026-06-10',
        queryCount: 1,
        openQueryCount: 1,
        documentRequestCount: 1,
      ),
      Audit(
        id: 602,
        taxpayerId: tpId,
        year: '2025-2026',
        status: 'DEMAND_ISSUED',
        description: 'Mismatched investment rebate document calculations.',
        demandAmount: 3720400.00,
        caseNo: 'AUD-2026-9F8E7D6C',
        auditType: 'COMPREHENSIVE',
        taxType: 'INCOME_TAX',
        fiscalYear: '2025-2026',
        taxPeriodStart: '2025-07-01',
        taxPeriodEnd: '2026-06-30',
        triggerReason: 'MISMATCH',
        riskScore: 92,
        priority: 'CRITICAL',
        assignedOfficerName: 'Mahbubur Rahman',
        supervisorName: 'Zamil Hossain',
        dueDate: '2026-07-25',
        createdAt: '2026-05-15',
        queryCount: 1,
        openQueryCount: 0,
        hasAssessment: true,
        hasDemandNotice: true,
      ),
    ];
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
    } catch (_) {}

    // Fallback to mocks
    List<AuditQuery> mocks = [];
    if (caseId == 601) {
      mocks = [
        AuditQuery(
          id: 901,
          auditCaseId: 601,
          queryNo: 'QRY-2026-001',
          subject: 'Discrepancy in Bank Credits',
          queryText: 'We noticed bank transactions of BDT 1,200,000 on Nov 12, 2024, which were not declared in your return. Please explain and provide bank statement.',
          queryType: 'Income Verification',
          raisedBy: 'Assraful Islam',
          raisedAt: '2026-06-12',
          deadline: '2026-07-20',
          status: 'OPEN',
        ),
      ];
    } else if (caseId == 602) {
      mocks = [
        AuditQuery(
          id: 902,
          auditCaseId: 602,
          queryNo: 'QRY-2026-002',
          subject: 'Form-16 Verification',
          queryText: 'Provide copy of Form-16 from employer for verification of tax deducted at source.',
          queryType: 'TDS Verification',
          raisedBy: 'Mahbubur Rahman',
          raisedAt: '2026-05-18',
          deadline: '2026-06-15',
          status: 'RESPONDED',
          responseText: 'Attached Form-16 as requested. Income is fully declared.',
          respondedBy: 'Mahadi',
          respondedAt: '2026-06-01',
        ),
      ];
    }
    _queriesCache[caseId] = mocks;
    return mocks;
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
    } catch (_) {}

    // Fallback to mocks
    List<AuditDocumentRequest> mocks = [];
    if (caseId == 601) {
      mocks = [
        AuditDocumentRequest(
          id: 801,
          auditCaseId: 601,
          requestNo: 'REQ-2026-001',
          requestedDocuments: 'Bank Statements for FY 2024-25',
          requestReason: 'To verify credit entries and declared income',
          requestType: 'Bank Records',
          requestedBy: 'Assraful Islam',
          requestedAt: '2026-06-12',
          deadline: '2026-07-20',
          status: 'PENDING',
        ),
      ];
    }
    _docsCache[caseId] = mocks;
    return mocks;
  }

  Future<Assessment?> getMyAssessment(int caseId) async {
    try {
      final r = await apiClient.get('/my-portal/audits/$caseId/assessment');
      if (r.data != null) {
        return Assessment.fromJson(r.data);
      }
    } catch (_) {}

    if (caseId == 602) {
      return Assessment(
        id: 702,
        auditCaseId: 602,
        caseNo: 'AUD-2026-9F8E7D6C',
        assessmentNo: 'ASM-2026-88711A',
        taxpayerId: 1,
        tinNumber: '539820193829',
        taxpayerName: 'Mahadi Hasan',
        fiscalYear: '2025-2026',
        taxType: 'INCOME_TAX',
        declaredIncome: 5000000.00,
        assessedIncome: 5050000.00,
        declaredTax: 150000.00,
        assessedTax: 165000.00,
        additionalTax: 15000.00,
        penaltyRate: 10.0,
        penaltyAmount: 1500.00,
        interestRate: 1.0,
        interestMonths: 6,
        interestAmount: 900.00,
        totalDemand: 3720400.00,
        amountPaid: 0.0,
        balanceDue: 3720400.00,
        findingsSummary: 'Salary receipts and family transfers verified. Discrepancy found in taxable credits.',
        legalBasis: 'Section 16(2) of Income Tax Ordinance 1984',
        appealRights: 'You can file a legal appeal within 45 days of receipt of this notice.',
        paymentDeadline: '2026-07-25',
        status: 'APPROVED',
        approvedBy: 'Zamil Hossain',
        approvedAt: '2026-06-16',
        hasDemandNotice: true,
        demandNo: 'DEM-2026-1395958B',
      );
    }
    return null;
  }

  Future<DemandNotice?> getMyDemandNotice(int caseId) async {
    try {
      final r = await apiClient.get('/my-portal/audits/$caseId/demand-notice');
      if (r.data != null) {
        return DemandNotice.fromJson(r.data);
      }
    } catch (_) {}

    if (caseId == 602) {
      return DemandNotice(
        id: 505,
        demandNo: 'DEM-2026-1395958B',
        assessmentId: 702,
        assessmentNo: 'ASM-2026-88711A',
        auditCaseId: 602,
        taxpayerId: 1,
        tinNumber: '539820193829',
        taxpayerName: 'Mahadi Hasan',
        amountDue: 3720400.00,
        dueDate: '2026-07-25',
        paymentInstructions: 'Please pay the outstanding demand via Sonali Bank e-Payment portal or NBR mobile banking gateways.',
        issuedBy: 'Zamil Hossain',
        issuedAt: '2026-06-16',
        status: 'ISSUED',
      );
    }
    return null;
  }

  Future<bool> respondToQuery(int caseId, int queryId, String text) async {
    try {
      await apiClient.post('/my-portal/audits/$caseId/respond', data: {
        'queryId': queryId,
        'responseText': text,
      });
    } catch (_) {}

    // Update locally in mock cache
    if (_queriesCache.containsKey(caseId)) {
      final list = _queriesCache[caseId]!;
      final idx = list.indexWhere((q) => q.id == queryId);
      if (idx != -1) {
        final old = list[idx];
        list[idx] = AuditQuery(
          id: old.id,
          auditCaseId: old.auditCaseId,
          queryNo: old.queryNo,
          subject: old.subject,
          queryText: old.queryText,
          queryType: old.queryType,
          raisedBy: old.raisedBy,
          raisedAt: old.raisedAt,
          status: 'RESPONDED',
          responseText: text,
          respondedBy: 'Self',
          respondedAt: DateTime.now().toIso8601String().split('T').first,
        );
      }
    }
    notifyListeners();
    return true;
  }

  Future<bool> uploadDocumentForRequest(int caseId, int requestId, String notes) async {
    try {
      await apiClient.post('/my-portal/audits/$caseId/respond', data: {
        'documentRequestId': requestId,
        'responseText': notes,
      });
    } catch (_) {}

    // Update locally in mock cache
    if (_docsCache.containsKey(caseId)) {
      final list = _docsCache[caseId]!;
      final idx = list.indexWhere((d) => d.id == requestId);
      if (idx != -1) {
        final old = list[idx];
        list[idx] = AuditDocumentRequest(
          id: old.id,
          auditCaseId: old.auditCaseId,
          requestNo: old.requestNo,
          requestedDocuments: old.requestedDocuments,
          requestReason: old.requestReason,
          requestType: old.requestType,
          requestedBy: old.requestedBy,
          requestedAt: old.requestedAt,
          status: 'FULFILLED',
          fulfillmentNotes: notes,
        );
      }
    }
    notifyListeners();
    return true;
  }

  List<Appeal> _getMockAppeals(int tpId) {
    return [
      Appeal(
        id: 1,
        taxpayerId: tpId,
        appealNo: 'APPEAL-2026-65722DAE',
        caseNo: 'APPEAL-2026-65722DAE',
        status: 'CLOSED',
        demandedAmount: 3720400.00,
        disputedAmount: 50000.00,
        reliefGranted: 25000.00,
        acceptedAmount: 25000.00,
        filedAt: '2026-06-16',
        deadline: '2026-07-31',
        groundsText: 'The assessment has included salary receipts as income which are already taxed at source. The declared income of BDT 5,000,000 is correct as per Form-16. Bank credits include family transfers which are not taxable under ITO 1984 Section 16(2). I request full cancellation of the demand.',
        description: 'The assessment has included salary receipts as income which are already taxed at source. The declared income of BDT 5,000,000 is correct as per Form-16. Bank credits include family transfers which are not taxable under ITO 1984 Section 16(2). I request full cancellation of the demand.',
        reliefSought: 'Full cancellation of demand notice DEM-2026-1395958B',
        decision: 'PARTIALLY UPHELD',
        decidedBy: 'Tax Commissioner',
        decidedAt: '2026-06-16',
        decisionNotes: 'After reviewing bank statements, BDT 25,000 represents non-taxable family transfers. Partial relief granted accordingly.',
        demandNo: 'DEM-2026-1395958B',
      ),
      Appeal(
        id: 701,
        taxpayerId: tpId,
        appealNo: 'APP/2026/089',
        caseNo: 'APP/2026/089',
        status: 'Hearing Scheduled',
        demandedAmount: 100000.00,
        disputedAmount: 100000.00,
        reliefGranted: 0.0,
        acceptedAmount: 0.0,
        filedAt: '2026-05-12',
        deadline: '2026-08-30',
        groundsText: 'Appeal against penalty issued for delay in filing income tax return. Ground: Taxpayer was hospitalized during filing period.',
        description: 'Appeal against penalty issued for delay in filing income tax return. Ground: Taxpayer was hospitalized during filing period.',
        hearingDate: '2026-07-20 11:30 AM',
      ),
    ];
  }

  List<VatRegistration> _getMockVatRegistrations(int tpId) {
    final String targetName = _currentTaxpayerName ?? 'Tasrif Zaman';
    return [
      VatRegistration(
        id: 401,
        binNo: '001234567-0101',
        businessName: 'Garments Apparel',
        ownerName: targetName,
        vatCategory: 'Manufacturer',
        businessType: 'Textile Manufacturing',
        businessCategory: 'Garments & Textile',
        tradeLicenseNo: 'TL-23456-2026',
        vatZone: 'Zone-05, Dhaka',
        vatCircle: 'Circle-A, Lalbagh',
        registrationDate: '2026-05-12',
        effectiveDate: '2026-05-15',
        returnPeriod: 'Monthly',
        expiryDate: '2027-05-15',
        annualTurnover: 3009300000.0,
        email: 'abdul2mannan9@gmail.com',
        phone: '01820318364',
        address: 'Puran Dhaka, Lalbagh, Dhaka',
        district: 'Dhaka',
        division: 'Dhaka',
        status: 'Active',
        remarks: 'Active VAT Registration.',
      ),
      VatRegistration(
        id: 402,
        binNo: '009876543-0202',
        businessName: 'Karim Agro Industries',
        ownerName: 'Abdul Karim',
        vatCategory: 'Service Provider',
        businessType: 'Agribusiness',
        businessCategory: 'Agriculture',
        tradeLicenseNo: 'TRAD/DNCC/12304/2024',
        vatZone: 'Zone-03, Dhaka',
        vatCircle: 'Circle-C, Uttara',
        registrationDate: '2024-06-01',
        effectiveDate: '2024-06-05',
        returnPeriod: 'Monthly',
        expiryDate: '2025-06-05',
        annualTurnover: 85000000.0,
        email: 'agro@karim.com',
        phone: '01812345678',
        address: 'H-10, Block C, Uttara, Dhaka',
        district: 'Dhaka',
        division: 'Dhaka',
        status: 'Pending',
        remarks: 'Secondary VAT Registration.',
      ),
    ];
  }

  List<VatReturn> _getMockVatReturns(int tpId) {
    final String targetName = _currentTaxpayerName ?? 'Tasrif Zaman';
    final String targetTin = _currentTaxpayerTin ?? 'TIN-000000005';
    return [
      VatReturn(
        id: 501,
        returnNo: 'VR-2026-06-0001',
        binNo: '001234567-0101',
        tinNumber: targetTin,
        businessName: 'Garments Apparel',
        returnPeriod: 'Monthly',
        periodMonth: 'June',
        periodYear: '2026',
        assessmentYear: '2026-2027',
        taxableSupplies: 1200000.0,
        exemptSupplies: 150000.0,
        zeroRatedSupplies: 50000.0,
        totalSupplies: 1400000.0,
        outputTax: 180000.0,
        inputTax: 105000.0,
        netTaxPayable: 75000.0,
        taxPaid: 75000.0,
        submissionDate: '2026-07-10',
        dueDate: '2026-07-15',
        status: 'Submitted',
        submittedBy: targetName,
        submittedAt: '2026-07-10T11:30:00',
        remarks: 'Regular monthly VAT return submission.',
      ),
      VatReturn(
        id: 502,
        returnNo: 'VR-2026-05-0002',
        binNo: '001234567-0101',
        tinNumber: targetTin,
        businessName: 'Garments Apparel',
        returnPeriod: 'Monthly',
        periodMonth: 'May',
        periodYear: '2026',
        assessmentYear: '2026-2027',
        taxableSupplies: 980000.0,
        exemptSupplies: 120000.0,
        zeroRatedSupplies: 40000.0,
        totalSupplies: 1140000.0,
        outputTax: 147000.0,
        inputTax: 92000.0,
        netTaxPayable: 55000.0,
        taxPaid: 55000.0,
        submissionDate: '2026-06-12',
        dueDate: '2026-06-15',
        status: 'Accepted',
        submittedBy: targetName,
        submittedAt: '2026-06-12T10:15:00',
        remarks: 'Regular monthly VAT return submission.',
      ),
    ];
  }
}
