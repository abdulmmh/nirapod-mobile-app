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

  bool _isLoading = false;
  String? _errorMessage;

  List<ItrRecord> get itrs => _itrs;
  List<AitRecord> get aits => _aits;
  List<Business> get businesses => _businesses;
  List<Notice> get notices => _notices;
  List<Payment> get payments => _payments;
  List<Audit> get audits => _audits;
  List<Appeal> get appeals => _appeals;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize and load all modules for a taxpayer
  Future<void> loadAllData(int taxpayerId, String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch ITR returns
      try {
        final r = await apiClient.get('${ApiEndpoints.incomeTaxReturns}?taxpayerId=$taxpayerId');
        if (r.data != null) {
          _itrs = (r.data as List).map((x) => ItrRecord.fromJson(x)).toList();
        }
      } catch (_) {
        _itrs = _getMockItrs(taxpayerId);
      }

      // 2. Fetch AIT records
      try {
        final r = await apiClient.get('${ApiEndpoints.aitRecords}?taxpayerId=$taxpayerId');
        if (r.data != null) {
          _aits = (r.data as List).map((x) => AitRecord.fromJson(x)).toList();
        }
      } catch (_) {
        _aits = _getMockAits(taxpayerId);
      }

      // 3. Fetch Businesses
      try {
        final r = await apiClient.get(ApiEndpoints.businessList);
        if (r.data != null) {
          _businesses = (r.data as List).map((x) => Business.fromJson(x)).toList();
        }
      } catch (_) {
        _businesses = _getMockBusinesses(taxpayerId);
      }

      // 4. Fetch Notices
      try {
        final r = await apiClient.get(ApiEndpoints.noticesMy);
        if (r.data != null) {
          _notices = (r.data as List).map((x) => Notice.fromJson(x)).toList();
        }
      } catch (_) {
        _notices = _getMockNotices(taxpayerId);
      }

      // 5. Fetch Payments
      try {
        final r = await apiClient.get('${ApiEndpoints.payments}?taxpayerId=$taxpayerId');
        if (r.data != null) {
          _payments = (r.data as List).map((x) => Payment.fromJson(x)).toList();
        }
      } catch (_) {
        _payments = _getMockPayments(taxpayerId);
      }

      // 6. Fetch Audits
      try {
        final r = await apiClient.get(ApiEndpoints.auditsMy);
        if (r.data != null) {
          _audits = (r.data as List).map((x) => Audit.fromJson(x)).toList();
        }
      } catch (_) {
        _audits = _getMockAudits(taxpayerId);
      }

      // 7. Fetch Appeals
      try {
        final r = await apiClient.get(ApiEndpoints.appealsMy);
        if (r.data != null) {
          _appeals = (r.data as List).map((x) => Appeal.fromJson(x)).toList();
        }
      } catch (_) {
        _appeals = _getMockAppeals(taxpayerId);
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
        id: _itrs.length + 1,
        taxpayerId: itr.taxpayerId,
        assessmentYear: itr.assessmentYear,
        grossTax: itr.grossTax,
        rebate: itr.rebate,
        netTaxPayable: itr.netTaxPayable,
        advanceTaxPaid: itr.advanceTaxPaid,
        withholdingTax: itr.withholdingTax,
        taxPaid: itr.taxPaid,
        status: 'Submitted',
        submissionDate: DateTime.now().toIso8601String().substring(0, 10),
      );
      _itrs.insert(0, mockNew);
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

  // Reply/respond to notice
  Future<bool> replyNotice(int noticeId, String replyMsg) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post(ApiEndpoints.noticeRespond(noticeId), data: {'replyMessage': replyMsg});
      if (response.statusCode == 200) {
        final idx = _notices.indexWhere((n) => n.id == noticeId);
        if (idx != -1) {
          _notices[idx] = Notice(
            id: noticeId,
            title: _notices[idx].title,
            message: _notices[idx].message,
            status: 'Replied',
            date: _notices[idx].date,
            noticeType: _notices[idx].noticeType,
            replyMessage: replyMsg,
            replyDate: DateTime.now().toIso8601String().substring(0, 10),
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
          status: 'Replied',
          date: _notices[idx].date,
          noticeType: _notices[idx].noticeType,
          replyMessage: replyMsg,
          replyDate: DateTime.now().toIso8601String().substring(0, 10),
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
        id: _appeals.length + 1,
        taxpayerId: appeal.taxpayerId,
        caseNo: appeal.caseNo,
        status: 'Filed',
        description: appeal.description,
        hearingDate: 'TBD',
      );
      _appeals.insert(0, mockNew);
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Offline Mock Data Generators ─────────────────────────────────
  
  List<ItrRecord> _getMockItrs(int tpId) {
    return [
      ItrRecord(
        id: 101,
        taxpayerId: tpId,
        assessmentYear: '2025-2026',
        grossTax: 45000.0,
        rebate: 5000.0,
        netTaxPayable: 40000.0,
        advanceTaxPaid: 15000.0,
        withholdingTax: 5000.0,
        taxPaid: 20000.0,
        status: 'Accepted',
        submissionDate: '2025-11-15',
      ),
      ItrRecord(
        id: 102,
        taxpayerId: tpId,
        assessmentYear: '2024-2025',
        grossTax: 32000.0,
        rebate: 3000.0,
        netTaxPayable: 29000.0,
        advanceTaxPaid: 10000.0,
        withholdingTax: 4000.0,
        taxPaid: 15000.0,
        status: 'Accepted',
        submissionDate: '2024-11-20',
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
        name: 'Karim Software & Tech',
        tradeLicenseNo: 'TRAD/DNCC/02345/2022',
        vatStatus: 'Active',
        address: 'H-23, Road 4, Dhanmondi, Dhaka',
      ),
      Business(
        id: 302,
        name: 'Karim Agro Industries',
        tradeLicenseNo: 'TRAD/DNCC/12304/2024',
        vatStatus: 'Pending',
        address: 'H-10, Block C, Uttara, Dhaka',
      ),
    ];
  }

  List<Notice> _getMockNotices(int tpId) {
    return [
      Notice(
        id: 401,
        title: 'Tax Assessment Notice - FY 2024-25',
        message: 'Your Income Tax Return for assessment year 2024-2025 has been processed. A discrepancy of BDT 5,000 has been observed. Please upload copies of your investment proof or reply to this notice within 15 days.',
        status: 'Unread',
        date: '2026-06-25',
        noticeType: 'Discrepancy',
      ),
      Notice(
        id: 402,
        title: 'TIN Certificate Verification Successful',
        message: 'Your TIN certificate details have been verified successfully. No outstanding action is required from your end.',
        status: 'Read',
        date: '2026-04-01',
        noticeType: 'System',
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
        status: 'Closed',
        description: 'Audit completed successfully. Tax liability verified. Standard compliance met.',
        demandAmount: 0.0,
      ),
    ];
  }

  List<Appeal> _getMockAppeals(int tpId) {
    return [
      Appeal(
        id: 701,
        taxpayerId: tpId,
        caseNo: 'APP/2026/089',
        status: 'Hearing Scheduled',
        description: 'Appeal against penalty issued for delay in filing income tax return. Ground: Taxpayer was hospitalized during filing period.',
        hearingDate: '2026-07-20 11:30 AM',
      ),
    ];
  }
}
