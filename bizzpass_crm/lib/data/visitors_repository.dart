import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for visitors.
class VisitorsRepository {
  VisitorsRepository()
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

  /// Fetch all visitors.
  Future<List<Visitor>> fetchVisitors() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/visitors');
      if (res.statusCode != 200 || res.data == null) {
        throw VisitorsException('Failed to fetch visitors');
      }
      final list = res.data!['visitors'] as List<dynamic>? ?? [];
      return list
          .map((e) => Visitor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw VisitorsException(_handleDioError(e));
    }
  }

  /// Register a new visitor.
  Future<Visitor> registerVisitor({
    required String visitorName,
    String? visitorPhone,
    String? visitorCompany,
    required int companyId,
    int? hostEmployeeId,
    String? hostName,
    String? purpose,
    String? idProofType,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{
      'visitor_name': visitorName.trim(),
      'company_id': companyId,
    };
    if (visitorPhone != null && visitorPhone.isNotEmpty) {
      body['visitor_phone'] = visitorPhone.trim();
    }
    if (visitorCompany != null && visitorCompany.isNotEmpty) {
      body['visitor_company'] = visitorCompany.trim();
    }
    if (hostEmployeeId != null) body['host_employee_id'] = hostEmployeeId;
    if (hostName != null && hostName.isNotEmpty) {
      body['host_name'] = hostName.trim();
    }
    if (purpose != null && purpose.isNotEmpty) body['purpose'] = purpose.trim();
    if (idProofType != null && idProofType.isNotEmpty) {
      body['id_proof_type'] = idProofType;
    }

    try {
      final res =
          await _dio.post<Map<String, dynamic>>('/visitors', data: body);
      if (res.statusCode != 200 || res.data == null) {
        final detail = res.data is Map && res.data!['detail'] != null
            ? res.data!['detail'].toString()
            : 'Failed to register visitor';
        throw VisitorsException(detail);
      }
      return Visitor.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      throw VisitorsException(_handleDioError(e));
    }
  }

  /// Check in a visitor.
  Future<void> checkInVisitor(int visitorId) async {
    await _addAuthToken();
    try {
      final res = await _dio.post('/visitors/$visitorId/check-in');
      if (res.statusCode != 200) {
        throw VisitorsException('Failed to check in visitor');
      }
    } on DioException catch (e) {
      throw VisitorsException(_handleDioError(e));
    }
  }

  /// Check out a visitor.
  Future<void> checkOutVisitor(int visitorId) async {
    await _addAuthToken();
    try {
      final res = await _dio.post('/visitors/$visitorId/check-out');
      if (res.statusCode != 200) {
        throw VisitorsException('Failed to check out visitor');
      }
    } on DioException catch (e) {
      throw VisitorsException(_handleDioError(e));
    }
  }
}

class VisitorsException implements Exception {
  final String message;
  VisitorsException(this.message);
  @override
  String toString() => message;
}
