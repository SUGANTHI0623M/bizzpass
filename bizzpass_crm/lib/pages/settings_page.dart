import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/auth_bloc.dart';
import '../data/auth_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shifts_page.dart';
import 'holidays_settings_page.dart';
import '../data/attendance_modals_repository.dart';
import '../data/fine_modals_repository.dart';
import '../data/shift_modals_repository.dart';
import 'attendance_modals_page.dart';
import 'shift_modals_page.dart';
import 'fine_modals_page.dart';
import 'leave_modals_page.dart';
import 'designations_page.dart';

const int _otpLength = 6;

/// Settings hub: top row (Settings + theme), switch tabs, Company / Business settings.
class SettingsPage extends StatefulWidget {
  /// When set, tapping Branches/Roles/Departments/User Management in Company settings navigates to that page.
  final ValueChanged<String>? onNavigateToPage;

  /// When true (super admin context), show only User Management, no Company/Business tabs.
  final bool isSuperAdmin;

  const SettingsPage({
    super.key,
    this.onNavigateToPage,
    this.isSuperAdmin = false,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// null = main view with tabs; else sub-section id (attendance, payroll, leave, etc.)
  String? _section;
  int _selectedTabIndex = 0; // 0 = Company settings, 1 = Business settings
  int _attendanceModalsCount = 0;
  int _shiftModalsCount = 0;
  int _fineModalsCount = 0;

  @override
  Widget build(BuildContext context) {
    if (_section != null) {
      return _buildSubSection();
    }
    return _buildMainSettingsView();
  }

  Widget _buildMainSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          const SizedBox(height: 24),
          if (!widget.isSuperAdmin) ...[
            _buildTabsRow(),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _selectedTabIndex == 0
                  ? _buildCompanySettingsContent()
                  : _buildBusinessSettingsContent(),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildSuperAdminSettingsContent(),
          ],
        ],
      ),
    );
  }

  /// Super admin: profile details (email) and change password via OTP. No User Management.
  Widget _buildSuperAdminSettingsContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is AuthAuthenticated,
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        final user = state.user;
        final email = user['email'] as String? ?? '—';
        final name = user['name'] as String? ?? 'Super Admin';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card: name + email
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.person_rounded, size: 20, color: context.accentColor),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileRow(label: 'Name', value: name),
                  const SizedBox(height: 8),
                  _ProfileRow(label: 'Email', value: email),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Change password via OTP
            _PolicyCard(
              icon: Icons.lock_reset_rounded,
              title: 'Change password',
              desc: 'Send OTP to your email to set a new password',
              onTap: () => _showChangePasswordDialog(context, email),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, String email) {
    final authRepo = AuthRepository();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool otpSent = false;
    bool loading = false;
    String? error;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              otpSent ? 'Enter OTP & new password' : 'Change password',
              style: TextStyle(color: context.textColor, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.dangerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: context.dangerColor),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error!, style: TextStyle(fontSize: 12, color: context.dangerColor))),
                        ],
                      ),
                    ),
                  ],
                  if (!otpSent) ...[
                    Text(
                      'We will send a one-time code to $email. Use it below to set a new password.',
                      style: TextStyle(fontSize: 13, color: context.textMutedColor),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                setDialogState(() {
                                  loading = true;
                                  error = null;
                                });
                                try {
                                  final token = await authRepo.getToken();
                                  if (token == null || token.isEmpty) {
                                    setDialogState(() {
                                      error = 'Session expired. Please log in again.';
                                      loading = false;
                                    });
                                    return;
                                  }
                                  await authRepo.requestPasswordChangeOtp(token);
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      otpSent = true;
                                      loading = false;
                                      error = null;
                                    });
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('OTP sent to your email. Check your inbox.')),
                                    );
                                  }
                                } on AuthException catch (e) {
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      error = e.message;
                                      loading = false;
                                    });
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      error = e.toString();
                                      loading = false;
                                    });
                                  }
                                }
                              },
                        icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.email_rounded, size: 18),
                        label: Text(loading ? 'Sending…' : 'Send OTP to email'),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpController,
                      decoration: InputDecoration(
                        labelText: 'OTP',
                        hintText: 'Enter 6-digit code',
                        border: const OutlineInputBorder(),
                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: context.dangerColor)),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: _otpLength,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        border: const OutlineInputBorder(),
                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: context.dangerColor)),
                      ),
                      obscureText: true,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        errorBorder: OutlineInputBorder(borderSide: BorderSide(color: context.dangerColor)),
                      ),
                      obscureText: true,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              if (otpSent)
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          final newPwd = newPasswordController.text;
                          final confirmPwd = confirmPasswordController.text;
                          if (otp.length != _otpLength) {
                            setDialogState(() => error = 'Enter the 6-digit OTP from your email.');
                            return;
                          }
                          if (newPwd.length < 8) {
                            setDialogState(() => error = 'Password must be at least 8 characters.');
                            return;
                          }
                          if (newPwd != confirmPwd) {
                            setDialogState(() => error = 'Passwords do not match.');
                            return;
                          }
                          setDialogState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            final token = await authRepo.getToken();
                            if (token == null || token.isEmpty) {
                              setDialogState(() {
                                error = 'Session expired. Please log in again.';
                                loading = false;
                              });
                              return;
                            }
                            await authRepo.changePasswordWithOtp(token, otp, newPwd);
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Password updated successfully.')),
                              );
                            }
                          } on AuthException catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() {
                                error = e.message;
                                loading = false;
                              });
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() {
                                error = e.toString();
                                loading = false;
                              });
                            }
                          }
                        },
                  child: Text(loading ? 'Updating…' : 'Update password'),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Top row: "Settings" heading only + theme toggle.
  Widget _buildTopRow() {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Row(
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.textColor,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
                color: context.accentColor,
              ),
              const SizedBox(width: 10),
              Text(
                isDark ? 'Dark' : 'Light',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textColor,
                ),
              ),
              const SizedBox(width: 14),
              Switch(
                value: isDark,
                onChanged: (value) {
                  themeNotifier.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeTrackColor: context.accentColor.withOpacity(0.5),
                activeThumbColor: context.accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tabs in one row: Company settings | Business settings.
  Widget _buildTabsRow() {
    const tabData = [
      (label: 'Company settings', icon: Icons.business_rounded),
      (label: 'Business settings', icon: Icons.receipt_long_rounded),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabData.length, (i) {
          final selected = _selectedTabIndex == i;
          final tab = tabData[i];
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? context.accentColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(
                            color: context.accentColor.withOpacity(0.4),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 18,
                          color: selected
                              ? context.accentColor
                              : context.textMutedColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? context.accentColor
                                : context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Company settings tab: Branches, Roles & Permissions, Department, User Management.
  Widget _buildCompanySettingsContent() {
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.business_rounded,
          title: 'Branches',
          desc: 'Manage company branches and locations',
          onTap: () => widget.onNavigateToPage?.call('branches'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Roles & Permissions',
          desc: 'Roles and access control',
          onTap: () => widget.onNavigateToPage?.call('roles'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.category_rounded,
          title: 'Department',
          desc: 'Departments and teams',
          onTap: () => widget.onNavigateToPage?.call('departments'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.work_rounded,
          title: 'Designations',
          desc: 'Job titles and designations',
          onTap: () {
            if (widget.onNavigateToPage != null) {
              widget.onNavigateToPage!('designations');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => Scaffold(
                    backgroundColor: ctx.bgColor,
                    body: DesignationsPage(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.person_add_rounded,
          title: 'User Management',
          desc: 'Add and manage admin users',
          onTap: () => widget.onNavigateToPage?.call('user-management'),
        ),
      ],
    );
  }

  Widget _buildSubSection() {
    switch (_section!) {
      case 'attendance':
        return _SettingsSubPage(
          title: 'Attendance Settings',
          subtitle: 'Attendance modals and shifts',
          onBack: () => setState(() => _section = null),
          child: _buildAttendanceSettingsContent(),
        );
      case 'attendance-modals':
        return AttendanceModalsPage(
          onBack: () {
            setState(() {
              _section = 'attendance';
              _attendanceModalsCount = 0;
            });
            _loadAttendanceSectionCounts();
          },
        );
      case 'shift-modals':
        return ShiftModalsPage(
          onBack: () {
            setState(() {
              _section = 'attendance';
              _shiftModalsCount = 0;
            });
            _loadAttendanceSectionCounts();
          },
        );
      case 'fine-modals':
        return FineModalsPage(
          onBack: () {
            setState(() {
              _section = 'attendance';
              _fineModalsCount = 0;
            });
            _loadAttendanceSectionCounts();
          },
        );
      case 'payroll':
        return _SettingsSubPage(
          title: 'Payroll Settings',
          subtitle: 'Payroll and salary configuration',
          onBack: () => setState(() => _section = null),
          child: _buildPayrollSettingsContent(),
        );
      case 'leave':
        return LeaveModalsPage(
          onBack: () => setState(() => _section = null),
        );
      default:
        return _buildMainSettingsView();
    }
  }

  Future<void> _loadAttendanceSectionCounts() async {
    try {
      final att = await AttendanceModalsRepository().fetchModals();
      final sh = await ShiftModalsRepository().fetchModals();
      final fm = await FineModalsRepository().fetchModals();
      if (mounted) {
        setState(() {
          _attendanceModalsCount = att.length;
          _shiftModalsCount = sh.length;
          _fineModalsCount = fm.length;
        });
      }
    } catch (_) {}
  }

  Widget _buildAttendanceSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.tune_rounded,
          title: 'Attendance Modals',
          desc: '$_attendanceModalsCount modal${_attendanceModalsCount == 1 ? '' : 's'} configured',
          onTap: () => setState(() => _section = 'attendance-modals'),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.gavel_rounded,
          title: 'Fine Modals',
          desc: '$_fineModalsCount fine modal${_fineModalsCount == 1 ? '' : 's'} configured',
          onTap: () => setState(() => _section = 'fine-modals'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.schedule_rounded,
          title: 'Shift Settings',
          desc: '$_shiftModalsCount shift${_shiftModalsCount == 1 ? '' : 's'} configured',
          onTap: () {
            if (widget.onNavigateToPage != null) {
              widget.onNavigateToPage!('shifts');
            } else {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => Scaffold(
                    backgroundColor: ctx.bgColor,
                    body: ShiftsPage(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ).then((_) => _loadAttendanceSectionCounts());
            }
          },
        ),
      ],
    );
  }

  Widget _buildBusinessSettingsContent() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.calendar_today_rounded,
          title: 'Attendance Settings',
          desc: 'Attendance modals and shifts',
          onTap: () {
            setState(() => _section = 'attendance');
            _loadAttendanceSectionCounts();
          },
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.payments_rounded,
          title: 'Payroll Settings',
          desc: 'Payroll configuration and salary components',
          onTap: () => setState(() => _section = 'payroll'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.weekend_rounded,
          title: 'Holidays Settings',
          desc: 'Office holidays and weekly off (holiday modal)',
          onTap: () {
            if (widget.onNavigateToPage != null) {
              widget.onNavigateToPage!('holidays-settings');
            } else {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => Scaffold(
                    backgroundColor: ctx.bgColor,
                    body: HolidaysSettingsPage(
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.beach_access_rounded,
          title: 'Leave Settings',
          desc: 'Leave policy and leave types',
          onTap: () => setState(() => _section = 'leave'),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.badge_rounded,
          title: 'Manage Staff Data',
          desc: 'No custom fields',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Manage Staff Data - Coming soon')),
            );
          },
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.cake_rounded,
          title: 'Events & Celebrations',
          desc: 'Edit and modify wishes',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Events & Celebrations - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPayrollSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Payroll Configuration',
          desc: 'Salary components and pay cycles',
          onTap: () {},
        ),
      ],
    );
  }
}

class _SettingsSubPage extends StatelessWidget {
  final String title, subtitle;
  final VoidCallback onBack;
  final Widget child;

  const _SettingsSubPage({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SectionHeader(
                  title: title,
                  subtitle: subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textMutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: context.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final VoidCallback onTap;

  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: context.accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.textDimColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
