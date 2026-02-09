import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class LeaveCategory {
  final int id;
  final String name;
  final bool isActive;

  LeaveCategory({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory LeaveCategory.fromJson(Map<String, dynamic> j) {
    return LeaveCategory(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }
}

class LeaveCategoriesRepository {
  LeaveCategoriesRepository()
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

  Future<List<LeaveCategory>> fetchCategories() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/leave-categories');
    if (res.statusCode != 200 || res.data == null) {
      throw LeaveCategoriesException('Failed to fetch leave categories');
    }
    final list = res.data!['categories'] as List<dynamic>? ?? [];
    return list
        .map((e) => LeaveCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    } on DioException catch (e) {
      throw LeaveCategoriesException(_handleDioError(e));
    }
  }

  Future<LeaveCategory> createCategory({required String name}) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/leave-categories',
        data: {'name': name.trim()},
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        throw LeaveCategoriesException(
          (d is Map<String, dynamic> && d['detail'] != null)
              ? d['detail'].toString()
              : 'Failed to create category',
        );
      }
      return LeaveCategory.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw LeaveCategoriesException(_handleDioError(e));
    }
  }

  Future<LeaveCategory> updateCategory(int id, {String? name, bool? isActive}) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (isActive != null) data['isActive'] = isActive;
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/leave-categories/$id',
        data: data,
      );
      if (res.statusCode != 200) {
        final d = res.data;
        throw LeaveCategoriesException(
          (d is Map<String, dynamic> && d['detail'] != null)
              ? d['detail'].toString()
              : 'Failed to update category',
        );
      }
      return LeaveCategory.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw LeaveCategoriesException(_handleDioError(e));
    }
  }

  Future<void> deleteCategory(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/leave-categories/$id');
      if (res.statusCode != 200 && res.statusCode != 204) {
        final d = res.data;
        throw LeaveCategoriesException(
          (d is Map<String, dynamic> && d['detail'] != null)
              ? d['detail'].toString()
              : 'Failed to delete category',
        );
      }
    } on DioException catch (e) {
      throw LeaveCategoriesException(_handleDioError(e));
    }
  }
}

class LeaveCategoriesException implements Exception {
  final String message;
  LeaveCategoriesException(this.message);
  @override
  String toString() => message;
}
