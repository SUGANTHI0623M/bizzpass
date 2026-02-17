import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bloc/auth_bloc.dart';
import 'data/auth_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/companies_page.dart';
import 'pages/company_detail_page.dart';
import 'pages/licenses_page.dart';
import 'pages/payments_page.dart';
import 'pages/staff_page.dart';
import 'pages/create_staff_page.dart';
import 'pages/staff_details_page.dart';
import 'data/staff_repository.dart';
import 'data/roles_repository.dart';
import 'pages/attendance_page.dart';
import 'pages/visitors_page.dart';
import 'pages/notifications_page.dart';
import 'pages/plans_page.dart';
import 'pages/settings_page.dart';
import 'pages/login_page.dart';
import 'pages/new_company_admin_dashboard.dart';
import 'pages/roles_permissions_page.dart';
import 'pages/audit_logs_page.dart';
import 'pages/branches_page.dart';
import 'pages/departments_page.dart';
import 'pages/leave_placeholder_page.dart';
import 'pages/tasks_placeholder_page.dart';
import 'pages/payroll_page.dart';
import 'pages/reports_placeholder_page.dart';
import 'pages/subscription_page.dart';
import 'pages/company_profile_page.dart';
import 'pages/branch_detail_page.dart';
import 'pages/user_management_page.dart';
import 'pages/super_admin_user_management_page.dart';
import 'pages/create_platform_admin_page.dart';
import 'pages/integrations_page.dart';
import 'pages/shifts_page.dart';
import 'pages/holidays_settings_page.dart';
import 'pages/designations_page.dart';
import 'widgets/company_admin_shell.dart';
import 'data/branches_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load saved theme before first frame so light theme applies immediately (no dark flash on refresh).
  ThemeMode initialTheme = ThemeMode.dark;
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'dark';
    initialTheme = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  } catch (_) {}

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
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeNotifier(initialTheme),
        child: const BizzPassApp(),
      ),
    );
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
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'BizzPass Admin CRM',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: themeNotifier.themeMode,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              color: isDark ? const Color(0xFF0C0E14) : const Color(0xFFF8F9FC),
              child: child,
            );
          },
          home: BlocProvider(
            create: (context) =>
                AuthBloc(AuthRepository())..add(AuthCheckRequested()),
            child: const AuthGate(),
          ),
        );
      },
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
  Branch? _selectedBranchForDetail;
  Branch? _initialEditBranch;
  Branch? _branchForDetailAfterEdit;
  int? _editStaffId;
  int? _staffDetailId;

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
        return NewCompanyAdminDashboard(
          companyName: (widget.user['company_name'] as String?) ?? '',
        );
      case 'staff':
        return StaffPage(
          enableCreate: true,
          branchId: _selectedBranchId,
          branchName: _selectedBranchName,
          onAddStaff: () => setState(() => _currentPage = 'create-staff'),
          onEditStaff: (s) => setState(() {
            _editStaffId = s.id;
            _currentPage = 'edit-staff';
          }),
          onViewStaff: (s) => setState(() {
            _staffDetailId = s.id;
            _currentPage = 'staff-detail';
          }),
        );
      case 'create-staff':
        return CreateStaffPage(
          staffRepo: StaffRepository(),
          rolesRepo: RolesRepository(),
          onBack: () => setState(() => _currentPage = 'staff'),
        );
      case 'edit-staff':
        return _editStaffId != null
            ? CreateStaffPage(
                staffRepo: StaffRepository(),
                rolesRepo: RolesRepository(),
                initialStaffId: _editStaffId,
                onBack: () => setState(() {
                  _editStaffId = null;
                  _currentPage = 'staff';
                }),
              )
            : const SizedBox.shrink();
      case 'staff-detail':
        return _staffDetailId != null
            ? StaffDetailsPage(
                staffId: _staffDetailId!,
                onBack: () => setState(() {
                  _staffDetailId = null;
                  _currentPage = 'staff';
                }),
                onEdit: (staff) => setState(() {
                  _editStaffId = staff.id;
                  _currentPage = 'edit-staff';
                }),
                onStaffUpdated: () => setState(() {}),
              )
            : const SizedBox.shrink();
      case 'branches':
        final initialEdit = _initialEditBranch;
        if (initialEdit != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initialEditBranch = null);
          });
        }
        return BranchesPage(
          initialEditBranch: initialEdit,
          onBranchTap: (branch) => setState(() {
            _selectedBranchForDetail = branch;
            _currentPage = 'branch-detail';
          }),
          onEditFormClosed: _branchForDetailAfterEdit != null
              ? () => setState(() {
                    _selectedBranchForDetail = _branchForDetailAfterEdit;
                    _branchForDetailAfterEdit = null;
                    _initialEditBranch = null;
                    _currentPage = 'branch-detail';
                  })
              : null,
        );
      case 'branch-detail':
        return _selectedBranchForDetail != null
            ? BranchDetailPage(
                branch: _selectedBranchForDetail!,
                onBack: () => setState(() {
                  _selectedBranchForDetail = null;
                  _initialEditBranch = null;
                  _branchForDetailAfterEdit = null;
                  _currentPage = 'branches';
                }),
                onEdit: () => setState(() {
                  _branchForDetailAfterEdit = _selectedBranchForDetail;
                  _initialEditBranch = _selectedBranchForDetail;
                  _selectedBranchForDetail = null;
                  _currentPage = 'branches';
                }),
                onStatusChanged: () async {
                  final branch = _selectedBranchForDetail!;
                  try {
                    await BranchesRepository().setBranchStatus(
                      branch.id,
                      branch.isActive ? 'inactive' : 'active',
                    );
                    await _loadBranchesIfAllowed();
                    if (!mounted) return;
                    final updated = _branches.where((b) => b.id == branch.id).toList();
                    if (updated.isNotEmpty) {
                      setState(() => _selectedBranchForDetail = updated.first);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
              )
            : const SizedBox.shrink();
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
        return const PayrollPage();
      case 'reports':
        return const ReportsPlaceholderPage();
      case 'subscription':
        return const SubscriptionPage();
      case 'profile':
        return CompanyProfilePage(
          onBack: () => setState(() => _currentPage = 'dashboard'),
        );
      case 'settings':
        return SettingsPage(
          onNavigateToPage: (page) => setState(() => _currentPage = page),
        );
      case 'user-management':
        return UserManagementPage(
          onBack: () => setState(() => _currentPage = 'settings'),
          onAddAdmin: () => setState(() => _currentPage = 'create-admin'),
          onSelectAdmin: (staff) => setState(() {
            _staffDetailId = staff.id;
            _currentPage = 'staff-detail';
          }),
        );
      case 'create-admin':
        return CreateStaffPage(
          staffRepo: StaffRepository(),
          rolesRepo: RolesRepository(),
          onBack: () => setState(() => _currentPage = 'user-management'),
          isAdminCreation: true,
        );
      case 'audit-logs':
        return const AuditLogsPage();
      case 'shifts':
        return ShiftsPage(
          onBack: () => setState(() => _currentPage = 'settings'),
        );
      case 'holidays-settings':
        return HolidaysSettingsPage(
          onBack: () => setState(() => _currentPage = 'settings'),
        );
      case 'designations':
        return DesignationsPage(
          onBack: () => setState(() => _currentPage = 'settings'),
        );
      default:
        return NewCompanyAdminDashboard(
          companyName: (widget.user['company_name'] as String?) ?? '',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.user['permissions'] as List<dynamic>?;
    final hasBranchView =
        permissions?.any((p) => p.toString() == 'branch.view') ?? false;
    return CompanyAdminShell(
      activePage: _currentPage == 'branch-detail'
          ? 'branches'
          : (_currentPage == 'create-staff' || _currentPage == 'edit-staff' || _currentPage == 'staff-detail')
              ? 'staff'
              : (_currentPage == 'user-management' || _currentPage == 'create-admin' || _currentPage == 'shifts' || _currentPage == 'holidays-settings' || _currentPage == 'designations')
                  ? 'settings'
                  : _currentPage,
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
  int? _companyDetailId;
  bool _companyDetailIsEdit = false;

  Widget _buildPage() {
    switch (_currentPage) {
      case 'dashboard':
        return const DashboardPage();
      case 'companies':
        return CompaniesPage(
          onViewCompany: (c) => setState(() {
            _companyDetailId = c.id;
            _companyDetailIsEdit = false;
            _currentPage = 'company-detail';
          }),
          onEditCompany: (c) => setState(() {
            _companyDetailId = c.id;
            _companyDetailIsEdit = true;
            _currentPage = 'company-detail';
          }),
        );
      case 'company-detail':
        return _companyDetailId != null
            ? CompanyDetailPage(
                companyId: _companyDetailId!,
                initialIsEdit: _companyDetailIsEdit,
                onBack: () => setState(() {
                  _companyDetailId = null;
                  _currentPage = 'companies';
                }),
              )
            : const SizedBox.shrink();
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
      case 'integrations':
        return const IntegrationsPage();
      case 'settings':
        return SettingsPage(
          isSuperAdmin: true,
          onNavigateToPage: (page) => setState(() => _currentPage = page),
        );
      case 'user-management':
        return SuperAdminUserManagementPage(
          onBack: () => setState(() => _currentPage = 'settings'),
          onAddAdmin: () => setState(() => _currentPage = 'create-admin'),
        );
      case 'create-admin':
        return CreatePlatformAdminPage(
          onBack: () => setState(() => _currentPage = 'user-management'),
        );
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activePage: _currentPage == 'company-detail'
          ? 'companies'
          : (_currentPage == 'user-management' || _currentPage == 'create-admin')
              ? 'settings'
              : _currentPage,
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

