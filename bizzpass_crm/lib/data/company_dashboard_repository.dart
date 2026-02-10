import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'auth_repository.dart';

// Models
class EmployeeAnalytics {
  final int active;
  final int hired;
  final int exits;
  final int total;

  EmployeeAnalytics({
    required this.active,
    required this.hired,
    required this.exits,
    required this.total,
  });

  factory EmployeeAnalytics.fromJson(Map<String, dynamic> json) {
    return EmployeeAnalytics(
      active: (json['active'] as num?)?.toInt() ?? 0,
      hired: (json['hired'] as num?)?.toInt() ?? 0,
      exits: (json['exits'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class TodayAttendance {
  final int present;
  final int absent;
  final int onLeave;

  TodayAttendance({
    required this.present,
    required this.absent,
    required this.onLeave,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      onLeave: (json['onLeave'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardOverview {
  final EmployeeAnalytics employeeAnalytics;
  final TodayAttendance todayAttendance;
  final int pendingRequests;

  DashboardOverview({
    required this.employeeAnalytics,
    required this.todayAttendance,
    required this.pendingRequests,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      employeeAnalytics: EmployeeAnalytics.fromJson(
        json['employeeAnalytics'] as Map<String, dynamic>? ?? {},
      ),
      todayAttendance: TodayAttendance.fromJson(
        json['todayAttendance'] as Map<String, dynamic>? ?? {},
      ),
      pendingRequests: (json['pendingRequests'] as num?)?.toInt() ?? 0,
    );
  }
}

class Birthday {
  final int id;
  final String name;
  final String designation;
  final String date;
  final int daysUntil;
  final String? avatar;

  Birthday({
    required this.id,
    required this.name,
    required this.designation,
    required this.date,
    required this.daysUntil,
    this.avatar,
  });

  factory Birthday.fromJson(Map<String, dynamic> json) {
    return Birthday(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      date: json['date'] as String? ?? '',
      daysUntil: (json['daysUntil'] as num?)?.toInt() ?? 0,
      avatar: json['avatar'] as String?,
    );
  }
}

class Holiday {
  final int id;
  final String name;
  final String date;
  final String type;
  final int daysUntil;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.daysUntil,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? '',
      daysUntil: (json['daysUntil'] as num?)?.toInt() ?? 0,
    );
  }
}

class Shift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String type;
  final int staffCount;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.staffCount,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      type: json['type'] as String? ?? '',
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class LeaveBalance {
  final int id;
  final String type;
  final int available;
  final int used;
  final int total;

  LeaveBalance({
    required this.id,
    required this.type,
    required this.available,
    required this.used,
    required this.total,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      available: (json['available'] as num?)?.toInt() ?? 0,
      used: (json['used'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApprovalRequest {
  final int id;
  final String staffName;
  final String type;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;

  ApprovalRequest({
    required this.id,
    required this.staffName,
    required this.type,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      staffName: json['staffName'] as String? ?? '',
      type: json['type'] as String? ?? '',
      date: json['date'] as String? ?? '',
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      status: json['status'] as String? ?? '',
    );
  }
}

class Announcement {
  final int id;
  final String title;
  final String message;
  final String date;
  final String priority;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.priority,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      date: json['date'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
    );
  }
}

// Repository
class CompanyDashboardRepository {
  late final Dio _dio;

  CompanyDashboardRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  String _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please check your connection.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach the backend server. Please ensure it is running.';
    }
    if (e.response?.statusCode == 401) {
      return 'Unauthorized. Please login again.';
    }
    if (e.response?.data != null && e.response?.data is Map) {
      final detail = e.response?.data['detail'];
      if (detail != null) return detail.toString();
    }
    return 'An error occurred: ${e.message}';
  }

  Future<DashboardOverview> fetchOverview() async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/overview',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return DashboardOverview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<Birthday>> fetchBirthdays({int daysAhead = 7}) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/birthdays',
        queryParameters: {'days_ahead': daysAhead},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final birthdays = data['birthdays'] as List? ?? [];
      return birthdays.map((b) => Birthday.fromJson(b as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<Holiday>> fetchUpcomingHolidays({int limit = 5}) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/upcoming-holidays',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final holidays = data['holidays'] as List? ?? [];
      return holidays.map((h) => Holiday.fromJson(h as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<Shift>> fetchShiftSchedule() async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/shift-schedule',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final shifts = data['shifts'] as List? ?? [];
      return shifts.map((s) => Shift.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<LeaveBalance>> fetchMyLeaves() async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/my-leaves',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final leaves = data['leaves'] as List? ?? [];
      return leaves.map((l) => LeaveBalance.fromJson(l as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<ApprovalRequest>> fetchApprovalRequests({String type = 'attendance'}) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/approval-requests',
        queryParameters: {'request_type': type},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final requests = data['requests'] as List? ?? [];
      return requests.map((r) => ApprovalRequest.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<List<Announcement>> fetchAnnouncements({int limit = 10}) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/announcements',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data as Map<String, dynamic>;
      final announcements = data['announcements'] as List? ?? [];
      return announcements.map((a) => Announcement.fromJson(a as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> fetchTotalExpenses({String period = 'month'}) async {
    try {
      final token = await AuthRepository().getToken();
      final response = await _dio.get(
        '/company-dashboard/total-expenses',
        queryParameters: {'period': period},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }
}

class CompanyDashboardException implements Exception {
  final String message;
  CompanyDashboardException(this.message);
  @override
  String toString() => 'CompanyDashboardException: $message';
}
