import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class AuditLogEntry {
  final int id;
  final int? userId, companyId;
  final String action;
  final String? entityType, entityId, ipAddress, actorName, actorEmail;
  final dynamic details;
  final String? createdAt;

  AuditLogEntry({
    required this.id,
    this.userId,
    this.companyId,
    required this.action,
    this.entityType,
    this.entityId,
    this.ipAddress,
    this.actorName,
    this.actorEmail,
    this.details,
    this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> j) {
    return AuditLogEntry(
      id: (j['id'] as num?)?.toInt() ?? 0,
      userId: (j['userId'] as num?)?.toInt(),
      companyId: (j['companyId'] as num?)?.toInt(),
      action: (j['action'] as String?) ?? '',
      entityType: j['entityType'] as String?,
      entityId: j['entityId'] as String?,
      ipAddress: j['ipAddress'] as String?,
      actorName: j['actorName'] as String?,
      actorEmail: j['actorEmail'] as String?,
      details: j['details'],
      createdAt: j['createdAt'] as String?,
    );
  }
}

class AuditLogsRepository {
  AuditLogsRepository()
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

  Future<List<AuditLogEntry>> fetchAuditLogs({
    int limit = 100,
    int offset = 0,
    String? action,
    String? entityType,
  }) async {
    await _addAuthToken();
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (action != null && action.isNotEmpty) query['action'] = action;
    if (entityType != null && entityType.isNotEmpty) query['entity_type'] = entityType;
    final res = await _dio.get<Map<String, dynamic>>(
      '/audit-logs',
      queryParameters: query,
    );
    if (res.statusCode != 200 || res.data == null) {
      throw AuditLogsException('Failed to fetch audit logs');
    }
    final list = res.data!['auditLogs'] as List<dynamic>? ?? [];
    return list
        .map((e) => AuditLogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

class AuditLogsException implements Exception {
  final String message;
  AuditLogsException(this.message);
  @override
  String toString() => message;
}
