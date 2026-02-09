import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth_bloc.dart';
import 'data/auth_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/companies_page.dart';
import 'pages/licenses_page.dart';
import 'pages/payments_page.dart';
import 'pages/staff_page.dart';
import 'pages/attendance_page.dart';
import 'pages/visitors_page.dart';
import 'pages/notifications_page.dart';
import 'pages/plans_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/company_admin_dashboard_page.dart';
import 'pages/roles_permissions_page.dart';
import 'pages/audit_logs_page.dart';
import 'pages/branches_page.dart';
import 'pages/departments_page.dart';
import 'pages/leave_placeholder_page.dart';
import 'pages/tasks_placeholder_page.dart';
import 'pages/payroll_placeholder_page.dart';
import 'pages/reports_placeholder_page.dart';
import 'pages/subscription_placeholder_page.dart';
import 'widgets/company_admin_shell.dart';
import 'data/branches_repository.dart';

void main() {
  // Show a visible error instead of white screen if the app throws during build
  if (kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: const Color(0xFF0C0E14),
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFB7185), size: 48),
                const SizedBox(height: 16),
                Text(
                  details.exceptionAsString(),
                  style:
                      const TextStyle(color: Color(0xFFE8EAF0), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    };
  }
  runZonedGuarded(() {
    runApp(const BizzPassApp());
  }, (error, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Uncaught error: $error\n$stack');
    }
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'runZonedGuarded',
    ));
  });
}

class BizzPassApp extends StatelessWidget {
  const BizzPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizzPass Admin CRM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        return Container(
          color: const Color(0xFF0C0E14),
          child: child,
        );
      },
      home: BlocProvider(
        create: (context) =>
            AuthBloc(AuthRepository())..add(AuthCheckRequested()),
        child: const AuthGate(),
      ),
    );
  }
}

/// Shows LoginPage or MainScreen based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _loadingTimeout = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is! AuthInitial && state is! AuthLoading) {
          _AuthGateLoadingState.cancelTimer();
        }
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final role = (state.user['role'] as String? ?? '').toLowerCase();
          final companyId = state.user['company_id'];
          final isSuperAdmin = role == 'super_admin' &&
              (companyId == null || companyId == false);
          if (isSuperAdmin) {
            return const MainScreen();
          }
          if (companyId != null && companyId != false) {
            return CompanyAdminScreen(user: state.user);
          }
          return const _WrongPortalScreen();
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const _AuthGateLoadingState();
        }
        return const LoginPage();
      },
    );
  }
}

/// Visible loading screen with timeout fallback (avoids black screen if auth check hangs on web).
class _AuthGateLoadingState extends StatefulWidget {
  const _AuthGateLoadingState();

  static Timer? _loadingTimer;
  static void cancelTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  State<_AuthGateLoadingState> createState() => _AuthGateLoadingStateState();
}

class _AuthGateLoadingStateState extends State<_AuthGateLoadingState> {
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _AuthGateLoadingState._loadingTimer?.cancel();
    _AuthGateLoadingState._loadingTimer =
        Timer(_AuthGateState._loadingTimeout, () {
      if (!mounted) return;
      setState(() => _showFallback = true);
    });
  }

  @override
  void dispose() {
    _AuthGateLoadingState.cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
            const SizedBox(height: 20),
            Text(
              'Loading…',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 16,
              ),
            ),
            if (_showFallback) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthFallbackToLogin());
                },
                child: const Text('Continue to login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WrongPortalScreen extends StatelessWidget {
  const _WrongPortalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 64, color: Color(0xFFF59E0B)),
              const SizedBox(height: 24),
              const Text(
                'Wrong Portal',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'This portal is for Super Administrators only.\nUse the Company Portal for company access.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthLogoutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyAdminScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const CompanyAdminScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _CompanyAdminScreenStateful(user: user);
  }
}

class _CompanyAdminScreenStateful extends StatefulWidget {
  final Map<String, dynamic> user;

  const _CompanyAdminScreenStateful({required this.user});

  @override
  State<_CompanyAdminScreenStateful> createState() =>
      __CompanyAdminScreenStatefulState();
}

class __CompanyAdminScreenStatefulState
    extends State<_CompanyAdminScreenStateful> {
  String _currentPage = 'dashboard';
  List<Branch> _branches = [];
  int? _selectedBranchId;
  String? _selectedBranchName;

  @override
  void initState() {
    super.initState();
    _loadBranchesIfAllowed();
  }

  Future<void> _loadBranchesIfAllowed() async {
    final permissions = (widget.user['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (!permissions.contains('branch.view')) return;
    try {
      final list = await BranchesRepository().fetchBranches();
      if (mounted) setState(() => _branches = list);
    } catch (_) {}
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 'dashboard':
        return const CompanyAdminDashboardPage();
      case 'staff':
        return StaffPage(
          enableCreate: true,
          branchId: _selectedBranchId,
          branchName: _selectedBranchName,
        );
      case 'branches':
        return BranchesPage(
          onSelectBranch: (id, name) => setState(() {
            _selectedBranchId = id;
            _selectedBranchName = name;
            _currentPage = 'staff';
          }),
        );
      case 'departments':
        return const DepartmentsPage();
      case 'roles':
        return const RolesPermissionsPage();
      case 'attendance':
        return const AttendancePage();
      case 'leave':
        return const LeavePlaceholderPage();
      case 'tasks':
        return const TasksPlaceholderPage();
      case 'visitors':
        return const VisitorsPage();
      case 'payroll':
        return const PayrollPlaceholderPage();
      case 'reports':
        return const ReportsPlaceholderPage();
      case 'subscription':
        return const SubscriptionPlaceholderPage();
      case 'settings':
        return const SettingsPage();
      case 'audit-logs':
        return const AuditLogsPage();
      default:
        return const CompanyAdminDashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.user['permissions'] as List<dynamic>?;
    final hasBranchView =
        permissions?.any((p) => p.toString() == 'branch.view') ?? false;
    return CompanyAdminShell(
      activePage: _currentPage,
      companyName: (widget.user['company_name'] as String?) ?? '',
      permissions: permissions,
      branches: hasBranchView ? _branches : null,
      selectedBranchId: _selectedBranchId,
      selectedBranchName: _selectedBranchName,
      onBranchSelected: hasBranchView
          ? (id, name) => setState(() {
                _selectedBranchId = id;
                _selectedBranchName = name;
              })
          : null,
      onPageChanged: (page) => setState(() => _currentPage = page),
      onLogout: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentPage),
          child: _buildPage(),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentPage = 'companies';

  Widget _buildPage() {
    switch (_currentPage) {
      case 'dashboard':
        return const DashboardPage();
      case 'companies':
        return const CompaniesPage();
      case 'licenses':
        return const LicensesPage();
      case 'payments':
        return const PaymentsPage();
      case 'staff':
        return const StaffPage();
      case 'attendance':
        return const AttendancePage();
      case 'visitors':
        return const VisitorsPage();
      case 'notifications':
        return const NotificationsPage();
      case 'plans':
        return const PlansPage();
      case 'settings':
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activePage: _currentPage,
      onPageChanged: (page) => setState(() => _currentPage = page),
      onLogout: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentPage),
          child: _buildPage(),
        ),
      ),
    );
  }
}
