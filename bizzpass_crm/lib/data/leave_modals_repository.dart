import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class LeaveModal {
  final int id;
  final String name;
  final String description;
  final List<dynamic> leaveTypes;
  final bool isActive;

  LeaveModal({
    required this.id,
    required this.name,
    required this.description,
    required this.leaveTypes,
    required this.isActive,
  });

  factory LeaveModal.fromJson(Map<String, dynamic> j) {
    return LeaveModal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      leaveTypes: (j['leaveTypes'] as List<dynamic>?) ?? [],
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }
}

class LeaveModalsRepository {
  LeaveModalsRepository()
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

  Future<List<LeaveModal>> fetchModals() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/leave-modals');
    if (res.statusCode != 200 || res.data == null) {
      throw LeaveModalsException('Failed to fetch leave modals');
    }
    final list = res.data!['modals'] as List<dynamic>? ?? [];
    return list
        .map((e) => LeaveModal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LeaveModal> createModal({
    required String name,
    String? description,
    List<dynamic>? leaveTypes,
    bool isActive = true,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'name': name,
      'description': description ?? '',
      'leaveTypes': leaveTypes ?? [],
      'isActive': isActive,
    };
    final res =
        await _dio.post<Map<String, dynamic>>('/leave-modals', data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw LeaveModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create leave modal',
      );
    }
    return LeaveModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<LeaveModal> updateModal(
    int id, {
    String? name,
    String? description,
    List<dynamic>? leaveTypes,
    bool? isActive,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (leaveTypes != null) data['leaveTypes'] = leaveTypes;
    if (isActive != null) data['isActive'] = isActive;
    final res =
        await _dio.patch<Map<String, dynamic>>('/leave-modals/$id', data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw LeaveModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to update leave modal',
      );
    }
    return LeaveModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteModal(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/leave-modals/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw LeaveModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete leave modal',
      );
    }
  }
}

class LeaveModalsException implements Exception {
  final String message;
  LeaveModalsException(this.message);
  @override
  String toString() => message;
}
