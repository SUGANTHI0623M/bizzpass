import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'auth_repository.dart';

class PaysharpConfig {
  final bool configured;
  final String? apiKeyMasked;
  final String? apiKey;
  final String? secretKey;
  final String? merchantId;
  final bool sandbox;
  final String? apiBaseUrl;

  PaysharpConfig({
    required this.configured,
    this.apiKeyMasked,
    this.apiKey,
    this.secretKey,
    this.merchantId,
    this.sandbox = true,
    this.apiBaseUrl,
  });

  factory PaysharpConfig.fromJson(Map<String, dynamic> j) {
    return PaysharpConfig(
      configured: (j['configured'] as bool?) ?? false,
      apiKeyMasked: j['api_key_masked'] as String?,
      apiKey: j['api_key'] as String?,
      secretKey: j['secret_key'] as String?,
      merchantId: j['merchant_id'] as String?,
      sandbox: (j['sandbox'] as bool?) ?? true,
      apiBaseUrl: j['api_base_url'] as String?,
    );
  }
}

class IntegrationsRepository {
  IntegrationsRepository()
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

  /// Fetch Paysharp config. Set [reveal] true to get full api_key and secret_key in the same response.
  Future<PaysharpConfig> getPaysharpConfig({bool reveal = false}) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/integrations/paysharp',
        queryParameters: reveal ? {'reveal': 'true'} : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        throw IntegrationsException('Failed to fetch Paysharp config');
      }
      return PaysharpConfig.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw IntegrationsException('Session expired. Please log in again.');
      }
      throw IntegrationsException(
        e.response?.data is Map && e.response?.data['detail'] != null
            ? e.response!.data!['detail'].toString()
            : (e.message ?? 'Network error'),
      );
    }
  }

  /// PayPal config for PayPal Checkout payments
  Future<Map<String, dynamic>> getPayPalConfig({bool reveal = false}) async {
    await _addAuthToken();
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/integrations/paypal',
        queryParameters: reveal ? {'reveal': 'true'} : null,
      );
      if (res.statusCode != 200 || res.data == null) {
        return {'configured': false};
      }
      return res.data!;
    } on DioException catch (_) {
      return {'configured': false};
    }
  }

  Future<void> savePayPalConfig({
    required String clientId,
    required String clientSecret,
  }) async {
    await _addAuthToken();
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/integrations/paypal',
        data: {'client_id': clientId.trim(), 'client_secret': clientSecret.trim()},
      );
      if (res.statusCode != 200) {
        final detail = res.data is Map && res.data!['detail'] != null
            ? res.data!['detail'].toString()
            : 'Failed to save PayPal config';
        throw IntegrationsException(detail);
      }
    } on DioException catch (e) {
      throw IntegrationsException(
        e.response?.data is Map && e.response?.data['detail'] != null
            ? e.response!.data!['detail'].toString()
            : (e.message ?? 'Network error'),
      );
    }
  }

  Future<void> savePaysharpConfig({
    required String apiKey,
    String? secretKey,
    String? merchantId,
    bool sandbox = true,
    String? apiBaseUrl,
  }) async {
    await _addAuthToken();
    try {
      final data = <String, dynamic>{
        'api_key': apiKey.trim(),
        'merchant_id': merchantId?.trim(),
        'sandbox': sandbox,
        'api_base_url': (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) ? null : apiBaseUrl.trim(),
      };
      if (secretKey != null && secretKey.trim().isNotEmpty && secretKey.trim() != '••••••••') {
        data['secret_key'] = secretKey.trim();
      }
      final res = await _dio.put<Map<String, dynamic>>(
        '/integrations/paysharp',
        data: data,
      );
      if (res.statusCode != 200) {
        final detail = res.data is Map && res.data!['detail'] != null
            ? res.data!['detail'].toString()
            : 'Failed to save Paysharp config';
        throw IntegrationsException(detail);
      }
    } on DioException catch (e) {
      final detail = e.response?.data is Map && e.response?.data['detail'] != null
          ? e.response!.data!['detail'].toString()
          : (e.message ?? 'Network error');
      throw IntegrationsException(detail);
    }
  }
}

class IntegrationsException implements Exception {
  final String message;
  IntegrationsException(this.message);
  @override
  String toString() => message;
}
