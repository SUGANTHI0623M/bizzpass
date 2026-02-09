import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

class StaffRepository {
  StaffRepository()
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

  Future<List<Staff>> fetchStaff({
    String? search,
    String tab = 'all',
    String? department,
    String? joiningDateFrom,
    String? joiningDateTo,
    int? branchId,
  }) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (tab != 'all') queryParams['tab'] = tab;
      if (department != null && department.isNotEmpty)
        queryParams['department'] = department;
      if (joiningDateFrom != null && joiningDateFrom.isNotEmpty)
        queryParams['joiningDateFrom'] = joiningDateFrom;
      if (joiningDateTo != null && joiningDateTo.isNotEmpty)
        queryParams['joiningDateTo'] = joiningDateTo;
      if (branchId != null) queryParams['branchId'] = branchId;
      final res = await _dio.get<Map<String, dynamic>>(
        '/staff',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw StaffException('Failed to fetch staff');
      }
      final list = res.data!['staff'] as List<dynamic>? ?? [];
      return list
          .map((e) => Staff.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw StaffException(_handleDioError(e));
    }
  }

  /// Get a single staff by id.
  Future<Staff> getStaff(int staffId) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/staff/$staffId');
      if (res.statusCode != 200 || res.data == null) {
        throw StaffException('Failed to fetch staff');
      }
      return Staff.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw StaffException(_handleDioError(e));
    }
  }

  /// License usage for company admin (current users, max users, license active).
  Future<Map<String, dynamic>> getStaffLimits() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/staff/limits');
      if (res.statusCode != 200 || res.data == null) {
        return {'currentUsers': 0, 'maxUsers': null, 'licenseActive': false};
      }
      final d = res.data!;
      return {
        'currentUsers': (d['currentUsers'] as num?)?.toInt() ?? 0,
        'maxUsers': (d['maxUsers'] as num?)?.toInt(),
        'licenseActive': (d['licenseActive'] as bool?) ?? false,
      };
    } on DioException catch (e) {
      throw StaffException(_handleDioError(e));
    }
  }

  /// Create staff (and optional login user). Company admin only.
  Future<Staff> createStaff({
    required String fullName,
    required String email,
    String? phone,
    String? employeeId,
    String? department,
    String? designation,
    String? joiningDate,
    int? branchId,
    String loginMethod = 'password',
    String? temporaryPassword,
    required int roleId,
    String status = 'active',
    int? attendanceModalId,
    int? leaveModalId,
    int? holidayModalId,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'fullName': fullName,
        'email': email.trim().toLowerCase(),
        'phone': phone?.trim(),
        'employeeId': employeeId?.trim(),
        'department': department?.trim(),
        'designation': designation?.trim(),
        'joiningDate': joiningDate,
        'branchId': branchId,
        'loginMethod': loginMethod,
        'temporaryPassword': temporaryPassword,
        'roleId': roleId,
        'status': status,
      };
      if (attendanceModalId != null)
        data['attendanceModalId'] = attendanceModalId;
      if (leaveModalId != null) data['leaveModalId'] = leaveModalId;
      if (holidayModalId != null) data['holidayModalId'] = holidayModalId;
      final res = await _dio.post<Map<String, dynamic>>(
        '/staff',
        data: data,
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        final detail = d is Map ? (d as Map)['detail'] : null;
        throw StaffException(detail?.toString() ?? 'Failed to create staff');
      }
      return Staff.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      throw StaffException(_handleDioError(e));
    }
  }

  /// Update staff. Company admin only.
  Future<Staff> updateStaff(
    int staffId, {
    String? fullName,
    String? phone,
    String? department,
    String? designation,
    String? status,
    int? roleId,
    int? branchId,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (department != null) data['department'] = department;
      if (designation != null) data['designation'] = designation;
      if (status != null) data['status'] = status;
      if (roleId != null) data['roleId'] = roleId;
      if (branchId != null) data['branchId'] = branchId;
      final res = await _dio.patch<Map<String, dynamic>>(
        '/staff/$staffId',
        data: data,
      );
      if (res.statusCode != 200) {
        final d = res.data;
        final detail = d is Map ? (d as Map)['detail'] : null;
        throw StaffException(detail?.toString() ?? 'Failed to update staff');
      }
      return Staff.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      throw StaffException(_handleDioError(e));
    }
  }
}

class StaffException implements Exception {
  final String message;
  StaffException(this.message);
  @override
  String toString() => message;
}
