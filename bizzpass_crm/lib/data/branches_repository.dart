import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class Branch {
  final int id;
  final String branchName, branchCode;
  final bool isHeadOffice;
  final String? addressCity, addressState, contactNumber, status;
  final double? latitude;
  final double? longitude;
  final double? attendanceRadiusM;

  Branch({
    required this.id,
    required this.branchName,
    required this.branchCode,
    required this.isHeadOffice,
    this.addressCity,
    this.addressState,
    this.contactNumber,
    this.status,
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
      addressCity: j['addressCity'] as String?,
      addressState: j['addressState'] as String?,
      contactNumber: j['contactNumber'] as String?,
      status: j['status'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      attendanceRadiusM: (j['attendanceRadiusM'] as num?)?.toDouble(),
    );
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

  Future<List<Branch>> fetchBranches() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/branches');
    if (res.statusCode != 200 || res.data == null) {
      throw BranchesException('Failed to fetch branches');
    }
    final list = res.data!['branches'] as List<dynamic>? ?? [];
    return list.map((e) => Branch.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Branch> createBranch({
    required String branchName,
    String? branchCode,
    bool isHeadOffice = false,
    String? addressCity,
    String? addressState,
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
      'addressCity': addressCity,
      'addressState': addressState,
      'contactNumber': contactNumber,
    };
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (attendanceRadiusM != null) data['attendanceRadiusM'] = attendanceRadiusM;
    final res = await _dio.post<Map<String, dynamic>>('/branches', data: data);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      throw BranchesException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to create branch',
      );
    }
    return Branch.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Branch> updateBranch(
    int branchId, {
    String? branchName,
    String? branchCode,
    bool? isHeadOffice,
    String? addressCity,
    String? addressState,
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
    if (addressCity != null) data['addressCity'] = addressCity;
    if (addressState != null) data['addressState'] = addressState;
    if (contactNumber != null) data['contactNumber'] = contactNumber;
    if (status != null) data['status'] = status;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (attendanceRadiusM != null) data['attendanceRadiusM'] = attendanceRadiusM;
    final res = await _dio.patch<Map<String, dynamic>>('/branches/$branchId', data: data);
    if (res.statusCode != 200) {
      final d = res.data;
      throw BranchesException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to update branch',
      );
    }
    return Branch.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deleteBranch(int branchId) async {
    await _addAuthToken();
    final res = await _dio.delete('/branches/$branchId');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      throw BranchesException(
        (d is Map<String, dynamic> && d['detail'] != null) ? d['detail'].toString() : 'Failed to delete branch',
      );
    }
  }
}

class BranchesException implements Exception {
  final String message;
  BranchesException(this.message);
  @override
  String toString() => message;
}
