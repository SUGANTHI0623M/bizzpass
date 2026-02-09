import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class AttendanceModal {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final bool requireGeolocation;
  final bool requireSelfie;
  final bool allowAttendanceOnHolidays;
  final bool allowAttendanceOnWeeklyOff;
  final bool allowLateEntry;
  final bool allowEarlyExit;
  final bool allowOvertime;

  AttendanceModal({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.requireGeolocation,
    required this.requireSelfie,
    required this.allowAttendanceOnHolidays,
    required this.allowAttendanceOnWeeklyOff,
    required this.allowLateEntry,
    required this.allowEarlyExit,
    required this.allowOvertime,
  });

  factory AttendanceModal.fromJson(Map<String, dynamic> j) {
    return AttendanceModal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
      requireGeolocation: (j['requireGeolocation'] as bool?) ?? false,
      requireSelfie: (j['requireSelfie'] as bool?) ?? false,
      allowAttendanceOnHolidays: (j['allowAttendanceOnHolidays'] as bool?) ?? false,
      allowAttendanceOnWeeklyOff: (j['allowAttendanceOnWeeklyOff'] as bool?) ?? false,
      allowLateEntry: (j['allowLateEntry'] as bool?) ?? true,
      allowEarlyExit: (j['allowEarlyExit'] as bool?) ?? true,
      allowOvertime: (j['allowOvertime'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isActive': isActive,
        'requireGeolocation': requireGeolocation,
        'requireSelfie': requireSelfie,
        'allowAttendanceOnHolidays': allowAttendanceOnHolidays,
        'allowAttendanceOnWeeklyOff': allowAttendanceOnWeeklyOff,
        'allowLateEntry': allowLateEntry,
        'allowEarlyExit': allowEarlyExit,
        'allowOvertime': allowOvertime,
      };
}

class AttendanceModalsRepository {
  AttendanceModalsRepository()
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

  Future<List<AttendanceModal>> fetchModals() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/attendance-modals');
    if (res.statusCode != 200 || res.data == null) {
      throw AttendanceModalsException('Failed to fetch attendance modals');
    }
    final list = res.data!['modals'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            AttendanceModal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AttendanceModal> createModal({
    required String name,
    String? description,
    bool isActive = true,
    bool requireGeolocation = false,
    bool requireSelfie = false,
    bool allowAttendanceOnHolidays = false,
    bool allowAttendanceOnWeeklyOff = false,
    bool allowLateEntry = true,
    bool allowEarlyExit = true,
    bool allowOvertime = true,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'isActive': isActive,
      'requireGeolocation': requireGeolocation,
      'requireSelfie': requireSelfie,
      'allowAttendanceOnHolidays': allowAttendanceOnHolidays,
      'allowAttendanceOnWeeklyOff': allowAttendanceOnWeeklyOff,
      'allowLateEntry': allowLateEntry,
      'allowEarlyExit': allowEarlyExit,
      'allowOvertime': allowOvertime,
    };
    final res = await _dio.post<Map<String, dynamic>>('/attendance-modals',
        data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw AttendanceModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create attendance modal',
      );
    }
    return AttendanceModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<AttendanceModal> updateModal(
    int id, {
    String? name,
    String? description,
    bool? isActive,
    bool? requireGeolocation,
    bool? requireSelfie,
    bool? allowAttendanceOnHolidays,
    bool? allowAttendanceOnWeeklyOff,
    bool? allowLateEntry,
    bool? allowEarlyExit,
    bool? allowOvertime,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;
    if (requireGeolocation != null) data['requireGeolocation'] = requireGeolocation;
    if (requireSelfie != null) data['requireSelfie'] = requireSelfie;
    if (allowAttendanceOnHolidays != null) {
      data['allowAttendanceOnHolidays'] = allowAttendanceOnHolidays;
    }
    if (allowAttendanceOnWeeklyOff != null) {
      data['allowAttendanceOnWeeklyOff'] = allowAttendanceOnWeeklyOff;
    }
    if (allowLateEntry != null) data['allowLateEntry'] = allowLateEntry;
    if (allowEarlyExit != null) data['allowEarlyExit'] = allowEarlyExit;
    if (allowOvertime != null) data['allowOvertime'] = allowOvertime;
    final res =
        await _dio.patch<Map<String, dynamic>>('/attendance-modals/$id',
            data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw AttendanceModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to update attendance modal',
      );
    }
    return AttendanceModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteModal(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/attendance-modals/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw AttendanceModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete attendance modal',
      );
    }
  }
}

class AttendanceModalsException implements Exception {
  final String message;
  AttendanceModalsException(this.message);
  @override
  String toString() => message;
}
