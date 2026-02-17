import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for licenses.
class LicensesRepository {
  LicensesRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;
  final AuthRepository _auth = AuthRepository();

  Future<void> _addAuthToken() async {
    final token = await _auth.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Fetch licenses list from API with optional search and tab filter.
  Future<List<License>> fetchLicenses(
      {String? search, String tab = 'all'}) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (tab != 'all') queryParams['tab'] = tab;
      final res = await _dio.get<Map<String, dynamic>>(
        '/licenses',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw LicensesException('Failed to fetch licenses');
      }
      final list = res.data!['licenses'] as List<dynamic>? ?? [];
      return list
          .map((e) => License.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw LicensesException('Session expired. Please log in again.');
      }
      throw LicensesException(e.message ?? 'Failed to fetch licenses');
    }
  }

  /// Get a single license by ID.
  Future<License> getLicense(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/licenses/$id');
      if (res.statusCode != 200 || res.data == null) {
        throw LicensesException('Failed to fetch license');
      }
      return License.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw LicensesException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw LicensesException('License not found');
      }
      throw LicensesException(e.message ?? 'Failed to fetch license');
    }
  }

  /// Create a new license. If [maxUsers]/[maxBranches] are null, backend uses plan defaults.
  Future<License> createLicense({
    required String subscriptionPlan,
    int? maxUsers,
    int? maxBranches,
    bool isTrial = false,
    String? notes,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{
      'subscription_plan': subscriptionPlan,
      'is_trial': isTrial,
    };
    if (maxUsers != null) body['max_users'] = maxUsers;
    if (maxBranches != null) body['max_branches'] = maxBranches;
    if (notes != null && notes.trim().isNotEmpty) body['notes'] = notes.trim();

    try {
      final res =
          await _dio.post<Map<String, dynamic>>('/licenses', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw LicensesException('Failed to create license');
      }
      return License.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw LicensesException('Session expired. Please log in again.');
      }
      final detail =
          e.response?.data is Map && e.response?.data['detail'] != null
              ? e.response!.data['detail'].toString()
              : (e.message ?? 'Network error');
      throw LicensesException(detail);
    }
  }

  /// Update a license.
  Future<License> updateLicense(
    int id, {
    int? maxUsers,
    int? maxBranches,
    String? status,
    String? notes,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{};
    if (maxUsers != null) body['max_users'] = maxUsers;
    if (maxBranches != null) body['max_branches'] = maxBranches;
    if (status != null) body['status'] = status;
    if (notes != null) body['notes'] = notes;
    if (body.isEmpty) return getLicense(id);
    try {
      final res =
          await _dio.patch<Map<String, dynamic>>('/licenses/$id', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw LicensesException('Failed to update license');
      }
      return License.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw LicensesException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw LicensesException('License not found');
      }
      final detail =
          e.response?.data is Map && e.response?.data['detail'] != null
              ? e.response!.data['detail'].toString()
              : (e.message ?? 'Network error');
      throw LicensesException(detail);
    }
  }

  /// Revoke (delete) a license.
  Future<void> deleteLicense(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/licenses/$id');
      if (res.statusCode != 200) {
        throw LicensesException('Failed to revoke license');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw LicensesException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw LicensesException('License not found');
      }
      throw LicensesException(e.message ?? 'Failed to revoke license');
    }
  }
}

class LicensesException implements Exception {
  final String message;
  LicensesException(this.message);
  @override
  String toString() => message;
}
