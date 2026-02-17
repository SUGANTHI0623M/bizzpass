import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Branch {
  final int id;
  final String branchName, branchCode;
  final bool isHeadOffice;
  final String? addressAptBuilding, addressStreet, addressCity, addressState, addressZip, addressCountry;
  final String? contactNumber, status;
  final String? createdAt;
  final double? latitude;
  final double? longitude;
  final double? attendanceRadiusM;

  Branch({
    required this.id,
    required this.branchName,
    required this.branchCode,
    required this.isHeadOffice,
    this.addressAptBuilding,
    this.addressStreet,
    this.addressCity,
    this.addressState,
    this.addressZip,
    this.addressCountry,
    this.contactNumber,
    this.status,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.attendanceRadiusM,
  });

  factory Branch.fromJson(Map<String, dynamic> j) {
    return Branch(
      id: (j['id'] as num?)?.toInt() ?? 0,
      branchName: (j['branchName'] as String?) ?? '',
      branchCode: (j['branchCode'] as String?) ?? '',
      isHeadOffice: (j['isHeadOffice'] as bool?) ?? false,
      addressAptBuilding: j['addressAptBuilding'] as String?,
      addressStreet: j['addressStreet'] as String?,
      addressCity: j['addressCity'] as String?,
      addressState: j['addressState'] as String?,
      addressZip: j['addressZip'] as String?,
      addressCountry: j['addressCountry'] as String?,
      contactNumber: j['contactNumber'] as String?,
      status: j['status'] as String?,
      createdAt: j['createdAt'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      attendanceRadiusM: (j['attendanceRadiusM'] as num?)?.toDouble(),
    );
  }

  bool get isActive => status == null || status!.toLowerCase().trim() == 'active';

  /// Full address (apt/building, street, city, state, zip, country) for display.
  String get fullAddress {
    final parts = <String>[];
    if (addressAptBuilding != null && addressAptBuilding!.trim().isNotEmpty) parts.add(addressAptBuilding!.trim());
    if (addressStreet != null && addressStreet!.trim().isNotEmpty) parts.add(addressStreet!.trim());
    if (addressCity != null && addressCity!.trim().isNotEmpty) parts.add(addressCity!.trim());
    if (addressState != null && addressState!.trim().isNotEmpty) parts.add(addressState!.trim());
    if (addressZip != null && addressZip!.trim().isNotEmpty) parts.add(addressZip!.trim());
    if (addressCountry != null && addressCountry!.trim().isNotEmpty) parts.add(addressCountry!.trim());
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

class BranchesRepository {
  BranchesRepository()
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

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        (e.type == DioExceptionType.unknown && e.response == null)) {
      return 'Cannot reach the backend at ${ApiConstants.baseUrl}. ${ApiConstants.backendUnreachableHint}';
    }
    if (e.response?.statusCode == 401) return 'Session expired. Please log in again.';
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  Future<List<Branch>> fetchBranches() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/branches');
      if (res.statusCode != 200 || res.data == null) {
        throw BranchesException('Failed to fetch branches');
      }
      final list = res.data!['branches'] as List<dynamic>? ?? [];
      return list.map((e) => Branch.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw BranchesException(_handleDioError(e));
    }
  }

  Future<Branch> createBranch({
    required String branchName,
    String? branchCode,
    bool isHeadOffice = false,
    String? addressAptBuilding,
    String? addressStreet,
    String? addressCity,
    String? addressState,
    String? addressZip,
    String? addressCountry,
    String? contactNumber,
    double? latitude,
    double? longitude,
    double? attendanceRadiusM,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{
      'branchName': branchName,
      'branchCode': branchCode,
      'isHeadOffice': isHeadOffice,
      'addressAptBuilding': addressAptBuilding,
      'addressStreet': addressStreet,
      'addressCity': addressCity,
      'addressState': addressState,
      'addressZip': addressZip,
      'addressCountry': addressCountry,
      'contactNumber': contactNumber,
    };
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (attendanceRadiusM != null) data['attendanceRadiusM'] = attendanceRadiusM;
    try {
      final res = await _dio.post<Map<String, dynamic>>('/branches', data: data);
      if (res.statusCode != 200 && res.statusCode != 201) {
        final d = res.data;
        throw BranchesException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to create branch',
        );
      }
      return Branch.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw BranchesException(_handleDioError(e));
    }
  }

  Future<Branch> updateBranch(
    int branchId, {
    String? branchName,
    String? branchCode,
    bool? isHeadOffice,
    String? addressAptBuilding,
    String? addressStreet,
    String? addressCity,
    String? addressState,
    String? addressZip,
    String? addressCountry,
    String? contactNumber,
    String? status,
    double? latitude,
    double? longitude,
    double? attendanceRadiusM,
  }) async {
    await _addAuthToken();
    final data = <String, dynamic>{};
    if (branchName != null) data['branchName'] = branchName;
    if (branchCode != null) data['branchCode'] = branchCode;
    if (isHeadOffice != null) data['isHeadOffice'] = isHeadOffice;
    if (addressAptBuilding != null) data['addressAptBuilding'] = addressAptBuilding;
    if (addressStreet != null) data['addressStreet'] = addressStreet;
    if (addressCity != null) data['addressCity'] = addressCity;
    if (addressState != null) data['addressState'] = addressState;
    if (addressZip != null) data['addressZip'] = addressZip;
    if (addressCountry != null) data['addressCountry'] = addressCountry;
    if (contactNumber != null) data['contactNumber'] = contactNumber;
    if (status != null) data['status'] = status;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (attendanceRadiusM != null) data['attendanceRadiusM'] = attendanceRadiusM;
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/branches/$branchId', data: data);
      if (res.statusCode != 200) {
        final d = res.data;
        throw BranchesException(
          (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to update branch',
        );
      }
      return Branch.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw BranchesException(_handleDioError(e));
    }
  }

  /// Deactivate or activate a branch (no delete; use status only).
  Future<Branch> setBranchStatus(int branchId, String status) async {
    return updateBranch(branchId, status: status);
  }
}

class BranchesException implements Exception {
  final String message;
  BranchesException(this.message);
  @override
  String toString() => message;
}
