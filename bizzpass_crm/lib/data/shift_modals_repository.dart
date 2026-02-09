import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class ShiftModal {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final int graceMinutes;
  final String graceUnit;
  final bool isActive;

  ShiftModal({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.graceMinutes,
    required this.graceUnit,
    this.isActive = true,
  });

  factory ShiftModal.fromJson(Map<String, dynamic> j) {
    return ShiftModal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      startTime: (j['startTime'] as String?) ?? '',
      endTime: (j['endTime'] as String?) ?? '',
      graceMinutes: (j['graceMinutes'] as num?)?.toInt() ?? 10,
      graceUnit: (j['graceUnit'] as String?) ?? 'Minutes',
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }
}

class ShiftModalsRepository {
  ShiftModalsRepository()
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

  Future<List<ShiftModal>> fetchModals() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/shift-modals');
    if (res.statusCode != 200 || res.data == null) {
      throw ShiftModalsException('Failed to fetch shift modals');
    }
    final list = res.data!['modals'] as List<dynamic>? ?? [];
    return list
        .map((e) => ShiftModal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ShiftModal> createModal({
    required String name,
    required String startTime,
    required String endTime,
    int graceMinutes = 10,
    String graceUnit = 'Minutes',
    bool isActive = true,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      'graceMinutes': graceMinutes,
      'graceUnit': graceUnit,
      'isActive': isActive,
    };
    final res =
        await _dio.post<Map<String, dynamic>>('/shift-modals', data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw ShiftModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create shift modal',
      );
    }
    return ShiftModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<ShiftModal> updateModal(
    int id, {
    String? name,
    String? startTime,
    String? endTime,
    int? graceMinutes,
    String? graceUnit,
    bool? isActive,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (startTime != null) data['startTime'] = startTime;
    if (endTime != null) data['endTime'] = endTime;
    if (graceMinutes != null) data['graceMinutes'] = graceMinutes;
    if (graceUnit != null) data['graceUnit'] = graceUnit;
    if (isActive != null) data['isActive'] = isActive;
    final res =
        await _dio.patch<Map<String, dynamic>>('/shift-modals/$id', data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw ShiftModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to update shift modal',
      );
    }
    return ShiftModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteModal(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/shift-modals/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw ShiftModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete shift modal',
      );
    }
  }
}

class ShiftModalsException implements Exception {
  final String message;
  ShiftModalsException(this.message);
  @override
  String toString() => message;
}
