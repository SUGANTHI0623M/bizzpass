import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

class AttendanceRepository {
  AttendanceRepository()
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

  Future<List<AttendanceRecord>> fetchTodayAttendance() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/attendance/today');
      if (res.statusCode != 200 || res.data == null) {
        throw AttendanceException('Failed to fetch attendance');
      }
      final list = res.data!['attendance'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              AttendanceRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw AttendanceException(_handleDioError(e));
    }
  }
}

class AttendanceException implements Exception {
  final String message;
  AttendanceException(this.message);
  @override
  String toString() => message;
}
