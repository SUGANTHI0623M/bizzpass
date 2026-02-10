import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/mock_data.dart';

class PayrollRepository {
  PayrollRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
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
      return 'Cannot reach the backend at ${ApiConstants.baseUrl}. Ensure it is running.';
    }
    if (e.response?.statusCode == 401) {
      return 'Session expired. Please log in again.';
    }
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    return e.message ?? 'Network error';
  }

  // ============================================================================
  // SALARY COMPONENTS
  // ============================================================================

  Future<List<SalaryComponent>> fetchSalaryComponents({String? type}) async {
    await _addAuthToken();
    try {
      final params = <String, dynamic>{};
      if (type != null && type.isNotEmpty) {
        params['type'] = type;
      }
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/components',
        queryParameters: params.isNotEmpty ? params : null,
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch salary components');
      }
      
      final list = res.data!['components'] as List<dynamic>? ?? [];
      return list
          .map((e) => SalaryComponent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<int> createSalaryComponent({
    required String name,
    required String displayName,
    required String type,
    String? category,
    required String calculationType,
    double? calculationValue,
    String? formula,
    bool isTaxable = true,
    bool isStatutory = false,
    bool affectsGross = true,
    bool affectsNet = true,
    double? minValue,
    double? maxValue,
    List<String>? appliesToCategories,
    int priorityOrder = 0,
    bool isActive = true,
    String? remarks,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'name': name,
        'displayName': displayName,
        'type': type,
        'category': category,
        'calculationType': calculationType,
        'calculationValue': calculationValue,
        'formula': formula,
        'isTaxable': isTaxable,
        'isStatutory': isStatutory,
        'affectsGross': affectsGross,
        'affectsNet': affectsNet,
        'minValue': minValue,
        'maxValue': maxValue,
        'appliesToCategories': appliesToCategories,
        'priorityOrder': priorityOrder,
        'isActive': isActive,
        'remarks': remarks,
      };
      
      final res = await _dio.post<Map<String, dynamic>>(
        '/payroll/components',
        data: data,
      );
      
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw PayrollException('Failed to create salary component');
      }
      
      return (res.data!['id'] as num).toInt();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<void> updateSalaryComponent(
    int componentId, {
    required String name,
    required String displayName,
    String? category,
    required String calculationType,
    double? calculationValue,
    String? formula,
    bool isTaxable = true,
    bool isStatutory = false,
    bool affectsGross = true,
    bool affectsNet = true,
    double? minValue,
    double? maxValue,
    List<String>? appliesToCategories,
    int priorityOrder = 0,
    bool isActive = true,
    String? remarks,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'name': name,
        'displayName': displayName,
        'category': category,
        'calculationType': calculationType,
        'calculationValue': calculationValue,
        'formula': formula,
        'isTaxable': isTaxable,
        'isStatutory': isStatutory,
        'affectsGross': affectsGross,
        'affectsNet': affectsNet,
        'minValue': minValue,
        'maxValue': maxValue,
        'appliesToCategories': appliesToCategories,
        'priorityOrder': priorityOrder,
        'isActive': isActive,
        'remarks': remarks,
      };
      
      final res = await _dio.patch(
        '/payroll/components/$componentId',
        data: data,
      );
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to update salary component');
      }
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<void> deleteSalaryComponent(int componentId) async {
    await _addAuthToken();
    try {
      final res = await _dio.delete('/payroll/components/$componentId');
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to delete salary component');
      }
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // PAYROLL SETTINGS
  // ============================================================================

  Future<Map<String, dynamic>> fetchPayrollSettings() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/payroll/settings');
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch payroll settings');
      }
      
      return res.data!;
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<void> savePayrollSettings(Map<String, dynamic> settings) async {
    await _addAuthToken();
    try {
      final res = await _dio.post(
        '/payroll/settings',
        data: settings,
      );
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to save payroll settings');
      }
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // EMPLOYEE SALARY STRUCTURES
  // ============================================================================

  Future<List<Map<String, dynamic>>> fetchEmployeeSalaryStructures({
    int? employeeId,
    bool? current,
  }) async {
    await _addAuthToken();
    try {
      final params = <String, dynamic>{};
      if (employeeId != null) params['employeeId'] = employeeId;
      if (current != null) params['current'] = current;
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/salary-structures',
        queryParameters: params.isNotEmpty ? params : null,
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch salary structures');
      }
      
      final list = res.data!['salaryStructures'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<int> createEmployeeSalaryStructure({
    required int employeeId,
    required String effectiveFrom,
    String? effectiveTo,
    required double ctc,
    required double grossSalary,
    required double netSalary,
    required List<Map<String, dynamic>> earnings,
    required List<Map<String, dynamic>> deductions,
    String? workingDaysBasis,
    List<String>? paidLeaveTypes,
    bool pfApplicable = true,
    double? pfEmployeeRate,
    bool esiApplicable = true,
    bool ptApplicable = true,
    String? revisionReason,
    String? remarks,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'employeeId': employeeId,
        'effectiveFrom': effectiveFrom,
        'effectiveTo': effectiveTo,
        'ctc': ctc,
        'grossSalary': grossSalary,
        'netSalary': netSalary,
        'earnings': earnings,
        'deductions': deductions,
        'workingDaysBasis': workingDaysBasis,
        'paidLeaveTypes': paidLeaveTypes,
        'pfApplicable': pfApplicable,
        'pfEmployeeRate': pfEmployeeRate,
        'esiApplicable': esiApplicable,
        'ptApplicable': ptApplicable,
        'revisionReason': revisionReason,
        'remarks': remarks,
      };
      
      final res = await _dio.post<Map<String, dynamic>>(
        '/payroll/salary-structures',
        data: data,
      );
      
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw PayrollException('Failed to create salary structure');
      }
      
      return (res.data!['id'] as num).toInt();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // PAYROLL RUNS
  // ============================================================================

  Future<List<PayrollRun>> fetchPayrollRuns({
    int? month,
    int? year,
    String? status,
  }) async {
    await _addAuthToken();
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;
      if (year != null) params['year'] = year;
      if (status != null && status.isNotEmpty) params['status'] = status;
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/runs',
        queryParameters: params.isNotEmpty ? params : null,
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch payroll runs');
      }
      
      final list = res.data!['runs'] as List<dynamic>? ?? [];
      return list
          .map((e) => PayrollRun.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> fetchPayrollRunDetails(int runId) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/payroll/runs/$runId');
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch payroll run details');
      }
      
      return res.data!;
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<int> createPayrollRun({
    required int month,
    required int year,
    required String payPeriodStart,
    required String payPeriodEnd,
    String? departmentFilter,
    int? branchFilter,
    List<int>? employeeIds,
    String? remarks,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'month': month,
        'year': year,
        'payPeriodStart': payPeriodStart,
        'payPeriodEnd': payPeriodEnd,
        'departmentFilter': departmentFilter,
        'branchFilter': branchFilter,
        'employeeIds': employeeIds,
        'remarks': remarks,
      };
      
      final res = await _dio.post<Map<String, dynamic>>(
        '/payroll/runs',
        data: data,
      );
      
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw PayrollException('Failed to create payroll run');
      }
      
      return (res.data!['id'] as num).toInt();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> calculatePayrollRun(int runId) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payroll/runs/$runId/calculate',
      );
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to calculate payroll');
      }
      
      return res.data!;
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<void> approvePayrollRun(int runId) async {
    await _addAuthToken();
    try {
      final res = await _dio.post('/payroll/runs/$runId/approve');
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to approve payroll run');
      }
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // PAYROLL TRANSACTIONS
  // ============================================================================

  Future<PayrollTransaction> fetchPayrollTransaction(int transactionId) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/transactions/$transactionId',
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch payroll transaction');
      }
      
      return PayrollTransaction.fromJson(
        Map<String, dynamic>.from(res.data!['transaction'] as Map),
      );
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<void> updatePayrollTransaction(
    int transactionId, {
    String? status,
    String? holdReason,
    String? paymentMode,
    String? paymentDate,
    String? paymentReference,
    String? remarks,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (holdReason != null) data['holdReason'] = holdReason;
      if (paymentMode != null) data['paymentMode'] = paymentMode;
      if (paymentDate != null) data['paymentDate'] = paymentDate;
      if (paymentReference != null) data['paymentReference'] = paymentReference;
      if (remarks != null) data['remarks'] = remarks;
      
      final res = await _dio.patch(
        '/payroll/transactions/$transactionId',
        data: data,
      );
      
      if (res.statusCode != 200) {
        throw PayrollException('Failed to update payroll transaction');
      }
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // TAX DECLARATIONS
  // ============================================================================

  Future<List<Map<String, dynamic>>> fetchTaxDeclarations({
    int? employeeId,
    String? financialYear,
  }) async {
    await _addAuthToken();
    try {
      final params = <String, dynamic>{};
      if (employeeId != null) params['employeeId'] = employeeId;
      if (financialYear != null) params['financialYear'] = financialYear;
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/tax-declarations',
        queryParameters: params.isNotEmpty ? params : null,
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch tax declarations');
      }
      
      final list = res.data!['declarations'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  Future<int> saveTaxDeclaration(Map<String, dynamic> declaration) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/payroll/tax-declarations',
        data: declaration,
      );
      
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw PayrollException('Failed to save tax declaration');
      }
      
      return (res.data!['id'] as num).toInt();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }

  // ============================================================================
  // REPORTS
  // ============================================================================

  Future<List<Map<String, dynamic>>> fetchPayrollSummaryReport({
    required int year,
    int? month,
  }) async {
    await _addAuthToken();
    try {
      final params = <String, dynamic>{'year': year};
      if (month != null) params['month'] = month;
      
      final res = await _dio.get<Map<String, dynamic>>(
        '/payroll/reports/summary',
        queryParameters: params,
      );
      
      if (res.statusCode != 200 || res.data == null) {
        throw PayrollException('Failed to fetch payroll summary report');
      }
      
      final list = res.data!['summary'] as List<dynamic>? ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw PayrollException(_handleDioError(e));
    }
  }
}

class PayrollException implements Exception {
  final String message;
  PayrollException(this.message);
  @override
  String toString() => message;
}
