import 'dart:io' show Platform;

class ApiEndpoints {
  // Configurable base URL
  static String get baseUrl {
    // Default emulator loopback for Android; localhost for iOS / Web
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080/api';
      }
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Taxpayer
  static const String taxpayersMe = '/taxpayers/me';
  static String taxpayerDetails(int id) => '/taxpayers/$id';
  static String taxpayerUpdate(int id) => '/taxpayers/$id';
  static String taxpayerUploadPhoto(int id) => '/taxpayers/$id/photo';

  // Businesses
  static const String businessList = '/businesses';
  static String businessDetails(int id) => '/businesses/$id';

  // TIN Management
  static const String tins = '/tins';
  static String tinByTaxpayer(int taxpayerId) => '/tins/my-tin/$taxpayerId';

  // VAT
  static const String vatRegistrations = '/vat-registrations';
  static const String vatReturns = '/vat-returns';

  // Income Tax Returns (ITR)
  static const String incomeTaxReturns = '/income-tax-returns';
  static const String itrPreview = '/income-tax-returns/preview';

  // AIT
  static const String aitRecords = '/ait-records';
  static String aitDocuments(int aitId) => '/ait-records/$aitId/documents';
  static String aitVerifyChallan(int id) => '/ait-records/$id/verify-challan';
  static String aitSubmit(int id) => '/ait-records/$id/submit';

  // Payments
  static const String payments = '/payments';
  static String outstandingPayments(int taxpayerId) => '/payments/outstanding?taxpayerId=$taxpayerId';

  // Notices
  static const String noticesMy = '/notices/my';
  static const String noticesList = '/notices';
  static String noticeRead(int id) => '/notices/$id/read';
  static String noticeRespond(int id) => '/notices/$id/respond';

  // Audits (Taxpayer portal views)
  static const String auditsMy = '/my-portal/audits/my';
  static String auditDetails(int id) => '/my-portal/audits/$id';
  static String auditRespond(int id) => '/my-portal/audits/$id/respond';

  // Appeals (Taxpayer portal views)
  static const String appealsMy = '/my-portal/appeals';
  static String appealDetails(int id) => '/my-portal/appeals/$id';
  static String appealWithdraw(int id) => '/my-portal/appeals/$id/withdraw';
}
