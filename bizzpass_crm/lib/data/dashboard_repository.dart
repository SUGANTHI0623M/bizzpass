import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

class DashboardRepository {
  DashboardRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  final AuthRepository _auth = AuthRepository();

  Future<void> _addAuthToken() async {
    final token = await _auth.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        (e.type == DioExceptionType.unknown && e.response == null)) {
      return 'Cannot reach the backend at ${ApiConstants.baseUrl}. Ensure it is running.';
    }
    if (e.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<DashboardStats> fetchStats() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard');
      if (res.statusCode != 200 || res.data == null) {
        throw DashboardException('Failed to fetch dashboard stats');
      }
      return DashboardStats.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      throw DashboardException(_handleDioError(e));
    }
  }

  Future<List<Company>> fetchCompanies() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/companies');
      if (res.statusCode != 200 || res.data == null) {
        throw DashboardException('Failed to fetch companies');
      }
      final list = res.data!['companies'] as List<dynamic>? ?? [];
      return list
          .map((e) => Company.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw DashboardException(_handleDioError(e));
    }
  }

  Future<List<License>> fetchLicenses() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/licenses');
      if (res.statusCode != 200 || res.data == null) {
        throw DashboardException('Failed to fetch licenses');
      }
      final list = res.data!['licenses'] as List<dynamic>? ?? [];
      return list
          .map((e) => License.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw DashboardException(_handleDioError(e));
    }
  }

  Future<List<Payment>> fetchPayments() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/payments');
      if (res.statusCode != 200 || res.data == null) {
        throw DashboardException('Failed to fetch payments');
      }
      final list = res.data!['payments'] as List<dynamic>? ?? [];
      return list
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw DashboardException(_handleDioError(e));
    }
  }
}

class DashboardStats {
  final int activeCompanies;
  final int totalCompanies;
  final int activeLicenses;
  final int expiredLicenses;
  final int suspendedLicenses;
  final int unassignedLicenses;
  final int totalRevenue;
  final int paymentCount;
  final int totalStaff;

  const DashboardStats({
    required this.activeCompanies,
    required this.totalCompanies,
    required this.activeLicenses,
    required this.expiredLicenses,
    required this.suspendedLicenses,
    required this.unassignedLicenses,
    required this.totalRevenue,
    required this.paymentCount,
    required this.totalStaff,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) {
    return DashboardStats(
      activeCompanies: (j['activeCompanies'] as num?)?.toInt() ?? 0,
      totalCompanies: (j['totalCompanies'] as num?)?.toInt() ?? 0,
      activeLicenses: (j['activeLicenses'] as num?)?.toInt() ?? 0,
      expiredLicenses: (j['expiredLicenses'] as num?)?.toInt() ?? 0,
      suspendedLicenses: (j['suspendedLicenses'] as num?)?.toInt() ?? 0,
      unassignedLicenses: (j['unassignedLicenses'] as num?)?.toInt() ?? 0,
      totalRevenue: (j['totalRevenue'] as num?)?.toInt() ?? 0,
      paymentCount: (j['paymentCount'] as num?)?.toInt() ?? 0,
      totalStaff: (j['totalStaff'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardException implements Exception {
  final String message;
  DashboardException(this.message);
  @override
  String toString() => message;
}
