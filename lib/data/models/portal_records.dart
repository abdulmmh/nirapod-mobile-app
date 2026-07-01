class ItrRecord {
  final int id;
  final int taxpayerId;
  final String assessmentYear;
  final double? grossTax;
  final double? rebate;
  final double? netTaxPayable;
  final double? advanceTaxPaid;
  final double? withholdingTax;
  final double? taxPaid;
  final String status;
  final String? submissionDate;

  ItrRecord({
    required this.id,
    required this.taxpayerId,
    required this.assessmentYear,
    this.grossTax,
    this.rebate,
    this.netTaxPayable,
    this.advanceTaxPaid,
    this.withholdingTax,
    this.taxPaid,
    required this.status,
    this.submissionDate,
  });

  factory ItrRecord.fromJson(Map<String, dynamic> json) {
    return ItrRecord(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      assessmentYear: json['assessmentYear'] ?? '',
      grossTax: json['grossTax'] != null ? double.tryParse(json['grossTax'].toString()) : null,
      rebate: json['rebate'] != null ? double.tryParse(json['rebate'].toString()) : null,
      netTaxPayable: json['netTaxPayable'] != null ? double.tryParse(json['netTaxPayable'].toString()) : null,
      advanceTaxPaid: json['advanceTaxPaid'] != null ? double.tryParse(json['advanceTaxPaid'].toString()) : null,
      withholdingTax: json['withholdingTax'] != null ? double.tryParse(json['withholdingTax'].toString()) : null,
      taxPaid: json['taxPaid'] != null ? double.tryParse(json['taxPaid'].toString()) : null,
      status: json['status'] ?? 'Draft',
      submissionDate: json['submissionDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'assessmentYear': assessmentYear,
      'grossTax': grossTax,
      'rebate': rebate,
      'netTaxPayable': netTaxPayable,
      'advanceTaxPaid': advanceTaxPaid,
      'withholdingTax': withholdingTax,
      'taxPaid': taxPaid,
      'status': status,
      'submissionDate': submissionDate,
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
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      source: json['source'] ?? '',
      challanNo: json['challanNo'] ?? '',
      date: json['date'] ?? json['submissionDate'],
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

  Notice({
    required this.id,
    required this.title,
    required this.message,
    required this.status,
    this.date,
    this.noticeType,
    this.replyMessage,
    this.replyDate,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? json['content'] ?? '',
      status: json['status'] ?? 'Unread',
      date: json['date'] ?? json['createdAt'] ?? json['issueDate'],
      noticeType: json['noticeType'],
      replyMessage: json['replyMessage'],
      replyDate: json['replyDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'status': status,
      'date': date,
      'noticeType': noticeType,
      'replyMessage': replyMessage,
      'replyDate': replyDate,
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

  Payment({
    required this.id,
    required this.challanNo,
    required this.amount,
    this.date,
    required this.status,
    this.paymentType,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      challanNo: json['challanNo'] ?? '',
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      date: json['date'] ?? json['paymentDate'] ?? json['createdAt'],
      status: json['status'] ?? 'Pending',
      paymentType: json['paymentType'],
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

  Audit({
    required this.id,
    required this.taxpayerId,
    required this.year,
    required this.status,
    this.description,
    this.demandAmount,
  });

  factory Audit.fromJson(Map<String, dynamic> json) {
    return Audit(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      year: json['year'] ?? json['auditYear'] ?? '',
      status: json['status'] ?? 'Initiated',
      description: json['description'] ?? json['comments'] ?? json['findings'],
      demandAmount: json['demandAmount'] != null ? double.tryParse(json['demandAmount'].toString()) : null,
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

  Appeal({
    required this.id,
    required this.taxpayerId,
    required this.caseNo,
    required this.status,
    this.description,
    this.hearingDate,
  });

  factory Appeal.fromJson(Map<String, dynamic> json) {
    return Appeal(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      caseNo: json['caseNo'] ?? json['appealNumber'] ?? '',
      status: json['status'] ?? 'Filed',
      description: json['description'] ?? json['groundsOfAppeal'] ?? json['remarks'],
      hearingDate: json['hearingDate'],
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
    };
  }
}
