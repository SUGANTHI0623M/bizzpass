import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

void _log(String message, [Map<String, dynamic>? data]) {
  developer.log(message, name: 'AuthRepo', error: data?.toString());
}

/// Login response from crm_backend POST /auth/login
class LoginResponse {
  final String token;
  final Map<String, dynamic> user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }
}

/// Handles auth API calls and token persistence. Uses Dio.
class AuthRepository {
  AuthRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;

  /// [identifier] can be license key, email, or phone number.
  Future<LoginResponse> login(String identifier, String password) async {
    const uri = '${ApiConstants.baseUrl}/auth/login';
    _log('Login request', {'url': uri, 'identifier': identifier});
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'identifier': identifier.trim(), 'password': password},
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      _log('Login response', {
        'statusCode': response.statusCode,
        'data': response.data?.toString(),
      });

      if (response.statusCode == 401) {
        _log('Login failed: 401 Unauthorized');
        throw AuthException('Invalid license key, email or phone, or password');
      }
      if (response.statusCode != 200 || response.data == null) {
        final detail = response.data is Map && response.data!['detail'] != null
            ? response.data!['detail'].toString()
            : 'Login failed';
        _log('Login failed: non-200 or null data', {'detail': detail});
        throw AuthException(detail);
      }

      final loginResponse = LoginResponse.fromJson(response.data!);
      await _saveAuth(loginResponse);
      _log('Login success', {
        'user.id': loginResponse.user['id'],
        'user.email': loginResponse.user['email']
      });
      return loginResponse;
    } on DioException catch (e) {
      _log('Login DioException', {
        'type': e.type.toString(),
        'message': e.message,
        'error': e.error?.toString(),
      });
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        throw AuthException(
          'Cannot reach server at ${ApiConstants.baseUrl}. '
          'Start the backend (e.g. docker compose up -d) and try again.',
        );
      }
      rethrow;
    }
  }

  Future<void> _saveAuth(LoginResponse res) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.authTokenKey, res.token);
    await prefs.setString(
      ApiConstants.authUserKey,
      jsonEncode(res.user),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.authTokenKey);
    await prefs.remove(ApiConstants.authUserKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.authTokenKey);
  }

  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(ApiConstants.authUserKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// No-auth health check for backend (e.g. on login page). Returns true if GET /health succeeds.
  static Future<bool> checkBackendHealth() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final res = await dio.get<Map>('/health');
      return res.statusCode == 200 && (res.data?['status'] == 'ok');
    } catch (_) {
      return false;
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
