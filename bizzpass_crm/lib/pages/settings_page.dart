import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Settings hub: main menu and sub-sections. Uses "modal" (not "template") naming.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// null = main menu; else sub-section id
  String? _section;
  int _attendanceModalsCount = 3; // can be loaded from API later

  @override
  Widget build(BuildContext context) {
    if (_section != null) {
      return _buildSubSection();
    }
    return _buildMainMenu();
  }

  Widget _buildMainMenu() {
    final items = [
      _SettingsCard(
        icon: Icons.people_rounded,
        title: 'User Management',
        desc: 'Manage users, roles, and access for your company',
        onTap: () => setState(() => _section = 'user'),
      ),
      _SettingsCard(
        icon: Icons.calendar_today_rounded,
        title: 'Attendance Settings',
        desc: 'Attendance modals, geofence, shifts, and automation rules',
        onTap: () => setState(() => _section = 'attendance'),
      ),
      _SettingsCard(
        icon: Icons.business_center_rounded,
        title: 'Business Settings',
        desc: 'Holiday and leave modals, weekly off, staff data, celebrations',
        onTap: () => setState(() => _section = 'business'),
      ),
      _SettingsCard(
        icon: Icons.payments_rounded,
        title: 'Payroll Settings',
        desc: 'Payroll configuration and salary components',
        onTap: () => setState(() => _section = 'payroll'),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Settings',
            subtitle: 'Configure your company portal',
          ),
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 700 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 100,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => items[i],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubSection() {
    switch (_section!) {
      case 'user':
        return _SettingsSubPage(
          title: 'User Management',
          subtitle: 'Manage users and access',
          onBack: () => setState(() => _section = null),
          child: _buildUserManagementContent(),
        );
      case 'attendance':
        return _SettingsSubPage(
          title: 'Attendance Settings',
          subtitle: 'Attendance modals, geofence, shifts, and rules',
          onBack: () => setState(() => _section = null),
          child: _buildAttendanceSettingsContent(),
        );
      case 'business':
        return _SettingsSubPage(
          title: 'Business Settings',
          subtitle: 'Policies, holidays, staff data, and more',
          onBack: () => setState(() => _section = null),
          child: _buildBusinessSettingsContent(),
        );
      case 'payroll':
        return _SettingsSubPage(
          title: 'Payroll Settings',
          subtitle: 'Payroll and salary configuration',
          onBack: () => setState(() => _section = null),
          child: _buildPayrollSettingsContent(),
        );
      default:
        return _buildMainMenu();
    }
  }

  Widget _buildUserManagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.person_add_rounded,
          title: 'Manage Users',
          desc: 'Add and manage portal users',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Roles & Permissions',
          desc: 'Define roles and what each can do',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAttendanceSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.tune_rounded,
          title: 'Attendance Modals',
          desc: '$_attendanceModalsCount modals configured',
          onTap: () => _showCreateAttendanceModal(context),
          trailing: TextButton.icon(
            onPressed: () => _showCreateAttendanceModal(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add modal'),
          ),
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.my_location_rounded,
          title: 'Attendance Geofence Settings',
          desc: 'Location-based attendance',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.schedule_rounded,
          title: 'Shift Settings',
          desc: '1 shift configured',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.rule_rounded,
          title: 'Automation Rules',
          desc: 'Automation rules configured',
          onTap: () {},
        ),
      ],
    );
  }

  void _showCreateAttendanceModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CreateAttendanceModalDialog(
        onClose: () => Navigator.of(ctx).pop(),
        onCreate: () {
          setState(() => _attendanceModalsCount++);
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance modal created')),
          );
        },
      ),
    );
  }

  Widget _buildBusinessSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicyCard(
          icon: Icons.celebration_rounded,
          title: 'Holiday Policy',
          desc: '1 modal',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.beach_access_rounded,
          title: 'Leave Policy',
          desc: '1 modal',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.functions_rounded,
          title: 'Manage Business Functions',
          desc: 'No functions',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.badge_rounded,
          title: 'Manage Staff Data',
          desc: 'No custom fields',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.weekend_rounded,
          title: 'Weekly Holidays',
          desc: 'Odd/Even Saturday pattern',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.person_rounded,
          title: 'Manage Users',
          desc: '1 user',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.cake_rounded,
          title: 'Celebrations',
          desc: 'Edit and modify wishes',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _PolicyCard(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Roles & Permissions',
          desc: 'No roles',
          onTap: () {},
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

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final VoidCallback onTap;

  const _SettingsCard({
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

/// Create Attendance Modal dialog. Uses "modal" (not "template") naming.
class _CreateAttendanceModalDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onCreate;

  const _CreateAttendanceModalDialog({
    required this.onClose,
    required this.onCreate,
  });

  @override
  State<_CreateAttendanceModalDialog> createState() =>
      _CreateAttendanceModalDialogState();
}

class _CreateAttendanceModalDialogState
    extends State<_CreateAttendanceModalDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _active = true;
  bool _requireGeolocation = false;
  bool _requireSelfie = false;
  bool _allowOnHolidays = false;
  bool _allowOnWeeklyOff = false;
  bool _allowLateEntry = true;
  bool _allowEarlyExit = true;
  bool _allowOvertime = true;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modal name is required')),
      );
      return;
    }
    widget.onCreate();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Attendance Modal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure attendance modal settings and requirements',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Modal Name *',
                        hintText:
                            'e.g. Standard Attendance, Selfie & Location',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _desc,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe this attendance modal...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Active Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Switch(
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                          activeColor: AppColors.accent,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Only active modals can be assigned to staff',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Attendance Requirements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      label: 'Require Geolocation',
                      subtitle:
                          'Employees must provide location when marking attendance',
                      value: _requireGeolocation,
                      onChanged: (v) =>
                          setState(() => _requireGeolocation = v),
                    ),
                    _ToggleRow(
                      label: 'Require Selfie',
                      subtitle:
                          'Employees must take a selfie when marking attendance',
                      value: _requireSelfie,
                      onChanged: (v) => setState(() => _requireSelfie = v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Attendance Rules',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      label: 'Allow Attendance on Holidays',
                      subtitle: 'Allow employees to mark attendance on holiday days',
                      value: _allowOnHolidays,
                      onChanged: (v) => setState(() => _allowOnHolidays = v),
                    ),
                    _ToggleRow(
                      label: 'Allow Attendance on Weekly Off',
                      subtitle:
                          'Allow employees to mark attendance on weekly off days',
                      value: _allowOnWeeklyOff,
                      onChanged: (v) => setState(() => _allowOnWeeklyOff = v),
                    ),
                    _ToggleRow(
                      label: 'Allow Late Entry',
                      subtitle:
                          'Allow employees to mark attendance after shift start time',
                      value: _allowLateEntry,
                      onChanged: (v) => setState(() => _allowLateEntry = v),
                    ),
                    _ToggleRow(
                      label: 'Allow Early Exit',
                      subtitle:
                          'Allow employees to mark exit before shift end time',
                      value: _allowEarlyExit,
                      onChanged: (v) => setState(() => _allowEarlyExit = v),
                    ),
                    _ToggleRow(
                      label: 'Allow Overtime',
                      subtitle:
                          'Allow employees to work beyond shift end time',
                      value: _allowOvertime,
                      onChanged: (v) => setState(() => _allowOvertime = v),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Modal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
