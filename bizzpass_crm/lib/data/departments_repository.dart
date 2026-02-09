import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> j) {
    return Department(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
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

  Future<List<Department>> fetchDepartments() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/departments');
    if (res.statusCode != 200 || res.data == null) {
      throw DepartmentsException('Failed to fetch departments');
    }
    final list = res.data!['departments'] as List<dynamic>? ?? [];
    return list.map((e) => Department.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Department> createDepartment({required String name}) async {
    await _addAuthToken();
    final res = await _dio.post<Map<String, dynamic>>('/departments', data: {'name': name.trim()});
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw DepartmentsException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to create department',
      );
    }
    return Department.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Department> updateDepartment(int departmentId, {required String name}) async {
    await _addAuthToken();
    final res = await _dio.patch<Map<String, dynamic>>('/departments/$departmentId', data: {'name': name.trim()});
    if (res.statusCode != 200) {
      final d = res.data;
      throw DepartmentsException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to update department',
      );
    }
    return Department.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteDepartment(int departmentId) async {
    await _addAuthToken();
    final res = await _dio.delete('/departments/$departmentId');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw DepartmentsException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to delete department',
      );
    }
  }
}

class DepartmentsException implements Exception {
  final String message;
  DepartmentsException(this.message);
  @override
  String toString() => message;
}
