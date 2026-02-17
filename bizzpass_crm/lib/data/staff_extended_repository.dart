import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'auth_repository.dart';

class StaffExperience {
  final int id;
  final int staffId;
  final String companyName;
  final String jobTitle;
  final String fromDate;
  final String toDate;
  final bool isCurrent;
  final String description;

  const StaffExperience({
    required this.id,
    required this.staffId,
    required this.companyName,
    required this.jobTitle,
    required this.fromDate,
    required this.toDate,
    required this.isCurrent,
    required this.description,
  });

  factory StaffExperience.fromJson(Map<String, dynamic> j) {
    return StaffExperience(
      id: (j['id'] as num?)?.toInt() ?? 0,
      staffId: (j['staffId'] as num?)?.toInt() ?? 0,
      companyName: (j['companyName'] as String?) ?? '',
      jobTitle: (j['jobTitle'] as String?) ?? '',
      fromDate: (j['fromDate'] as String?) ?? '',
      toDate: (j['toDate'] as String?) ?? '',
      isCurrent: (j['isCurrent'] as bool?) ?? false,
      description: (j['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'jobTitle': jobTitle,
        'fromDate': fromDate.isEmpty ? null : fromDate,
        'toDate': toDate.isEmpty ? null : toDate,
        'isCurrent': isCurrent,
        'description': description.isEmpty ? null : description,
      };
}

class StaffEducation {
  final int id;
  final int staffId;
  final String institution;
  final String degreeOrCourse;
  final String fromDate;
  final String toDate;

  const StaffEducation({
    required this.id,
    required this.staffId,
    required this.institution,
    required this.degreeOrCourse,
    required this.fromDate,
    required this.toDate,
  });

  factory StaffEducation.fromJson(Map<String, dynamic> j) {
    return StaffEducation(
      id: (j['id'] as num?)?.toInt() ?? 0,
      staffId: (j['staffId'] as num?)?.toInt() ?? 0,
      institution: (j['institution'] as String?) ?? '',
      degreeOrCourse: (j['degreeOrCourse'] as String?) ?? '',
      fromDate: (j['fromDate'] as String?) ?? '',
      toDate: (j['toDate'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degreeOrCourse': degreeOrCourse,
        'fromDate': fromDate.isEmpty ? null : fromDate,
        'toDate': toDate.isEmpty ? null : toDate,
      };
}

class StaffOnboardingDocument {
  final int id;
  final int staffId;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final String uploadedAt;

  const StaffOnboardingDocument({
    required this.id,
    required this.staffId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory StaffOnboardingDocument.fromJson(Map<String, dynamic> j) {
    return StaffOnboardingDocument(
      id: (j['id'] as num?)?.toInt() ?? 0,
      staffId: (j['staffId'] as num?)?.toInt() ?? 0,
      documentType: (j['documentType'] as String?) ?? '',
      fileName: (j['fileName'] as String?) ?? '',
      fileUrl: (j['fileUrl'] as String?) ?? '',
      uploadedAt: (j['uploadedAt'] as String?) ?? '',
    );
  }

  bool get isOfferLetter => documentType == 'offer_letter';
}

class StaffExtendedRepository {
  StaffExtendedRepository()
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

  // --- Experience ---
  Future<List<StaffExperience>> getExperience(int staffId) async {
    await _addAuthToken();
    final res = await _dio.get<List<dynamic>>('/staff/$staffId/experience');
    final list = res.data ?? [];
    return list.map((e) => StaffExperience.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<int> createExperience(int staffId, Map<String, dynamic> body) async {
    await _addAuthToken();
    final res = await _dio.post<Map<String, dynamic>>('/staff/$staffId/experience', data: body);
    return (res.data?['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateExperience(int staffId, int expId, Map<String, dynamic> body) async {
    await _addAuthToken();
    await _dio.patch<Map<String, dynamic>>('/staff/$staffId/experience/$expId', data: body);
  }

  Future<void> deleteExperience(int staffId, int expId) async {
    await _addAuthToken();
    await _dio.delete('/staff/$staffId/experience/$expId');
  }

  // --- Education ---
  Future<List<StaffEducation>> getEducation(int staffId) async {
    await _addAuthToken();
    final res = await _dio.get<List<dynamic>>('/staff/$staffId/education');
    final list = res.data ?? [];
    return list.map((e) => StaffEducation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<int> createEducation(int staffId, Map<String, dynamic> body) async {
    await _addAuthToken();
    final res = await _dio.post<Map<String, dynamic>>('/staff/$staffId/education', data: body);
    return (res.data?['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateEducation(int staffId, int eduId, Map<String, dynamic> body) async {
    await _addAuthToken();
    await _dio.patch<Map<String, dynamic>>('/staff/$staffId/education/$eduId', data: body);
  }

  Future<void> deleteEducation(int staffId, int eduId) async {
    await _addAuthToken();
    await _dio.delete('/staff/$staffId/education/$eduId');
  }

  // --- Onboarding documents ---
  Future<List<StaffOnboardingDocument>> getOnboardingDocuments(int staffId) async {
    await _addAuthToken();
    final res = await _dio.get<List<dynamic>>('/staff/$staffId/onboarding-documents');
    final list = res.data ?? [];
    return list.map((e) => StaffOnboardingDocument.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<StaffOnboardingDocument> uploadOnboardingDocument(
    int staffId, {
    required List<int> fileBytes,
    required String fileName,
    String documentType = 'joining_document',
  }) async {
    await _addAuthToken();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/staff/$staffId/onboarding-documents?document_type=$documentType',
      data: formData,
      options: Options(contentType: 'multipart/form-data', receiveTimeout: const Duration(seconds: 30)),
    );
    final d = res.data!;
    return StaffOnboardingDocument(
      id: (d['id'] as num?)?.toInt() ?? 0,
      staffId: staffId,
      documentType: (d['documentType'] as String?) ?? documentType,
      fileName: (d['fileName'] as String?) ?? fileName,
      fileUrl: (d['fileUrl'] as String?) ?? '',
      uploadedAt: '',
    );
  }

  Future<void> deleteOnboardingDocument(int staffId, int docId) async {
    await _addAuthToken();
    await _dio.delete('/staff/$staffId/onboarding-documents/$docId');
  }
}
