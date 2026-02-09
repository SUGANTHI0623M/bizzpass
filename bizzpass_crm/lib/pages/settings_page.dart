import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shifts_page.dart';
import 'holidays_settings_page.dart';
import '../data/attendance_modals_repository.dart';
import '../data/shift_modals_repository.dart';
import 'attendance_modals_page.dart';
import 'shift_modals_page.dart';
import 'leave_modals_page.dart';

/// Settings hub: main menu and sub-sections. Uses "modal" (not "template") naming.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// null = main menu; else sub-section id
  String? _section;
  int _attendanceModalsCount = 0;
  int _shiftModalsCount = 0;

  @override
  Widget build(BuildContext context) {
    // Only two outcomes: Business Settings list (no 4-card menu) or a sub-section (attendance, payroll, leave, etc.)
    if (_section != null) {
      return _buildSubSection();
    }
    return KeyedSubtree(
      key: const ValueKey<String>('settings_business_list'),
      child: _buildBusinessSettingsList(),
    );
  }

  /// When Settings is clicked, show Business Settings list directly.
  /// No 4-card menu, no User Management, no Manage Business Functions.
  /// Order: Attendance Settings, Payroll Settings, Holidays Settings, Leave Settings, Manage Staff Data, Events & Celebrations.
  Widget _buildBusinessSettingsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Business Settings',
            subtitle: 'Policies, holidays, staff data, and more',
          ),
          const SizedBox(height: 20),
          _buildBusinessSettingsContent(),
        ],
      ),
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
              _attendanceModalsCount = 0; // will reload
            });
            _loadAttendanceSectionCounts();
          },
        );
      case 'shift-modals':
        return ShiftModalsPage(
          onBack: () {
            setState(() {
              _section = 'attendance';
              _shiftModalsCount = 0; // will reload
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
        return _buildBusinessSettingsList();
    }
  }

  Future<void> _loadAttendanceSectionCounts() async {
    try {
      final att = await AttendanceModalsRepository().fetchModals();
      final sh = await ShiftModalsRepository().fetchModals();
      if (mounted) {
        setState(() {
          _attendanceModalsCount = att.length;
          _shiftModalsCount = sh.length;
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
        _PolicyCard(
          icon: Icons.schedule_rounded,
          title: 'Shift Settings',
          desc: '$_shiftModalsCount shift${_shiftModalsCount == 1 ? '' : 's'} configured',
          onTap: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.bg,
                  body: ShiftsPage(
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
            );
            _loadAttendanceSectionCounts();
          },
        ),
      ],
    );
  }

  Widget _buildBusinessSettingsContent() {
    return Column(
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
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.bg,
                  body: HolidaysSettingsPage(
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
            );
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
              const SnackBar(content: Text('Events & Celebrations - Coming soon')),
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
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
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

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.trailing,
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textDim,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
