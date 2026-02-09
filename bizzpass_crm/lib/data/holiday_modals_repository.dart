import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class HolidayModal {
  final int id;
  final String name;
  final String patternType;
  final List<int> customDays;
  final bool isActive;

  HolidayModal({
    required this.id,
    required this.name,
    required this.patternType,
    this.customDays = const [],
    this.isActive = true,
  });

  factory HolidayModal.fromJson(Map<String, dynamic> j) {
    final custom = j['customDays'];
    List<int> days = [];
    if (custom is List) {
      for (final e in custom) {
        if (e is int) days.add(e);
        if (e is num) days.add(e.toInt());
      }
    }
    return HolidayModal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      patternType: (j['patternType'] as String?) ?? 'sundays',
      customDays: days,
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }

  String get patternLabel {
    switch (patternType) {
      case 'sundays':
        return 'Sundays Holiday';
      case 'odd_saturday':
        return 'Odd Saturday Holiday';
      case 'even_saturday':
        return 'Even Saturday Holiday';
      case 'all_saturday':
        return 'All Saturday Holiday';
      case 'custom':
        return 'Custom';
      default:
        return patternType;
    }
  }
}

class HolidayModalsRepository {
  HolidayModalsRepository()
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

  Future<List<HolidayModal>> fetchModals() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/holiday-modals');
    if (res.statusCode != 200 || res.data == null) {
      throw HolidayModalsException('Failed to fetch holiday modals');
    }
    final list = res.data!['modals'] as List<dynamic>? ?? [];
    return list
        .map((e) => HolidayModal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<HolidayModal> createModal({
    required String name,
    required String patternType,
    List<int>? customDays,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'name': name,
      'patternType': patternType,
      if (customDays != null) 'customDays': customDays,
    };
    final res = await _dio.post<Map<String, dynamic>>('/holiday-modals', data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw HolidayModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create holiday modal',
      );
    }
    return HolidayModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<HolidayModal> updateModal(
    int id, {
    String? name,
    String? patternType,
    List<int>? customDays,
    bool? isActive,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (patternType != null) data['patternType'] = patternType;
    if (customDays != null) data['customDays'] = customDays;
    if (isActive != null) data['isActive'] = isActive;
    final res = await _dio.patch<Map<String, dynamic>>('/holiday-modals/$id', data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw HolidayModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to update holiday modal',
      );
    }
    return HolidayModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteModal(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/holiday-modals/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw HolidayModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete holiday modal',
      );
    }
  }
}

class HolidayModalsException implements Exception {
  final String message;
  HolidayModalsException(this.message);
  @override
  String toString() => message;
}
