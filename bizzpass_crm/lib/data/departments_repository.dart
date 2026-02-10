import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Department {
  final int id;
  final String name;
  final bool active;

  Department({required this.id, required this.name, this.active = true});

  factory Department.fromJson(Map<String, dynamic> j) {
    return Department(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      active: j['active'] as bool? ?? true,
    );
  }
}

class DepartmentsRepository {
  DepartmentsRepository()
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

  /// [activeOnly] if true returns only active departments (e.g. for staff dropdown). Omit for all.
  /// [active] filter: true = active only, false = inactive only, null = all.
  /// [search] filter by name (server-side).
  Future<List<Department>> fetchDepartments({
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
        '/departments',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw DepartmentsException('Failed to fetch departments');
      }
      final list = res.data!['departments'] as List<dynamic>? ?? [];
      return list.map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw DepartmentsException(_handleDioError(e));
    }
  }

  Future<Department> createDepartment({required String name, bool active = true}) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/departments',
        data: {'name': name.trim(), 'active': active},
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        throw DepartmentsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to create department',
        );
      }
      return Department.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw DepartmentsException(_handleDioError(e));
    }
  }

  Future<Department> updateDepartment(
    int departmentId, {
    String? name,
    bool? active,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (active != null) data['active'] = active;
      final res = await _dio.patch<Map<String, dynamic>>(
        '/departments/$departmentId',
        data: data.isNotEmpty ? data : null,
      );
      if (res.statusCode != 200) {
        final d = res.data;
        throw DepartmentsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to update department',
        );
      }
      return Department.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw DepartmentsException(_handleDioError(e));
    }
  }

  Future<void> deleteDepartment(int departmentId) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/departments/$departmentId');
      if (res.statusCode != 200 && res.statusCode != 204) {
        final d = res.data;
        throw DepartmentsException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to delete department',
        );
      }
    } on DioException catch (e) {
      throw DepartmentsException(_handleDioError(e));
    }
  }
}

class DepartmentsException implements Exception {
  final String message;
  DepartmentsException(this.message);
  @override
  String toString() => message;
}
