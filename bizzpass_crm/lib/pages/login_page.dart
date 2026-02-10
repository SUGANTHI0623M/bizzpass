import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../bloc/auth_bloc.dart';
import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../theme/app_theme.dart';

/// Login page for BizzPass CRM. Uses existing app theme; no UI changes to rest of app.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool? _backendReachable;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBackend());
  }

  Future<void> _checkBackend() async {
    final ok = await AuthRepository.checkBackendHealth();
    if (mounted) setState(() => _backendReachable = ok);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    developer.log('Login submit pressed',
        name: 'LoginPage',
        error: 'identifier=$identifier, passwordLength=${password.length}');
    if (!_formKey.currentState!.validate()) {
      developer.log('Form validation failed', name: 'LoginPage');
      return;
    }
    context.read<AuthBloc>().add(
          AuthLoginRequested(identifier, password),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.dangerColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_backendReachable == false)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.dangerColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: context.dangerColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: context.dangerColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cannot reach backend at ${ApiConstants.baseUrl}. Start the backend (e.g. docker compose up -d), then tap Retry.',
                                    style: TextStyle(
                                        color: context.textColor, fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    setState(() => _backendReachable = null);
                                    await _checkBackend();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 56,
                        color: context.accentColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BizzPass',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textMutedColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'License key, email or phone',
                          hintText: 'Enter license key, email or phone number',
                          prefixIcon: Icon(LucideIcons.mail, size: 20, color: context.textMutedColor),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'License key, email or phone is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(LucideIcons.lock, size: 20, color: context.textMutedColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                              size: 20,
                              color: context.textMutedColor,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
