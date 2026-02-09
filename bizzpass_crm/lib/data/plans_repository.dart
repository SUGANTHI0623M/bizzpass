import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for subscription plans.
class PlansRepository {
  PlansRepository()
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

  /// Fetch plans from API with optional search and active filter.
  Future<List<Plan>> fetchPlans(
      {String? search, bool activeOnly = true}) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      queryParams['active_only'] = activeOnly;
      final res = await _dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: queryParams,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw PlansException('Failed to fetch plans');
      }
      final list = res.data!['plans'] as List<dynamic>? ?? [];
      return list
          .map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PlansException('Session expired. Please log in again.');
      }
      throw PlansException(e.message ?? 'Failed to fetch plans');
    }
  }

  /// Get a single plan by ID.
  Future<Plan> getPlan(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/plans/$id');
      if (res.statusCode != 200 || res.data == null) {
        throw PlansException('Failed to fetch plan');
      }
      return Plan.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PlansException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw PlansException('Plan not found');
      }
      throw PlansException(e.message ?? 'Failed to fetch plan');
    }
  }

  /// Create a new plan.
  Future<Plan> createPlan({
    required String planCode,
    required String planName,
    String? description,
    required double price,
    String currency = 'INR',
    int durationMonths = 12,
    int maxUsers = 30,
    int? maxBranches,
    List<String>? features,
    int trialDays = 0,
    bool isActive = true,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{
      'plan_code': planCode.trim(),
      'plan_name': planName.trim(),
      'price': price,
      'currency': currency,
      'duration_months': durationMonths,
      'max_users': maxUsers,
      'trial_days': trialDays,
      'is_active': isActive,
    };
    if (description != null && description.isNotEmpty)
      body['description'] = description;
    if (maxBranches != null) body['max_branches'] = maxBranches;
    if (features != null && features.isNotEmpty) body['features'] = features;

    try {
      // Use /plans/create so the path can't be mistaken for GET /plans/{id}
      final res =
          await _dio.post<Map<String, dynamic>>('/plans/create', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw PlansException(
          res.data is Map && res.data!['detail'] != null
              ? res.data!['detail'].toString()
              : 'Failed to create plan (${res.statusCode})',
        );
      }
      return Plan.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PlansException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw PlansException(
          'Not found. Ensure the backend is running at ${ApiConstants.baseUrl}. '
          'Check ${ApiConstants.baseUrl}/debug/routes to see if POST /plans/create is listed.',
        );
      }
      final detail =
          e.response?.data is Map && e.response?.data['detail'] != null
              ? e.response!.data['detail'].toString()
              : (e.message ?? 'Network error');
      throw PlansException(detail);
    }
  }

  /// Update a plan.
  Future<Plan> updatePlan(
    int id, {
    String? planName,
    String? description,
    double? price,
    String? currency,
    int? durationMonths,
    int? maxUsers,
    int? maxBranches,
    List<String>? features,
    int? trialDays,
    bool? isActive,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{};
    if (planName != null) body['plan_name'] = planName.trim();
    if (description != null) body['description'] = description.trim();
    if (price != null) body['price'] = price;
    if (currency != null) body['currency'] = currency;
    if (durationMonths != null) body['duration_months'] = durationMonths;
    if (maxUsers != null) body['max_users'] = maxUsers;
    if (maxBranches != null) body['max_branches'] = maxBranches;
    if (features != null) body['features'] = features;
    if (trialDays != null) body['trial_days'] = trialDays;
    if (isActive != null) body['is_active'] = isActive;
    if (body.isEmpty) return getPlan(id);

    try {
      final res =
          await _dio.patch<Map<String, dynamic>>('/plans/$id', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw PlansException('Failed to update plan');
      }
      return Plan.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PlansException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw PlansException('Plan not found');
      }
      final detail =
          e.response?.data is Map && e.response?.data['detail'] != null
              ? e.response!.data['detail'].toString()
              : (e.message ?? 'Network error');
      throw PlansException(detail);
    }
  }

  /// Delete (deactivate) a plan.
  Future<void> deletePlan(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/plans/$id');
      if (res.statusCode != 200) {
        throw PlansException('Failed to delete plan');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw PlansException('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw PlansException('Plan not found');
      }
      throw PlansException(e.message ?? 'Failed to delete plan');
    }
  }
}

class PlansException implements Exception {
  final String message;
  PlansException(this.message);
  @override
  String toString() => message;
}
