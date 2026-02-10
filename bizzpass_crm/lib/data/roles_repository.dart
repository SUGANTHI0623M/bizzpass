import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Role {
  final int id;
  final String code, name;
  final String? description;
  final int? companyId;
  final bool isSystemRole;
  final List<String> permissionCodes;
  final int staffCount;

  Role({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.companyId,
    required this.isSystemRole,
    required this.permissionCodes,
    this.staffCount = 0,
  });

  factory Role.fromJson(Map<String, dynamic> j) {
    final codes = j['permissionCodes'] ?? j['permission_codes'];
    return Role(
      id: (j['id'] as num?)?.toInt() ?? 0,
      code: (j['code'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      description: j['description'] as String?,
      companyId: (j['companyId'] as num?)?.toInt(),
      isSystemRole: (j['isSystemRole'] as bool?) ?? false,
      permissionCodes: codes is List
          ? List<String>.from(codes.map((e) => e.toString()))
          : [],
      staffCount: (j['staffCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RolesRepository {
  RolesRepository()
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
    if (e.response?.statusCode == 401) return 'Session expired. Please log in again.';
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<List<Role>> fetchRoles() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/roles');
      if (res.statusCode != 200 || res.data == null) {
        throw RolesException('Failed to fetch roles');
      }
      final list = res.data!['roles'] as List<dynamic>? ?? [];
      return list
          .map((e) => Role.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw RolesException(_handleDioError(e));
    }
  }

  /// Returns map of module -> list of {id, code, description}
  Future<Map<String, List<Map<String, dynamic>>>> fetchPermissions() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/roles/permissions');
      if (res.statusCode != 200 || res.data == null) {
        throw RolesException('Failed to fetch permissions');
      }
      final raw = res.data!['permissions'] as Map<String, dynamic>? ?? {};
      final out = <String, List<Map<String, dynamic>>>{};
      for (final entry in raw.entries) {
        final list = entry.value as List<dynamic>? ?? [];
        out[entry.key] =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return out;
    } on DioException catch (e) {
      throw RolesException(_handleDioError(e));
    }
  }

  Future<Role> createRole({
    required String name,
    String? description,
    List<String> permissionCodes = const [],
  }) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/roles',
        data: {
          'name': name,
          'description': description,
          'permission_codes': permissionCodes,
        },
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        final msg = (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create role';
        throw RolesException(msg);
      }
      final data = res.data;
      if (data == null) {
        throw RolesException('Invalid response from server');
      }
      return Role.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw RolesException(_handleDioError(e));
    }
  }

  Future<void> deleteRole(int roleId) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/roles/$roleId');
      if (res.statusCode != 200 && res.statusCode != 204) {
        final d = res.data;
        final msg = (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete role';
        throw RolesException(msg);
      }
    } on DioException catch (e) {
      throw RolesException(_handleDioError(e));
    }
  }

  Future<Role> updateRole(
    int roleId, {
    String? name,
    String? description,
    List<String>? permissionCodes,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (permissionCodes != null) data['permission_codes'] = permissionCodes;
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/roles/$roleId',
        data: data,
      );
      if (res.statusCode != 200) {
        final d = res.data;
        final detail = d is Map ? (d as Map)['detail'] : null;
        throw RolesException(detail?.toString() ?? 'Failed to update role');
      }
      return Role.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw RolesException(_handleDioError(e));
    }
  }
}

class RolesException implements Exception {
  final String message;
  RolesException(this.message);
  @override
  String toString() => message;
}
