import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for notifications.
class NotificationsRepository {
  NotificationsRepository()
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

  /// Fetch all notifications.
  Future<List<AppNotification>> fetchNotifications() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/notifications');
      if (res.statusCode != 200 || res.data == null) {
        throw NotificationsException('Failed to fetch notifications');
      }
      final list = res.data!['notifications'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw NotificationsException(_handleDioError(e));
    }
  }
}

class NotificationsException implements Exception {
  final String message;
  NotificationsException(this.message);
  @override
  String toString() => message;
}
