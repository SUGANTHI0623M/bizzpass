import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';

void _log(String message, [String? detail]) {
  developer.log(message, name: 'AuthBloc', error: detail);
}

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  /// License key, email, or phone number.
  final String identifier;
  final String password;

  AuthLoginRequested(this.identifier, this.password);
}

class AuthLogoutRequested extends AuthEvent {}

/// Used when auth check is taking too long (e.g. web storage hang) to show login.
class AuthFallbackToLogin extends AuthEvent {}

// ─── States ─────────────────────────────────────────────────────────────────

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  AuthAuthenticated(this.token, this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

// ─── Bloc ──────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthFallbackToLogin>(_onFallbackToLogin);
  }

  void _onFallbackToLogin(AuthFallbackToLogin event, Emitter<AuthState> emit) {
    _log('AuthFallbackToLogin');
    emit(AuthUnauthenticated());
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('AuthCheckRequested');
    try {
      final token = await _authRepository.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('Auth check timeout reading token');
          return null;
        },
      );
      final user = await _authRepository.getSavedUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('Auth check timeout reading user');
          return null;
        },
      );
      _log('Auth check result',
          'token=${token != null ? "present" : "null"}, user=${user != null ? "present" : "null"}');
      if (token != null && token.isNotEmpty && user != null) {
        emit(AuthAuthenticated(token, user));
        _log('Emitted AuthAuthenticated');
      } else {
        emit(AuthUnauthenticated());
        _log('Emitted AuthUnauthenticated');
      }
    } catch (e, st) {
      _log('Auth check error', '$e\n$st');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _log('AuthLoginRequested', 'identifier=${event.identifier}');
    emit(AuthLoading());
    try {
      final res = await _authRepository.login(event.identifier, event.password);
      emit(AuthAuthenticated(res.token, res.user));
      _log('Login success', 'user=${res.user['email']}');
    } on AuthException catch (e) {
      _log('Login AuthException', e.message);
      emit(AuthError(e.message));
    } catch (e, st) {
      _log('Login unexpected error', '$e\n$st');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
