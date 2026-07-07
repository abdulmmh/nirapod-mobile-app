class ItrAction {
  final int? id;
  final String action;
  final String? fromStatus;
  final String? toStatus;
  final String? status;
  final String performedBy;
  final String role;
  final String performedAt;
  final String? remarks;

  ItrAction({
    this.id,
    required this.action,
    this.fromStatus,
    this.toStatus,
    this.status,
    required this.performedBy,
    required this.role,
    required this.performedAt,
    this.remarks,
  });

  factory ItrAction.fromJson(Map<String, dynamic> json) {
    return ItrAction(
      id: json['id'],
      action: json['action'] ?? '',
      fromStatus: json['fromStatus'],
      toStatus: json['toStatus'],
      status: json['status'],
      performedBy: json['performedBy'] ?? '',
      role: json['role'] ?? '',
      performedAt: json['performedAt'] ?? '',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'status': status,
      'performedBy': performedBy,
      'role': role,
      'performedAt': performedAt,
      'remarks': remarks,
    };
  }
}

class IT10BRecord {
  final int? id;
  final int? returnId;
  final double nonAgriculturalProperty;
  final double agriculturalProperty;
  final double investments;
  final double motorVehicles;
  final double bankBalances;
  final double personalLiabilities;
  final double netWealth;

  IT10BRecord({
    this.id,
    this.returnId,
    required this.nonAgriculturalProperty,
    required this.agriculturalProperty,
    required this.investments,
    required this.motorVehicles,
    required this.bankBalances,
    required this.personalLiabilities,
    required this.netWealth,
  });

  factory IT10BRecord.fromJson(Map<String, dynamic> json) {
    return IT10BRecord(
      id: json['id'],
      returnId: json['returnId'],
      nonAgriculturalProperty: double.tryParse(json['nonAgriculturalProperty']?.toString() ?? '0') ?? 0.0,
      agriculturalProperty: double.tryParse(json['agriculturalProperty']?.toString() ?? '0') ?? 0.0,
      investments: double.tryParse(json['investments']?.toString() ?? '0') ?? 0.0,
      motorVehicles: double.tryParse(json['motorVehicles']?.toString() ?? '0') ?? 0.0,
      bankBalances: double.tryParse(json['bankBalances']?.toString() ?? '0') ?? 0.0,
      personalLiabilities: double.tryParse(json['personalLiabilities']?.toString() ?? '0') ?? 0.0,
      netWealth: double.tryParse(json['netWealth']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'returnId': returnId,
      'nonAgriculturalProperty': nonAgriculturalProperty,
      'agriculturalProperty': agriculturalProperty,
      'investments': investments,
      'motorVehicles': motorVehicles,
      'bankBalances': bankBalances,
      'personalLiabilities': personalLiabilities,
      'netWealth': netWealth,
    };
  }
}

class ItrRecord {
  final int id;
  final int taxpayerId;
  final String? returnNo;
  final String? tinNumber;
  final int? userId;
  final String? taxpayerName;
  final String? itrCategory;
  final String? companySubType;
  final String assessmentYear;
  final String? incomeYear;
  final String? returnPeriod;
  final double? grossIncome;
  final double? exemptIncome;
  final double? rebate; // maps to taxRebate
  final double? taxRebate;
  final double? netTaxPayable; // added back
  final double? advanceTaxPaid;
  final double? withholdingTax;
  final double? taxPaid;
  final double? taxRate;
  final double? grossTax;
  final String status;
  final String? submissionDate;
  final String? dueDate;
  final String? submittedBy;
  final String? remarks;
  final List<ItrAction>? actionHistory;

  ItrRecord({
    required this.id,
    required this.taxpayerId,
    this.returnNo,
    this.tinNumber,
    this.userId,
    this.taxpayerName,
    this.itrCategory,
    this.companySubType,
    required this.assessmentYear,
    this.incomeYear,
    this.returnPeriod,
    this.grossIncome,
    this.exemptIncome,
    this.rebate,
    this.taxRebate,
    this.netTaxPayable,
    this.advanceTaxPaid,
    this.withholdingTax,
    this.taxPaid,
    this.taxRate,
    this.grossTax,
    required this.status,
    this.submissionDate,
    this.dueDate,
    this.submittedBy,
    this.remarks,
    this.actionHistory,
  });

  factory ItrRecord.fromJson(Map<String, dynamic> json) {
    var history = json['actionHistory'] as List?;
    List<ItrAction>? historyList = history != null
        ? history.map((e) => ItrAction.fromJson(e)).toList()
        : null;

    final double? rebateVal = json['taxRebate'] != null
        ? double.tryParse(json['taxRebate'].toString())
        : (json['rebate'] != null ? double.tryParse(json['rebate'].toString()) : null);

    return ItrRecord(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      returnNo: json['returnNo'],
      tinNumber: json['tinNumber'],
      userId: json['userId'],
      taxpayerName: json['taxpayerName'],
      itrCategory: json['itrCategory'],
      companySubType: json['companySubType'],
      assessmentYear: json['assessmentYear'] ?? '',
      incomeYear: json['incomeYear'],
      returnPeriod: json['returnPeriod'],
      grossIncome: json['grossIncome'] != null ? double.tryParse(json['grossIncome'].toString()) : null,
      exemptIncome: json['exemptIncome'] != null ? double.tryParse(json['exemptIncome'].toString()) : null,
      rebate: rebateVal,
      taxRebate: rebateVal,
      netTaxPayable: json['netTaxPayable'] != null ? double.tryParse(json['netTaxPayable'].toString()) : null,
      advanceTaxPaid: json['advanceTaxPaid'] != null ? double.tryParse(json['advanceTaxPaid'].toString()) : null,
      withholdingTax: json['withholdingTax'] != null ? double.tryParse(json['withholdingTax'].toString()) : null,
      taxPaid: json['taxPaid'] != null ? double.tryParse(json['taxPaid'].toString()) : null,
      taxRate: json['taxRate'] != null ? double.tryParse(json['taxRate'].toString()) : null,
      grossTax: json['grossTax'] != null ? double.tryParse(json['grossTax'].toString()) : null,
      status: json['status'] ?? 'Draft',
      submissionDate: json['submissionDate'],
      dueDate: json['dueDate'],
      submittedBy: json['submittedBy'],
      remarks: json['remarks'],
      actionHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'returnNo': returnNo,
      'tinNumber': tinNumber,
      'userId': userId,
      'taxpayerName': taxpayerName,
      'itrCategory': itrCategory,
      'companySubType': companySubType,
      'assessmentYear': assessmentYear,
      'incomeYear': incomeYear,
      'returnPeriod': returnPeriod,
      'grossIncome': grossIncome,
      'exemptIncome': exemptIncome,
      'rebate': rebate,
      'taxRebate': taxRebate ?? rebate,
      'netTaxPayable': netTaxPayable ?? (grossTax != null ? (grossTax! - (taxRebate ?? rebate ?? 0.0)) : null),
      'advanceTaxPaid': advanceTaxPaid,
      'withholdingTax': withholdingTax,
      'taxPaid': taxPaid,
      'taxRate': taxRate,
      'grossTax': grossTax,
      'status': status,
      'submissionDate': submissionDate,
      'dueDate': dueDate,
      'submittedBy': submittedBy,
      'remarks': remarks,
      'actionHistory': actionHistory?.map((e) => e.toJson()).toList(),
    };
  }
}

class AitRecord {
  final int id;
  final int taxpayerId;
  final double amount;
  final String source;
  final String challanNo;
  final String? date;
  final String status;

  AitRecord({
    required this.id,
    required this.taxpayerId,
    required this.amount,
    required this.source,
    required this.challanNo,
    this.date,
    required this.status,
  });

  factory AitRecord.fromJson(Map<String, dynamic> json) {
    return AitRecord(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      amount: json['amount'] != null 
          ? (double.tryParse(json['amount'].toString()) ?? 0.0)
          : (json['calculatedAitAmount'] != null 
              ? (double.tryParse(json['calculatedAitAmount'].toString()) ?? 0.0) 
              : 0.0),
      source: json['source'] ?? json['sourceType'] ?? '',
      challanNo: json['challanNo'] ?? json['challanNumber'] ?? '',
      date: json['date'] ?? json['submissionDate'] ?? json['createdAt'],
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'amount': amount,
      'source': source,
      'challanNo': challanNo,
      'date': date,
      'status': status,
    };
  }
}

class Business {
  final int id;
  final String name;
  final String tradeLicenseNo;
  final String vatStatus;
  final String? address;
  final String? ownerName;
  final String? tinNumber;
  final String? businessType;
  final String? businessCategory;
  final String? email;
  final String? phone;
  final String? division;
  final String? district;
  final String? incorporationDate;
  final String? registrationDate;
  final String? expiryDate;
  final double? annualTurnover;
  final int? numberOfEmployees;
  final String? remarks;

  Business({
    required this.id,
    required this.name,
    required this.tradeLicenseNo,
    required this.vatStatus,
    this.address,
    this.ownerName,
    this.tinNumber,
    this.businessType,
    this.businessCategory,
    this.email,
    this.phone,
    this.division,
    this.district,
    this.incorporationDate,
    this.registrationDate,
    this.expiryDate,
    this.annualTurnover,
    this.numberOfEmployees,
    this.remarks,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] ?? 0,
      name: json['businessName'] ?? json['name'] ?? json['companyName'] ?? '',
      tradeLicenseNo: json['tradeLicenseNo'] ?? json['rjscNo'] ?? '',
      vatStatus: json['vatStatus'] ?? json['status'] ?? 'Inactive',
      address: json['address'],
      ownerName: json['ownerName'],
      tinNumber: json['tinNumber'],
      businessType: json['businessType'] is Map 
          ? json['businessType']['typeName'] 
          : json['businessType']?.toString(),
      businessCategory: json['businessCategory'] is Map 
          ? json['businessCategory']['categoryName'] 
          : json['businessCategory']?.toString(),
      email: json['email'],
      phone: json['phone'],
      division: json['division'] is Map 
          ? json['division']['name'] 
          : json['division']?.toString(),
      district: json['district'] is Map 
          ? json['district']['name'] 
          : json['district']?.toString(),
      incorporationDate: json['incorporationDate'],
      registrationDate: json['registrationDate'],
      expiryDate: json['expiryDate'],
      annualTurnover: json['annualTurnover'] != null 
          ? double.tryParse(json['annualTurnover'].toString()) 
          : null,
      numberOfEmployees: json['numberOfEmployees'] != null 
          ? int.tryParse(json['numberOfEmployees'].toString()) 
          : null,
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': name,
      'name': name,
      'tradeLicenseNo': tradeLicenseNo,
      'vatStatus': vatStatus,
      'status': vatStatus,
      'address': address,
      'ownerName': ownerName,
      'tinNumber': tinNumber,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'email': email,
      'phone': phone,
      'division': division,
      'district': district,
      'incorporationDate': incorporationDate,
      'registrationDate': registrationDate,
      'expiryDate': expiryDate,
      'annualTurnover': annualTurnover,
      'numberOfEmployees': numberOfEmployees,
      'remarks': remarks,
    };
  }
}

class Notice {
  final int id;
  final String title;
  final String message;
  final String status;
  final String? date;
  final String? noticeType;
  final String? replyMessage;
  final String? replyDate;
  final String? noticeNo;
  final String? priority;

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.status,
    this.date,
    this.noticeType,
    this.replyMessage,
    this.replyDate,
    this.noticeNo,
    this.priority,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? 0,
      title: json['subject'] ?? json['title'] ?? '',
      message: json['body'] ?? json['message'] ?? json['content'] ?? '',
      status: json['status'] ?? 'Unread',
      date: json['issuedDate'] ?? json['date'] ?? json['createdAt'] ?? json['issueDate'],
      noticeType: json['noticeType'],
      replyMessage: json['responseNote'] ?? json['replyMessage'],
      replyDate: json['responseDate'] ?? json['replyDate'],
      noticeNo: json['noticeNo'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': title,
      'body': message,
      'status': status,
      'issuedDate': date,
      'noticeType': noticeType,
      'responseNote': replyMessage,
      'responseDate': replyDate,
      'noticeNo': noticeNo,
      'priority': priority,
    };
  }
}

class Payment {
  final int id;
  final String challanNo;
  final double amount;
  final String? date;
  final String status;
  final String? paymentType;
  final String? tinNumber;
  final String? taxpayerName;
  final int? taxpayerId;
  final String? paymentMethod;
  final String? bankName;
  final String? bankBranch;
  final String? accountNo;
  final String? chequeNo;
  final String? paymentDate;
  final String? valueDate;
  final String? referenceNo;
  final String? returnNo;
  final String? remarks;

  Payment({
    required this.id,
    required this.challanNo,
    required this.amount,
    this.date,
    required this.status,
    this.paymentType,
    this.tinNumber,
    this.taxpayerName,
    this.taxpayerId,
    this.paymentMethod,
    this.bankName,
    this.bankBranch,
    this.accountNo,
    this.chequeNo,
    this.paymentDate,
    this.valueDate,
    this.referenceNo,
    this.returnNo,
    this.remarks,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      challanNo: json['challanNo'] ?? json['transactionId'] ?? json['referenceNo'] ?? '',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      date: json['date'] ?? json['paymentDate'] ?? json['createdAt'],
      status: json['status'] ?? 'Pending',
      paymentType: json['paymentType'],
      tinNumber: json['tinNumber'],
      taxpayerName: json['taxpayerName'],
      taxpayerId: json['taxpayerId'],
      paymentMethod: json['paymentMethod'],
      bankName: json['bankName'],
      bankBranch: json['bankBranch'],
      accountNo: json['accountNo'],
      chequeNo: json['chequeNo'],
      paymentDate: json['paymentDate'],
      valueDate: json['valueDate'],
      referenceNo: json['referenceNo'],
      returnNo: json['returnNo'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challanNo': challanNo,
      'amount': amount,
      'date': date,
      'status': status,
      'paymentType': paymentType,
      if (tinNumber != null) 'tinNumber': tinNumber,
      if (taxpayerName != null) 'taxpayerName': taxpayerName,
      if (taxpayerId != null) 'taxpayerId': taxpayerId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (bankName != null) 'bankName': bankName,
      if (bankBranch != null) 'bankBranch': bankBranch,
      if (accountNo != null) 'accountNo': accountNo,
      if (chequeNo != null) 'chequeNo': chequeNo,
      if (paymentDate != null) 'paymentDate': paymentDate,
      if (valueDate != null) 'valueDate': valueDate,
      if (referenceNo != null) 'referenceNo': referenceNo,
      if (returnNo != null) 'returnNo': returnNo,
      if (remarks != null) 'remarks': remarks,
    };
  }
}

class OutstandingItem {
  final String type;
  final String returnNo;
  final String label;
  final double totalDue;
  final double alreadyPaid;
  final double outstanding;
  final String? dueDate;
  final String status;
  final bool overdue;

  OutstandingItem({
    required this.type,
    required this.returnNo,
    required this.label,
    required this.totalDue,
    required this.alreadyPaid,
    required this.outstanding,
    this.dueDate,
    required this.status,
    required this.overdue,
  });

  factory OutstandingItem.fromJson(Map<String, dynamic> json) {
    return OutstandingItem(
      type: json['type'] ?? '',
      returnNo: json['returnNo'] ?? '',
      label: json['label'] ?? '',
      totalDue: double.tryParse(json['totalDue']?.toString() ?? '0') ?? 0.0,
      alreadyPaid: double.tryParse(json['alreadyPaid']?.toString() ?? '0') ?? 0.0,
      outstanding: double.tryParse(json['outstanding']?.toString() ?? '0') ?? 0.0,
      dueDate: json['dueDate'],
      status: json['status'] ?? '',
      overdue: json['overdue'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'returnNo': returnNo,
      'label': label,
      'totalDue': totalDue,
      'alreadyPaid': alreadyPaid,
      'outstanding': outstanding,
      'dueDate': dueDate,
      'status': status,
      'overdue': overdue,
    };
  }
}

class Audit {
  final int id;
  final int taxpayerId;
  final String year;
  final String status;
  final String? description;
  final double? demandAmount;

  // New fields matching AuditCaseResponse
  final String caseNo;
  final String auditType;
  final String taxType;
  final String? fiscalYear;
  final String? taxPeriodStart;
  final String? taxPeriodEnd;
  final String? triggerReason;
  final int? riskScore;
  final String? priority;
  final String? assignedOfficerName;
  final String? supervisorName;
  final String? scheduledDate;
  final String? dueDate;
  final String? closedDate;
  final String? returnReference;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;
  final int queryCount;
  final int openQueryCount;
  final int findingCount;
  final int documentRequestCount;
  final bool hasAssessment;
  final bool hasDemandNotice;

  Audit({
    required this.id,
    required this.taxpayerId,
    required this.year,
    required this.status,
    this.description,
    this.demandAmount,
    required this.caseNo,
    required this.auditType,
    required this.taxType,
    this.fiscalYear,
    this.taxPeriodStart,
    this.taxPeriodEnd,
    this.triggerReason,
    this.riskScore,
    this.priority,
    this.assignedOfficerName,
    this.supervisorName,
    this.scheduledDate,
    this.dueDate,
    this.closedDate,
    this.returnReference,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.queryCount = 0,
    this.openQueryCount = 0,
    this.findingCount = 0,
    this.documentRequestCount = 0,
    this.hasAssessment = false,
    this.hasDemandNotice = false,
  });

  factory Audit.fromJson(Map<String, dynamic> json) {
    return Audit(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      year: json['fiscalYear'] ?? json['year'] ?? json['auditYear'] ?? '',
      status: json['status'] ?? 'SELECTED',
      description: json['description'] ?? json['comments'] ?? json['findings'] ?? json['remarks'] ?? '',
      demandAmount: json['demandAmount'] != null 
          ? double.tryParse(json['demandAmount'].toString()) 
          : (json['amountDue'] != null ? (json['amountDue'] as num).toDouble() : null),
      caseNo: json['caseNo'] ?? '',
      auditType: json['auditType'] ?? 'DESK',
      taxType: json['taxType'] ?? 'INCOME_TAX',
      fiscalYear: json['fiscalYear'] ?? json['year'],
      taxPeriodStart: json['taxPeriodStart'],
      taxPeriodEnd: json['taxPeriodEnd'],
      triggerReason: json['triggerReason'],
      riskScore: json['riskScore'],
      priority: json['priority'],
      assignedOfficerName: json['assignedOfficerName'],
      supervisorName: json['supervisorName'],
      scheduledDate: json['scheduledDate'],
      dueDate: json['dueDate'],
      closedDate: json['closedDate'],
      returnReference: json['returnReference'],
      remarks: json['remarks'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      queryCount: json['queryCount'] ?? 0,
      openQueryCount: json['openQueryCount'] ?? 0,
      findingCount: json['findingCount'] ?? 0,
      documentRequestCount: json['documentRequestCount'] ?? 0,
      hasAssessment: json['hasAssessment'] ?? false,
      hasDemandNotice: json['hasDemandNotice'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'year': year,
      'status': status,
      'description': description,
      'demandAmount': demandAmount,
      'caseNo': caseNo,
      'auditType': auditType,
      'taxType': taxType,
      'fiscalYear': fiscalYear,
      'taxPeriodStart': taxPeriodStart,
      'taxPeriodEnd': taxPeriodEnd,
      'triggerReason': triggerReason,
      'riskScore': riskScore,
      'priority': priority,
      'assignedOfficerName': assignedOfficerName,
      'supervisorName': supervisorName,
      'scheduledDate': scheduledDate,
      'dueDate': dueDate,
      'closedDate': closedDate,
      'returnReference': returnReference,
      'remarks': remarks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'queryCount': queryCount,
      'openQueryCount': openQueryCount,
      'findingCount': findingCount,
      'documentRequestCount': documentRequestCount,
      'hasAssessment': hasAssessment,
      'hasDemandNotice': hasDemandNotice,
    };
  }
}

class AuditQuery {
  final int id;
  final int auditCaseId;
  final String queryNo;
  final String subject;
  final String queryText;
  final String queryType;
  final String raisedBy;
  final String raisedAt;
  final String? responseText;
  final String? respondedBy;
  final String? respondedAt;
  final String? deadline;
  final String status;

  AuditQuery({
    required this.id,
    required this.auditCaseId,
    required this.queryNo,
    required this.subject,
    required this.queryText,
    required this.queryType,
    required this.raisedBy,
    required this.raisedAt,
    this.responseText,
    this.respondedBy,
    this.respondedAt,
    this.deadline,
    required this.status,
  });

  factory AuditQuery.fromJson(Map<String, dynamic> json) {
    return AuditQuery(
      id: json['id'] ?? 0,
      auditCaseId: json['auditCaseId'] ?? 0,
      queryNo: json['queryNo'] ?? '',
      subject: json['subject'] ?? '',
      queryText: json['queryText'] ?? '',
      queryType: json['queryType'] ?? '',
      raisedBy: json['raisedBy'] ?? '',
      raisedAt: json['raisedAt'] ?? '',
      responseText: json['responseText'],
      respondedBy: json['respondedBy'],
      respondedAt: json['respondedAt'],
      deadline: json['deadline'],
      status: json['status'] ?? 'OPEN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auditCaseId': auditCaseId,
      'queryNo': queryNo,
      'subject': subject,
      'queryText': queryText,
      'queryType': queryType,
      'raisedBy': raisedBy,
      'raisedAt': raisedAt,
      'responseText': responseText,
      'respondedBy': respondedBy,
      'respondedAt': respondedAt,
      'deadline': deadline,
      'status': status,
    };
  }
}

class AuditDocumentRequest {
  final int id;
  final int auditCaseId;
  final String requestNo;
  final String requestedDocuments;
  final String? requestReason;
  final String requestType;
  final String requestedBy;
  final String requestedAt;
  final String? deadline;
  final String status;
  final String? fulfillmentNotes;

  AuditDocumentRequest({
    required this.id,
    required this.auditCaseId,
    required this.requestNo,
    required this.requestedDocuments,
    this.requestReason,
    required this.requestType,
    required this.requestedBy,
    required this.requestedAt,
    this.deadline,
    required this.status,
    this.fulfillmentNotes,
  });

  factory AuditDocumentRequest.fromJson(Map<String, dynamic> json) {
    return AuditDocumentRequest(
      id: json['id'] ?? 0,
      auditCaseId: json['auditCaseId'] ?? 0,
      requestNo: json['requestNo'] ?? '',
      requestedDocuments: json['requestedDocuments'] ?? '',
      requestReason: json['requestReason'],
      requestType: json['requestType'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      deadline: json['deadline'],
      status: json['status'] ?? 'PENDING',
      fulfillmentNotes: json['fulfillmentNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auditCaseId': auditCaseId,
      'requestNo': requestNo,
      'requestedDocuments': requestedDocuments,
      'requestReason': requestReason,
      'requestType': requestType,
      'requestedBy': requestedBy,
      'requestedAt': requestedAt,
      'deadline': deadline,
      'status': status,
      'fulfillmentNotes': fulfillmentNotes,
    };
  }
}

class Assessment {
  final int id;
  final int auditCaseId;
  final String caseNo;
  final String assessmentNo;
  final int taxpayerId;
  final String tinNumber;
  final String taxpayerName;
  final String fiscalYear;
  final String taxType;
  final double declaredIncome;
  final double assessedIncome;
  final double declaredTax;
  final double assessedTax;
  final double additionalTax;
  final double penaltyRate;
  final double penaltyAmount;
  final double interestRate;
  final int interestMonths;
  final double interestAmount;
  final double totalDemand;
  final double amountPaid;
  final double balanceDue;
  final String? findingsSummary;
  final String? legalBasis;
  final String? appealRights;
  final String? paymentDeadline;
  final String status;
  final String? proposedBy;
  final String? proposedAt;
  final String? approvedBy;
  final String? approvedAt;
  final String? approvalNotes;
  final bool hasDemandNotice;
  final String? demandNo;

  Assessment({
    required this.id,
    required this.auditCaseId,
    required this.caseNo,
    required this.assessmentNo,
    required this.taxpayerId,
    required this.tinNumber,
    required this.taxpayerName,
    required this.fiscalYear,
    required this.taxType,
    required this.declaredIncome,
    required this.assessedIncome,
    required this.declaredTax,
    required this.assessedTax,
    required this.additionalTax,
    required this.penaltyRate,
    required this.penaltyAmount,
    required this.interestRate,
    required this.interestMonths,
    required this.interestAmount,
    required this.totalDemand,
    required this.amountPaid,
    required this.balanceDue,
    this.findingsSummary,
    this.legalBasis,
    this.appealRights,
    this.paymentDeadline,
    required this.status,
    this.proposedBy,
    this.proposedAt,
    this.approvedBy,
    this.approvedAt,
    this.approvalNotes,
    required this.hasDemandNotice,
    this.demandNo,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      id: json['id'] ?? 0,
      auditCaseId: json['auditCaseId'] ?? 0,
      caseNo: json['caseNo'] ?? '',
      assessmentNo: json['assessmentNo'] ?? '',
      taxpayerId: json['taxpayerId'] ?? 0,
      tinNumber: json['tinNumber'] ?? '',
      taxpayerName: json['taxpayerName'] ?? '',
      fiscalYear: json['fiscalYear'] ?? '',
      taxType: json['taxType'] ?? '',
      declaredIncome: (json['declaredIncome'] as num?)?.toDouble() ?? 0.0,
      assessedIncome: (json['assessedIncome'] as num?)?.toDouble() ?? 0.0,
      declaredTax: (json['declaredTax'] as num?)?.toDouble() ?? 0.0,
      assessedTax: (json['assessedTax'] as num?)?.toDouble() ?? 0.0,
      additionalTax: (json['additionalTax'] as num?)?.toDouble() ?? 0.0,
      penaltyRate: (json['penaltyRate'] as num?)?.toDouble() ?? 0.0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      interestMonths: json['interestMonths'] ?? 0,
      interestAmount: (json['interestAmount'] as num?)?.toDouble() ?? 0.0,
      totalDemand: (json['totalDemand'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0.0,
      findingsSummary: json['findingsSummary'],
      legalBasis: json['legalBasis'],
      appealRights: json['appealRights'],
      paymentDeadline: json['paymentDeadline'],
      status: json['status'] ?? 'PROPOSED',
      proposedBy: json['proposedBy'],
      proposedAt: json['proposedAt'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'],
      approvalNotes: json['approvalNotes'],
      hasDemandNotice: json['hasDemandNotice'] ?? false,
      demandNo: json['demandNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auditCaseId': auditCaseId,
      'caseNo': caseNo,
      'assessmentNo': assessmentNo,
      'taxpayerId': taxpayerId,
      'tinNumber': tinNumber,
      'taxpayerName': taxpayerName,
      'fiscalYear': fiscalYear,
      'taxType': taxType,
      'declaredIncome': declaredIncome,
      'assessedIncome': assessedIncome,
      'declaredTax': declaredTax,
      'assessedTax': assessedTax,
      'additionalTax': additionalTax,
      'penaltyRate': penaltyRate,
      'penaltyAmount': penaltyAmount,
      'interestRate': interestRate,
      'interestMonths': interestMonths,
      'interestAmount': interestAmount,
      'totalDemand': totalDemand,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'findingsSummary': findingsSummary,
      'legalBasis': legalBasis,
      'appealRights': appealRights,
      'paymentDeadline': paymentDeadline,
      'status': status,
      'proposedBy': proposedBy,
      'proposedAt': proposedAt,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
      'approvalNotes': approvalNotes,
      'hasDemandNotice': hasDemandNotice,
      'demandNo': demandNo,
    };
  }
}

class DemandNotice {
  final int id;
  final String demandNo;
  final int? assessmentId;
  final String? assessmentNo;
  final int? auditCaseId;
  final int? taxpayerId;
  final String? tinNumber;
  final String? taxpayerName;
  final double amountDue;
  final String dueDate;
  final String? paymentInstructions;
  final String? issuedBy;
  final String? issuedAt;
  final String status;
  final String? paymentReference;
  final double? paidAmount;
  final String? paidAt;

  DemandNotice({
    required this.id,
    required this.demandNo,
    this.assessmentId,
    this.assessmentNo,
    this.auditCaseId,
    this.taxpayerId,
    this.tinNumber,
    this.taxpayerName,
    required this.amountDue,
    required this.dueDate,
    this.paymentInstructions,
    this.issuedBy,
    this.issuedAt,
    required this.status,
    this.paymentReference,
    this.paidAmount,
    this.paidAt,
  });

  factory DemandNotice.fromJson(Map<String, dynamic> json) {
    return DemandNotice(
      id: json['id'] ?? 0,
      demandNo: json['demandNo'] ?? '',
      assessmentId: json['assessmentId'],
      assessmentNo: json['assessmentNo'],
      auditCaseId: json['auditCaseId'],
      taxpayerId: json['taxpayerId'],
      tinNumber: json['tinNumber'],
      taxpayerName: json['taxpayerName'],
      amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] ?? '',
      paymentInstructions: json['paymentInstructions'],
      issuedBy: json['issuedBy'],
      issuedAt: json['issuedAt'],
      status: json['status'] ?? 'ISSUED',
      paymentReference: json['paymentReference'],
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      paidAt: json['paidAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'demandNo': demandNo,
      'assessmentId': assessmentId,
      'assessmentNo': assessmentNo,
      'auditCaseId': auditCaseId,
      'taxpayerId': taxpayerId,
      'tinNumber': tinNumber,
      'taxpayerName': taxpayerName,
      'amountDue': amountDue,
      'dueDate': dueDate,
      'paymentInstructions': paymentInstructions,
      'issuedBy': issuedBy,
      'issuedAt': issuedAt,
      'status': status,
      'paymentReference': paymentReference,
      'paidAmount': paidAmount,
      'paidAt': paidAt,
    };
  }
}

class Appeal {
  final int id;
  final int taxpayerId;
  final String caseNo;
  final String status;
  final String? description;
  final String? hearingDate;
  
  // New fields matching the backend Appeal model
  final String? appealNo;
  final double? demandedAmount;
  final double? disputedAmount;
  final double? acceptedAmount;
  final double? reliefGranted;
  final String? groundsText;
  final String? reliefSought;
  final String? supportingEvidence;
  final String? filedAt;
  final String? deadline;
  final String? decidedAt;
  final String? decidedBy;
  final String? decision;
  final String? decisionNotes;
  final String? demandNo;

  Appeal({
    required this.id,
    required this.taxpayerId,
    required this.caseNo,
    required this.status,
    this.description,
    this.hearingDate,
    this.appealNo,
    this.demandedAmount,
    this.disputedAmount,
    this.acceptedAmount,
    this.reliefGranted,
    this.groundsText,
    this.reliefSought,
    this.supportingEvidence,
    this.filedAt,
    this.deadline,
    this.decidedAt,
    this.decidedBy,
    this.decision,
    this.decisionNotes,
    this.demandNo,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      caseNo: json['appealNo'] ?? json['caseNo'] ?? json['appealNumber'] ?? '',
      status: json['status'] ?? 'Filed',
      description: json['groundsText'] ?? json['description'] ?? json['groundsOfAppeal'] ?? json['remarks'] ?? '',
      hearingDate: json['hearingDate'],
      appealNo: json['appealNo'] ?? json['caseNo'] ?? json['appealNumber'] ?? '',
      demandedAmount: (json['demandedAmount'] as num?)?.toDouble(),
      disputedAmount: (json['disputedAmount'] as num?)?.toDouble(),
      acceptedAmount: (json['acceptedAmount'] as num?)?.toDouble(),
      reliefGranted: (json['reliefGranted'] as num?)?.toDouble(),
      groundsText: json['groundsText'] ?? json['description'] ?? '',
      reliefSought: json['reliefSought'],
      supportingEvidence: json['supportingEvidence'],
      filedAt: json['filedAt'],
      deadline: json['deadline'],
      decidedAt: json['decidedAt'],
      decidedBy: json['decidedBy'] ?? json['decidedByName'],
      decision: json['decision'],
      decisionNotes: json['decisionNotes'],
      demandNo: json['demandNo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'caseNo': caseNo,
      'status': status,
      'description': description,
      'hearingDate': hearingDate,
      'appealNo': appealNo,
      'demandedAmount': demandedAmount,
      'disputedAmount': disputedAmount,
      'acceptedAmount': acceptedAmount,
      'reliefGranted': reliefGranted,
      'groundsText': groundsText,
      'reliefSought': reliefSought,
      'supportingEvidence': supportingEvidence,
      'filedAt': filedAt,
      'deadline': deadline,
      'decidedAt': decidedAt,
      'decidedBy': decidedBy,
      'decision': decision,
      'decisionNotes': decisionNotes,
      'demandNo': demandNo,
    };
  }
}

class VatRegistration {
  final int id;
  final String binNo;
  final String businessName;
  final String? ownerName;
  final String vatCategory;
  final String? businessType;
  final String? businessCategory;
  final String? tradeLicenseNo;
  final String vatZone;
  final String vatCircle;
  final String? registrationDate;
  final String? effectiveDate;
  final String returnPeriod;
  final String? expiryDate;
  final double annualTurnover;
  final String? email;
  final String? phone;
  final String? address;
  final String? district;
  final String? division;
  final String status;
  final String? remarks;
  final String? tradeLicensePath;
  final String? tinCertificatePath;
  final String? nidAuthorizedPath;

  VatRegistration({
    required this.id,
    required this.binNo,
    required this.businessName,
    this.ownerName,
    required this.vatCategory,
    this.businessType,
    this.businessCategory,
    this.tradeLicenseNo,
    required this.vatZone,
    required this.vatCircle,
    this.registrationDate,
    this.effectiveDate,
    required this.returnPeriod,
    this.expiryDate,
    required this.annualTurnover,
    this.email,
    this.phone,
    this.address,
    this.district,
    this.division,
    required this.status,
    this.remarks,
    this.tradeLicensePath,
    this.tinCertificatePath,
    this.nidAuthorizedPath,
  });

  factory VatRegistration.fromJson(Map<String, dynamic> json) {
    return VatRegistration(
      id: json['id'] ?? 0,
      binNo: json['binNo'] ?? json['bin_no'] ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      ownerName: json['ownerName'] ?? json['owner_name'],
      vatCategory: json['vatCategory'] ?? json['vat_category'] ?? '',
      businessType: json['businessType'] ?? json['business_type'],
      businessCategory: json['businessCategory'] ?? json['business_category'],
      tradeLicenseNo: json['tradeLicenseNo'] ?? json['trade_license_no'],
      vatZone: json['vatZone'] ?? json['vat_zone'] ?? '',
      vatCircle: json['vatCircle'] ?? json['vat_circle'] ?? '',
      registrationDate: json['registrationDate'] ?? json['registration_date'],
      effectiveDate: json['effectiveDate'] ?? json['effective_date'],
      returnPeriod: json['returnPeriod'] ?? json['return_period'] ?? 'Monthly',
      expiryDate: json['expiryDate'] ?? json['expiry_date'],
      annualTurnover: double.tryParse(json['annualTurnover']?.toString() ?? '0.0') ?? 0.0,
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      district: json['district'],
      division: json['division'],
      status: json['status'] ?? 'Pending',
      remarks: json['remarks'],
      tradeLicensePath: json['tradeLicensePath'] ?? json['trade_license_path'],
      tinCertificatePath: json['tinCertificatePath'] ?? json['tin_certificate_path'],
      nidAuthorizedPath: json['nidAuthorizedPath'] ?? json['nid_authorized_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'binNo': binNo,
      'businessName': businessName,
      'ownerName': ownerName,
      'vatCategory': vatCategory,
      'businessType': businessType,
      'businessCategory': businessCategory,
      'tradeLicenseNo': tradeLicenseNo,
      'vatZone': vatZone,
      'vatCircle': vatCircle,
      'registrationDate': registrationDate,
      'effectiveDate': effectiveDate,
      'returnPeriod': returnPeriod,
      'expiryDate': expiryDate,
      'annualTurnover': annualTurnover,
      'email': email,
      'phone': phone,
      'address': address,
      'district': district,
      'division': division,
      'status': status,
      'remarks': remarks,
      'tradeLicensePath': tradeLicensePath,
      'tinCertificatePath': tinCertificatePath,
      'nidAuthorizedPath': nidAuthorizedPath,
    };
  }
}

class VatReturn {
  final int id;
  final String returnNo;
  final String binNo;
  final String tinNumber;
  final String businessName;
  final String returnPeriod;
  final String periodMonth;
  final String periodYear;
  final String? assessmentYear;
  final double taxableSupplies;
  final double exemptSupplies;
  final double zeroRatedSupplies;
  final double totalSupplies;
  final double outputTax;
  final double inputTax;
  final double netTaxPayable;
  final double taxPaid;
  final String? submissionDate;
  final String? dueDate;
  final String status;
  final String? submittedBy;
  final String? submittedAt;
  final String? remarks;

  VatReturn({
    required this.id,
    required this.returnNo,
    required this.binNo,
    required this.tinNumber,
    required this.businessName,
    required this.returnPeriod,
    required this.periodMonth,
    required this.periodYear,
    this.assessmentYear,
    required this.taxableSupplies,
    required this.exemptSupplies,
    required this.zeroRatedSupplies,
    required this.totalSupplies,
    required this.outputTax,
    required this.inputTax,
    required this.netTaxPayable,
    required this.taxPaid,
    this.submissionDate,
    this.dueDate,
    required this.status,
    this.submittedBy,
    this.submittedAt,
    this.remarks,
  });

  factory VatReturn.fromJson(Map<String, dynamic> json) {
    return VatReturn(
      id: json['id'] ?? 0,
      returnNo: json['returnNo'] ?? json['return_no'] ?? '',
      binNo: json['binNo'] ?? json['bin_no'] ?? '',
      tinNumber: json['tinNumber'] ?? json['tin_number'] ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      returnPeriod: json['returnPeriod'] ?? json['return_period'] ?? 'Monthly',
      periodMonth: json['periodMonth'] ?? json['period_month'] ?? '',
      periodYear: json['periodYear'] ?? json['period_year'] ?? '',
      assessmentYear: json['assessmentYear'] ?? json['assessment_year'],
      taxableSupplies: double.tryParse(json['taxableSupplies']?.toString() ?? '0.0') ?? 0.0,
      exemptSupplies: double.tryParse(json['exemptSupplies']?.toString() ?? '0.0') ?? 0.0,
      zeroRatedSupplies: double.tryParse(json['zeroRatedSupplies']?.toString() ?? '0.0') ?? 0.0,
      totalSupplies: double.tryParse(json['totalSupplies']?.toString() ?? '0.0') ?? 0.0,
      outputTax: double.tryParse(json['outputTax']?.toString() ?? '0.0') ?? 0.0,
      inputTax: double.tryParse(json['inputTax']?.toString() ?? '0.0') ?? 0.0,
      netTaxPayable: double.tryParse(json['netTaxPayable']?.toString() ?? '0.0') ?? 0.0,
      taxPaid: double.tryParse(json['taxPaid']?.toString() ?? '0.0') ?? 0.0,
      submissionDate: json['submissionDate'] ?? json['submission_date'],
      dueDate: json['dueDate'] ?? json['due_date'],
      status: json['status'] ?? 'Draft',
      submittedBy: json['submittedBy'] ?? json['submitted_by'],
      submittedAt: json['submittedAt'] ?? json['submitted_at'],
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'returnNo': returnNo,
      'binNo': binNo,
      'tinNumber': tinNumber,
      'businessName': businessName,
      'returnPeriod': returnPeriod,
      'periodMonth': periodMonth,
      'periodYear': periodYear,
      'assessmentYear': assessmentYear,
      'taxableSupplies': taxableSupplies,
      'exemptSupplies': exemptSupplies,
      'zeroRatedSupplies': zeroRatedSupplies,
      'totalSupplies': totalSupplies,
      'outputTax': outputTax,
      'inputTax': inputTax,
      'netTaxPayable': netTaxPayable,
      'taxPaid': taxPaid,
      'submissionDate': submissionDate,
      'dueDate': dueDate,
      'status': status,
      'submittedBy': submittedBy,
      'submittedAt': submittedAt,
      'remarks': remarks,
    };
  }
}
