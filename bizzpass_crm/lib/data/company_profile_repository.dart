import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';
import 'branches_repository.dart';

/// Company profile as returned by GET /company-profile (company admin's own company).
class CompanyProfile {
  final int id;
  final String name, email, phone, city, state;
  final String subscriptionPlan, subscriptionStatus, subscriptionEndDate;
  final String licenseKey;
  final bool isActive;
  final String? logo;
  final int staffCount, branchesCount;
  final int? maxStaff, maxBranches;
  final List<Branch> branches;

  CompanyProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.city = '',
    this.state = '',
    required this.subscriptionPlan,
    this.subscriptionStatus = 'active',
    this.subscriptionEndDate = '',
    this.licenseKey = '',
    this.isActive = true,
    this.logo,
    this.staffCount = 0,
    this.branchesCount = 0,
    this.maxStaff,
    this.maxBranches,
    this.branches = const [],
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> j) {
    final branchesList = j['branches'] as List<dynamic>? ?? [];
    return CompanyProfile(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      city: (j['city'] as String?) ?? '',
      state: (j['state'] as String?) ?? '',
      subscriptionPlan: (j['subscriptionPlan'] as String?) ?? '',
      subscriptionStatus: (j['subscriptionStatus'] as String?) ?? 'active',
      subscriptionEndDate: (j['subscriptionEndDate'] as String?) ?? '',
      licenseKey: (j['licenseKey'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
      logo: j['logo'] as String?,
      staffCount: (j['staffCount'] as num?)?.toInt() ?? 0,
      branchesCount: (j['branchesCount'] as num?)?.toInt() ?? 0,
      maxStaff: (j['maxStaff'] as num?)?.toInt(),
      maxBranches: (j['maxBranches'] as num?)?.toInt(),
      branches: branchesList
          .map((e) => Branch.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class CompanyProfileRepository {
  CompanyProfileRepository()
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

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) return 'Session expired. Please log in again.';
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<CompanyProfile> fetchProfile() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/company-profile');
      if (res.statusCode != 200 || res.data == null) {
        throw CompanyProfileException('Failed to load company profile');
      }
      return CompanyProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw CompanyProfileException(_handleError(e));
    }
  }

  Future<CompanyProfile> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? state,
  }) async {
    await _addAuthToken();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (email != null) body['email'] = email.trim();
    if (phone != null) body['phone'] = phone.trim().isEmpty ? null : phone.trim();
    if (city != null) body['city'] = city.trim().isEmpty ? null : city.trim();
    if (state != null) body['state'] = state.trim().isEmpty ? null : state.trim();
    if (body.isEmpty) return fetchProfile();
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/company-profile', data: body);
      if (res.statusCode != 200 || res.data == null) {
        throw CompanyProfileException('Failed to update profile');
      }
      return CompanyProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw CompanyProfileException(_handleError(e));
    }
  }

  Future<String> uploadLogo(List<int> imageBytes) async {
    await _addAuthToken();
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'logo.png',
        ),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/company-profile/logo',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.statusCode != 200 || res.data == null) {
        throw CompanyProfileException('Failed to upload logo');
      }
      final url = res.data!['logo'] as String?;
      if (url == null || url.isEmpty) throw CompanyProfileException('No logo URL returned');
      return url;
    } on DioException catch (e) {
      throw CompanyProfileException(_handleError(e));
    }
  }

  Future<void> deleteLogo() async {
    await _addAuthToken();
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/company-profile/logo');
      if (res.statusCode != 200) {
        throw CompanyProfileException('Failed to delete logo');
      }
    } on DioException catch (e) {
      throw CompanyProfileException(_handleError(e));
    }
  }
}

class CompanyProfileException implements Exception {
  final String message;
  CompanyProfileException(this.message);
  @override
  String toString() => message;
}
