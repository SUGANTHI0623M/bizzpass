import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

/// Grace rule for late login or early logout.
class GraceRule {
  final bool enabled;
  final int graceMinutesPerDay;
  final int graceCountPerMonth;
  final String resetCycle; // MONTHLY | WEEKLY | NEVER
  final String graceType; // PER_OCCURRENCE | COUNT_BASED | COMBINED
  final int weekStartDay;

  GraceRule({
    required this.enabled,
    required this.graceMinutesPerDay,
    required this.graceCountPerMonth,
    required this.resetCycle,
    required this.graceType,
    this.weekStartDay = 1,
  });

  factory GraceRule.fromJson(Map<String, dynamic> j) {
    return GraceRule(
      enabled: j['enabled'] as bool? ?? true,
      graceMinutesPerDay: (j['graceMinutesPerDay'] as num?)?.toInt() ?? 10,
      graceCountPerMonth: (j['graceCountPerMonth'] as num?)?.toInt() ?? 3,
      resetCycle: j['resetCycle'] as String? ?? 'MONTHLY',
      graceType: j['graceType'] as String? ?? 'PER_OCCURRENCE',
      weekStartDay: (j['weekStartDay'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'graceMinutesPerDay': graceMinutesPerDay,
        'graceCountPerMonth': graceCountPerMonth,
        'resetCycle': resetCycle,
        'graceType': graceType,
        'weekStartDay': weekStartDay,
      };
}

/// Grace config with separate rules for late login and early logout.
class GraceConfig {
  final GraceRule lateLogin;
  final GraceRule earlyLogout;

  GraceConfig({
    required this.lateLogin,
    required this.earlyLogout,
  });

  factory GraceConfig.fromJson(Map<String, dynamic> j) {
    return GraceConfig(
      lateLogin: GraceRule.fromJson(
        Map<String, dynamic>.from(j['lateLogin'] as Map? ?? {}),
      ),
      earlyLogout: GraceRule.fromJson(
        Map<String, dynamic>.from(j['earlyLogout'] as Map? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'lateLogin': lateLogin.toJson(),
        'earlyLogout': earlyLogout.toJson(),
      };
}

class FineModal {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final GraceConfig graceConfig;
  final String fineCalculationMethod; // per_minute | fixed_per_occurrence
  final double? fineFixedAmount;

  FineModal({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.graceConfig,
    required this.fineCalculationMethod,
    this.fineFixedAmount,
  });

  factory FineModal.fromJson(Map<String, dynamic> j) {
    return FineModal(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
      graceConfig: GraceConfig.fromJson(
        Map<String, dynamic>.from(j['graceConfig'] as Map? ?? {}),
      ),
      fineCalculationMethod:
          (j['fineCalculationMethod'] as String?) ?? 'per_minute',
      fineFixedAmount: (j['fineFixedAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'isActive': isActive,
        'graceConfig': graceConfig.toJson(),
        'fineCalculationMethod': fineCalculationMethod,
        'fineFixedAmount': fineFixedAmount,
      };
}

class FineModalsRepository {
  FineModalsRepository()
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

  Future<List<FineModal>> fetchModals() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/fine-modals');
    if (res.statusCode != 200 || res.data == null) {
      throw FineModalsException('Failed to fetch fine modals');
    }
    final list = res.data!['modals'] as List<dynamic>? ?? [];
    return list
        .map((e) =>
            FineModal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<FineModal> createModal({
    required String name,
    String? description,
    bool isActive = true,
    Map<String, dynamic>? graceConfig,
    String fineCalculationMethod = 'per_minute',
    double? fineFixedAmount,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'isActive': isActive,
      'graceConfig': graceConfig,
      'fineCalculationMethod': fineCalculationMethod,
      'fineFixedAmount': fineFixedAmount,
    };
    final res =
        await _dio.post<Map<String, dynamic>>('/fine-modals', data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw FineModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to create fine modal',
      );
    }
    return FineModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<FineModal> updateModal(
    int id, {
    String? name,
    String? description,
    bool? isActive,
    Map<String, dynamic>? graceConfig,
    String? fineCalculationMethod,
    double? fineFixedAmount,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (isActive != null) data['isActive'] = isActive;
    if (graceConfig != null) data['graceConfig'] = graceConfig;
    if (fineCalculationMethod != null) {
      data['fineCalculationMethod'] = fineCalculationMethod;
    }
    if (fineFixedAmount != null) data['fineFixedAmount'] = fineFixedAmount;
    final res = await _dio.patch<Map<String, dynamic>>('/fine-modals/$id',
        data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw FineModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to update fine modal',
      );
    }
    return FineModal.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteModal(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/fine-modals/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw FineModalsException(
        (d is Map<String, dynamic> && d['detail'] != null)
            ? d['detail'].toString()
            : 'Failed to delete fine modal',
      );
    }
  }
}

class FineModalsException implements Exception {
  final String message;
  FineModalsException(this.message);
  @override
  String toString() => message;
}
