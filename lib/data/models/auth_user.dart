class AuthUser {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String token;
  final int? taxpayerId;
  final String? taxpayerType;
  final String? tinNumber;
  final String? photoUrl;
  final String? approvalStatus;

  AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
    this.taxpayerId,
    this.taxpayerType,
    this.tinNumber,
    this.photoUrl,
    this.approvalStatus,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
      taxpayerId: json['taxpayerId'] != null ? int.tryParse(json['taxpayerId'].toString()) ?? json['taxpayerId'] as int? : null,
      taxpayerType: json['taxpayerType'],
      tinNumber: json['tinNumber'],
      photoUrl: json['photoUrl'],
      approvalStatus: json['approvalStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'token': token,
      'taxpayerId': taxpayerId,
      'taxpayerType': taxpayerType,
      'tinNumber': tinNumber,
      'photoUrl': photoUrl,
      'approvalStatus': approvalStatus,
    };
  }
}
