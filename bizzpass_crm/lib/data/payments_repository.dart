import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for payments.
class PaymentsRepository {
  PaymentsRepository()
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

  /// Fetch payments with optional search.
  Future<List<Payment>> fetchPayments({String? search}) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final res = await _dio.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw PaymentsException('Failed to fetch payments');
      }
      final list = res.data!['payments'] as List<dynamic>? ?? [];
      return list
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw PaymentsException(_handleDioError(e));
    }
  }
}

class PaymentsException implements Exception {
  final String message;
  PaymentsException(this.message);
  @override
  String toString() => message;
}
