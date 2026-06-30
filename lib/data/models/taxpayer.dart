class Taxpayer {
  final int id;
  final String? fullName;
  final String? companyName;
  final String? tin;
  final String? nid;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? profession;
  final String? fathersName;
  final String? mothersName;
  final Address? presentAddress;
  final String? photoPath;
  final String? approvalStatus;
  final TaxpayerType? taxpayerType;
  final String? rjscNo;
  final String? natureOfBusiness;
  final String? authorizedPersonName;
  final String? authorizedPersonNid;

  Taxpayer({
    required this.id,
    this.fullName,
    this.companyName,
    this.tin,
    this.nid,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.profession,
    this.fathersName,
    this.mothersName,
    this.presentAddress,
    this.photoPath,
    this.approvalStatus,
    this.taxpayerType,
    this.rjscNo,
    this.natureOfBusiness,
    this.authorizedPersonName,
    this.authorizedPersonNid,
  });

  factory Taxpayer.fromJson(Map<String, dynamic> json) {
    return Taxpayer(
      id: json['id'] ?? 0,
      fullName: json['fullName'],
      companyName: json['companyName'],
      tin: json['tin'],
      nid: json['nid'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
      profession: json['profession'],
      fathersName: json['fathersName'],
      mothersName: json['mothersName'],
      presentAddress: json['presentAddress'] != null 
          ? Address.fromJson(json['presentAddress']) 
          : null,
      photoPath: json['photoPath'],
      approvalStatus: json['approvalStatus'],
      taxpayerType: json['taxpayerType'] != null
          ? TaxpayerType.fromJson(json['taxpayerType'])
          : null,
      rjscNo: json['rjscNo'],
      natureOfBusiness: json['natureOfBusiness'],
      authorizedPersonName: json['authorizedPersonName'],
      authorizedPersonNid: json['authorizedPersonNid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'companyName': companyName,
      'tin': tin,
      'nid': nid,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'email': email,
      'profession': profession,
      'fathersName': fathersName,
      'mothersName': mothersName,
      'presentAddress': presentAddress?.toJson(),
      'photoPath': photoPath,
      'approvalStatus': approvalStatus,
      'taxpayerType': taxpayerType?.toJson(),
      'rjscNo': rjscNo,
      'natureOfBusiness': natureOfBusiness,
      'authorizedPersonName': authorizedPersonName,
      'authorizedPersonNid': authorizedPersonNid,
    };
  }
}

class Address {
  final String? division;
  final String? district;
  final String? details;

  Address({this.division, this.district, this.details});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      division: json['division'],
      district: json['district'],
      details: json['details'] ?? json['addressLine1'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'division': division,
      'district': district,
      'details': details,
    };
  }
}

class TaxpayerType {
  final String? category; // Individual, Business, Organization
  final String? typeName;

  TaxpayerType({this.category, this.typeName});

  factory TaxpayerType.fromJson(Map<String, dynamic> json) {
    return TaxpayerType(
      category: json['category'],
      typeName: json['typeName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'typeName': typeName,
    };
  }
}

class TinRecord {
  final int id;
  final int taxpayerId;
  final String tinNumber;
  final String? zone;
  final String? circle;
  final String? status;
  final String? issueDate;

  TinRecord({
    required this.id,
    required this.taxpayerId,
    required this.tinNumber,
    this.zone,
    this.circle,
    this.status,
    this.issueDate,
  });

  factory TinRecord.fromJson(Map<String, dynamic> json) {
    return TinRecord(
      id: json['id'] ?? 0,
      taxpayerId: json['taxpayerId'] ?? 0,
      tinNumber: json['tinNumber'] ?? '',
      zone: json['zone'],
      circle: json['circle'],
      status: json['status'],
      issueDate: json['issueDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taxpayerId': taxpayerId,
      'tinNumber': tinNumber,
      'zone': zone,
      'circle': circle,
      'status': status,
      'issueDate': issueDate,
    };
  }
}
