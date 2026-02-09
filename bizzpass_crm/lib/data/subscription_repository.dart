import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';
import 'mock_data.dart';

/// Current subscription for company (license + plan + usage).
class CurrentSubscription {
  final bool hasSubscription;
  final int? licenseId;
  final String? licenseKey;
  final String? licenseStatus;
  final Plan? plan;
  final String? validFrom;
  final String? validUntil;
  final int currentStaff;
  final int currentBranches;
  final int? maxStaff;
  final int? maxBranches;
  final int? daysRemaining;

  const CurrentSubscription({
    required this.hasSubscription,
    this.licenseId,
    this.licenseKey,
    this.licenseStatus,
    this.plan,
    this.validFrom,
    this.validUntil,
    this.currentStaff = 0,
    this.currentBranches = 0,
    this.maxStaff,
    this.maxBranches,
    this.daysRemaining,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> j) {
    final planData = j['plan'];
    return CurrentSubscription(
      hasSubscription: (j['hasSubscription'] as bool?) ?? false,
      licenseId: (j['licenseId'] as num?)?.toInt(),
      licenseKey: j['licenseKey'] as String?,
      licenseStatus: j['licenseStatus'] as String?,
      plan: planData is Map ? Plan.fromJson(Map<String, dynamic>.from(planData)) : null,
      validFrom: j['validFrom'] as String?,
      validUntil: j['validUntil'] as String?,
      currentStaff: (j['currentStaff'] as num?)?.toInt() ?? 0,
      currentBranches: (j['currentBranches'] as num?)?.toInt() ?? 0,
      maxStaff: (j['maxStaff'] as num?)?.toInt(),
      maxBranches: (j['maxBranches'] as num?)?.toInt(),
      daysRemaining: (j['daysRemaining'] as num?)?.toInt(),
    );
  }
}

/// Result of initiating a subscription (payment intent / PaySharp).
class InitiateSubscriptionResult {
  final int paymentId;
  final String gateway;
  final int planId;
  final String? planName;
  final int durationMonths;
  final int amount;
  final String currency;
  final String? checkoutUrl;
  final String? paymentIntentId;
  final String status;
  final String? message;

  const InitiateSubscriptionResult({
    required this.paymentId,
    required this.gateway,
    required this.planId,
    this.planName,
    required this.durationMonths,
    required this.amount,
    required this.currency,
    this.checkoutUrl,
    this.paymentIntentId,
    required this.status,
    this.message,
  });

  factory InitiateSubscriptionResult.fromJson(Map<String, dynamic> j) {
    return InitiateSubscriptionResult(
      paymentId: (j['paymentId'] as num?)?.toInt() ?? 0,
      gateway: (j['gateway'] as String?) ?? 'paysharp',
      planId: (j['planId'] as num?)?.toInt() ?? 0,
      planName: j['planName'] as String?,
      durationMonths: (j['durationMonths'] as num?)?.toInt() ?? 12,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      checkoutUrl: j['checkoutUrl'] as String?,
      paymentIntentId: j['paymentIntentId'] as String?,
      status: (j['status'] as String?) ?? 'pending',
      message: j['message'] as String?,
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final int amount;
  final String currency;
  final String status;
  final String gateway;
  final String planName;
  final String paidAt;
  final String createdAt;

  const PaymentHistoryItem({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gateway,
    required this.planName,
    required this.paidAt,
    required this.createdAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> j) {
    return PaymentHistoryItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      status: (j['status'] as String?) ?? '',
      gateway: (j['gateway'] as String?) ?? '',
      planName: (j['planName'] as String?) ?? '',
      paidAt: (j['paidAt'] as String?) ?? '',
      createdAt: (j['createdAt'] as String?) ?? '',
    );
  }
}

class SubscriptionRepository {
  SubscriptionRepository()
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

  /// Current company subscription (license, plan, usage).
  Future<CurrentSubscription> getCurrentSubscription() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/subscription/current');
      if (res.statusCode != 200 || res.data == null) {
        throw SubscriptionException('Failed to load subscription');
      }
      return CurrentSubscription.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw SubscriptionException('Session expired. Please log in again.');
      }
      throw SubscriptionException(e.message ?? 'Failed to load subscription');
    }
  }

  /// List plans available for subscription (company portal).
  Future<List<Plan>> getPlansForSubscription() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/subscription/plans');
      if (res.statusCode != 200 || res.data == null) {
        throw SubscriptionException('Failed to load plans');
      }
      final list = res.data!['plans'] as List<dynamic>? ?? [];
      return list
          .map((e) => Plan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw SubscriptionException('Session expired. Please log in again.');
      }
      throw SubscriptionException(e.message ?? 'Failed to load plans');
    }
  }

  /// Initiate subscription for a plan. Returns PaySharp checkout URL if configured.
  Future<InitiateSubscriptionResult> initiateSubscription({
    required int planId,
    int durationMonths = 12,
  }) async {
    await _addAuthToken();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/subscription/initiate',
        data: {'plan_id': planId, 'duration_months': durationMonths},
      );
      if (res.statusCode != 200 || res.data == null) {
        final detail = res.data is Map && res.data!['detail'] != null
            ? res.data!['detail'].toString()
            : 'Failed to initiate subscription';
        throw SubscriptionException(detail);
      }
      return InitiateSubscriptionResult.fromJson(res.data!);
    } on DioException catch (e) {
      final detail = e.response?.data is Map && e.response?.data['detail'] != null
          ? e.response!.data['detail'].toString()
          : (e.message ?? 'Network error');
      throw SubscriptionException(detail);
    }
  }

  /// Payment history for current company.
  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>('/subscription/payments');
      if (res.statusCode != 200 || res.data == null) {
        throw SubscriptionException('Failed to load payments');
      }
      final list = res.data!['payments'] as List<dynamic>? ?? [];
      return list
          .map((e) => PaymentHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw SubscriptionException('Session expired. Please log in again.');
      }
      throw SubscriptionException(e.message ?? 'Failed to load payments');
    }
  }
}

class SubscriptionException implements Exception {
  final String message;
  SubscriptionException(this.message);
  @override
  String toString() => message;
}
