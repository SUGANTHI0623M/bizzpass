import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

/// API repository for companies. Uses auth token for requests.
class CompaniesRepository {
  CompaniesRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  final AuthRepository _auth = AuthRepository();

  /// User-friendly message when backend is unreachable (network/connection error).
  static String _connectionErrorMsg() =>
      'Cannot reach the backend at ${ApiConstants.baseUrl}. '
      'Ensure the backend is running (e.g. docker compose up -d crm_backend, '
      'or: .\\.venv\\Scripts\\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000).';

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown && e.response == null) {
      return _connectionErrorMsg();
    }
    if (e.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<void> _addAuthToken() async {
    final token = await _auth.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Fetch companies list from API with optional search and tab filter.
  Future<List<Company>> fetchCompanies(
      {String? search, String tab = 'all'}) async {
    await _addAuthToken();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (tab != 'all') queryParams['tab'] = tab;
      final res = await _dio.get<Map<String, dynamic>>(
        '/companies',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw CompaniesException('Failed to fetch companies');
      }
      final list = res.data!['companies'] as List<dynamic>? ?? [];
      return list
          .map((e) => Company.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw CompaniesException(_handleDioError(e));
    }
  }

  /// Update a company.
  Future<Company> updateCompany(
    int id, {
    String? name,
    String? email,
    String? phone,
    String? city,
    String? state,
    String? subscriptionPlan,
    bool? isActive,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (email != null) body['email'] = email.trim();
    if (phone != null) body['phone'] = phone.trim();
    if (city != null) body['city'] = city.trim();
    if (state != null) body['state'] = state.trim();
    if (subscriptionPlan != null) body['subscription_plan'] = subscriptionPlan;
    if (isActive != null) body['is_active'] = isActive;
    if (body.isEmpty) {
      final res = await _dio.get<Map<String, dynamic>>('/companies/$id');
      if (res.statusCode != 200 || res.data == null) {
        throw CompaniesException('Failed to fetch company');
      }
      return Company.fromJson(Map<String, dynamic>.from(res.data!));
    }
    try {
      final res =
          await _dio.patch<Map<String, dynamic>>('/companies/$id', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw CompaniesException('Failed to update company');
      }
      return Company.fromJson(Map<String, dynamic>.from(res.data!));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw CompaniesException('Company not found');
      }
      throw CompaniesException(_handleDioError(e));
    }
  }

  /// Delete (deactivate) a company.
  Future<void> deleteCompany(int id) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/companies/$id');
      if (res.statusCode != 200) {
        throw CompaniesException('Failed to delete company');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw CompaniesException('Company not found');
      }
      throw CompaniesException(_handleDioError(e));
    }
  }

  /// Create a new company. Returns company and optional admin login (when backend uses default password).
  /// [licenseKey] is required; must be an unassigned license key.
  Future<CreateCompanyResult> createCompany({
    required String name,
    required String email,
    String? phone,
    String? city,
    String? state,
    String subscriptionPlan = 'Starter',
    required String licenseKey,
    bool isActive = true,
    String? adminPassword,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'subscription_plan': subscriptionPlan,
      'is_active': isActive,
      'license_key': licenseKey.trim(),
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone.trim();
    if (city != null && city.isNotEmpty) body['city'] = city.trim();
    if (state != null && state.isNotEmpty) body['state'] = state.trim();
    if (adminPassword != null && adminPassword.isNotEmpty) {
      body['admin_password'] = adminPassword.trim();
    }

    try {
      final res =
          await _dio.post<Map<String, dynamic>>('/companies', data: body);
      if (res.statusCode != 200 || res.data == null) {
        final detail = res.data is Map && res.data!['detail'] != null
            ? res.data!['detail'].toString()
            : 'Failed to create company';
        throw CompaniesException(detail);
      }
      final data = Map<String, dynamic>.from(res.data!);
      final company = Company.fromJson(data);
      final adminLogin = data['adminLogin'] is Map
          ? Map<String, dynamic>.from(data['adminLogin'] as Map)
          : null;
      return CreateCompanyResult(company: company, adminLogin: adminLogin);
    } on DioException catch (e) {
      throw CompaniesException(_handleDioError(e));
    }
  }
}

class CreateCompanyResult {
  final Company company;
  final Map<String, dynamic>? adminLogin;

  CreateCompanyResult({required this.company, this.adminLogin});
}

class CompaniesException implements Exception {
  final String message;
  CompaniesException(this.message);
  @override
  String toString() => message;
}
