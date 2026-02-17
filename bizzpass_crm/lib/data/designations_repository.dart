import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Designation {
  final int id;
  final String name;
  final bool active;
  final String? createdAt;

  Designation({required this.id, required this.name, this.active = true, this.createdAt});

  factory Designation.fromJson(Map<String, dynamic> j) {
    return Designation(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      active: j['active'] as bool? ?? true,
      createdAt: j['createdAt'] as String?,
    );
  }
}

class DesignationsRepository {
  DesignationsRepository()
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
      return 'Cannot reach the backend at ${ApiConstants.baseUrl}. ${ApiConstants.backendUnreachableHint}';
    }
    if (e.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<List<Designation>> fetchDesignations({
    bool? activeOnly,
    bool? active,
    String? search,
  }) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (activeOnly == true) queryParams['active'] = true;
      if (active != null) queryParams['active'] = active;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
      final res = await _dio.get<Map<String, dynamic>>(
        '/designations',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw DesignationsException('Failed to fetch designations');
      }
      final list = res.data!['designations'] as List<dynamic>? ?? [];
      return list.map((e) => Designation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw DesignationsException(_handleDioError(e));
    }
  }

  Future<Designation> createDesignation({required String name, bool active = true}) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/designations',
        data: {'name': name.trim(), 'active': active},
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        throw DesignationsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to create designation',
        );
      }
      return Designation.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw DesignationsException(_handleDioError(e));
    }
  }

  Future<Designation> updateDesignation(
    int designationId, {
    String? name,
    bool? active,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (active != null) data['active'] = active;
      final res = await _dio.patch<Map<String, dynamic>>(
        '/designations/$designationId',
        data: data.isNotEmpty ? data : null,
      );
      if (res.statusCode != 200) {
        final d = res.data;
        throw DesignationsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to update designation',
        );
      }
      return Designation.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw DesignationsException(_handleDioError(e));
    }
  }

  Future<void> deleteDesignation(int designationId) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/designations/$designationId');
      if (res.statusCode != 200 && res.statusCode != 204) {
        final d = res.data;
        throw DesignationsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to delete designation',
        );
      }
    } on DioException catch (e) {
      throw DesignationsException(_handleDioError(e));
    }
  }
}

class DesignationsException implements Exception {
  final String message;
  DesignationsException(this.message);
  @override
  String toString() => message;
}
