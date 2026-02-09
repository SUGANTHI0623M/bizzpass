import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/staff_repository.dart';
import '../data/roles_repository.dart';
import '../data/branches_repository.dart';
import '../data/departments_repository.dart';
import '../data/attendance_modals_repository.dart';
import '../data/shift_modals_repository.dart';
import '../data/leave_modals_repository.dart';
import 'staff_details_page.dart';

/// Option for attendance / shift / leave / holiday modal dropdowns in staff creation.
class StaffModalOption {
  final int id;
  final String name;
  const StaffModalOption(this.id, this.name);
}

class StaffPage extends StatefulWidget {
  /// When true (company admin), show Add Staff button and create dialog.
  final bool enableCreate;

  /// When set, filter staff by this branch (e.g. when viewing a branch).
  final int? branchId;
  final String? branchName;
  const StaffPage(
      {super.key, this.enableCreate = false, this.branchId, this.branchName});
  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final StaffRepository _repo = StaffRepository();
  final RolesRepository _rolesRepo = RolesRepository();
  final BranchesRepository _branchesRepo = BranchesRepository();
  final DepartmentsRepository _departmentsRepo = DepartmentsRepository();
  final AttendanceModalsRepository _attendanceModalsRepo = AttendanceModalsRepository();
  final ShiftModalsRepository _shiftModalsRepo = ShiftModalsRepository();
  final LeaveModalsRepository _leaveModalsRepo = LeaveModalsRepository();
  List<Staff> _staff = [];
  List<Branch> _branches = [];
  List<Department> _departments = [];
  List<StaffModalOption> _attendanceModals = [];
  List<StaffModalOption> _shiftModals = [];
  List<StaffModalOption> _leaveModals = [];
  List<StaffModalOption> _holidayModals = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _tab = 'all';
  bool _showCreateDialog = false;
  Staff? _editingStaff;
  String? _filterDepartment;
  String? _filterJoiningFrom;
  String? _filterJoiningTo;
  int? _filterBranchId;
  final _joiningFromController = TextEditingController();
  final _joiningToController = TextEditingController();

  int? get _effectiveBranchId => widget.branchId ?? _filterBranchId;

  @override
  void dispose() {
    _joiningFromController.dispose();
    _joiningToController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _filterBranchId = widget.branchId;
    _load();
    if (widget.enableCreate) {
      _loadBranchesAndDepartments();
      _loadModalsFromSettings();
    }
  }

  Future<void> _loadBranchesAndDepartments() async {
    try {
      final branches = await _branchesRepo.fetchBranches();
      final departments = await _departmentsRepo.fetchDepartments();
      if (mounted)
        setState(() {
          _branches = branches;
          _departments = departments;
        });
    } catch (_) {}
  }

  Future<void> _loadModalsFromSettings() async {
    try {
      final att = await _attendanceModalsRepo.fetchModals();
      final shift = await _shiftModalsRepo.fetchModals();
      final leave = await _leaveModalsRepo.fetchModals();
      if (mounted) {
        setState(() {
          _attendanceModals = att.map((m) => StaffModalOption(m.id, m.name)).toList();
          _shiftModals = shift.map((m) => StaffModalOption(m.id, m.name)).toList();
          _leaveModals = leave.map((m) => StaffModalOption(m.id, m.name)).toList();
          _holidayModals = [];
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchStaff(
        search: _search.trim().isEmpty ? null : _search.trim(),
        tab: _tab,
        department: _filterDepartment,
        joiningDateFrom: _filterJoiningFrom,
        joiningDateTo: _filterJoiningTo,
        branchId: _effectiveBranchId,
      );
      if (mounted) {
        setState(() {
          _staff = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('StaffException: ', '');
        });
      }
    }
  }

  List<Staff> get _filtered {
    // Tab filtering is done by the API; only apply local search if not sent to API
    if (_search.trim().isEmpty) return _staff;
    final s = _search.trim().toLowerCase();
    return _staff.where((st) {
      return st.name.toLowerCase().contains(s) ||
          st.company.toLowerCase().contains(s) ||
          st.department.toLowerCase().contains(s);
    }).toList();
  }

  void _openCreateStaff() {
    setState(() => _showCreateDialog = true);
  }

  void _openStaffDetails(Staff s) {
    Navigator.of(context).push<Staff?>(
      MaterialPageRoute<Staff?>(
        builder: (ctx) => Scaffold(
          backgroundColor: AppColors.bg,
          body: StaffDetailsPage(
            staffId: s.id,
            initialStaff: s,
            onBack: () => Navigator.of(ctx).pop(),
            onEdit: (staff) => Navigator.of(ctx).pop(staff),
            onStaffUpdated: _load,
          ),
        ),
      ),
    ).then((result) {
      if (result != null && mounted) setState(() => _editingStaff = result);
    });
  }

  Future<void> _submitCreateStaff({
    required String fullName,
    required String email,
    String? phone,
    String? employeeId,
    String? department,
    String? designation,
    String? joiningDate,
    String loginMethod = 'password',
    String? temporaryPassword,
    required int roleId,
    String status = 'active',
    int? branchId,
    int? attendanceModalId,
    int? shiftModalId,
    int? leaveModalId,
    int? holidayModalId,
  }) async {
    await _repo.createStaff(
      fullName: fullName,
      email: email,
      phone: phone,
      employeeId: employeeId,
      department: department,
      designation: designation,
      joiningDate: joiningDate,
      loginMethod: loginMethod,
      temporaryPassword: temporaryPassword,
      roleId: roleId,
      status: status,
      branchId: branchId,
      attendanceModalId: attendanceModalId,
      leaveModalId: leaveModalId,
      holidayModalId: holidayModalId,
    );
    if (mounted) {
      setState(() => _showCreateDialog = false);
      _load();
    }
  }

  Future<void> _updateStaff(
    int staffId, {
    String? fullName,
    String? phone,
    String? department,
    String? designation,
    String? status,
    int? roleId,
    int? branchId,
  }) async {
    await _repo.updateStaff(
      staffId,
      fullName: fullName,
      phone: phone,
      department: department,
      designation: designation,
      status: status,
      roleId: roleId,
      branchId: branchId,
    );
    if (mounted) {
      setState(() => _editingStaff = null);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Staff',
                  subtitle: widget.enableCreate
                      ? '${_staff.length} employees'
                      : '${_staff.length} employees across all companies',
                ),
              ),
              if (widget.enableCreate)
                TextButton.icon(
                  onPressed: _openCreateStaff,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Staff'),
                ),
            ],
          ),
          if (_showCreateDialog)
            _CreateStaffDialog(
              onClose: () => setState(() => _showCreateDialog = false),
              onSubmit: _submitCreateStaff,
              staffRepo: _repo,
              rolesRepo: _rolesRepo,
              branches: _branches,
              initialBranchId: _effectiveBranchId,
              attendanceModals: _attendanceModals,
              shiftModals: _shiftModals,
              leaveModals: _leaveModals,
              holidayModals: _holidayModals,
            ),
          if (_editingStaff != null)
            _EditStaffDialog(
              staff: _editingStaff!,
              branches: _branches,
              departments: _departments,
              rolesRepo: _rolesRepo,
              onClose: () => setState(() => _editingStaff = null),
              onSave: _updateStaff,
            ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
            if (_error!.toLowerCase().contains('cannot reach the backend'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  ApiConstants.backendUnreachableHint,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: _staff.length),
              TabItem(
                  id: 'active',
                  label: 'Active',
                  count: _staff.where((s) => s.status == 'active').length),
              TabItem(
                  id: 'inactive',
                  label: 'Inactive',
                  count: _staff.where((s) => s.status != 'active').length),
            ],
            active: _tab,
            onChanged: (v) => setState(() {
              _tab = v;
              _load();
            }),
          ),
          AppSearchBar(
              hint: 'Search by name, company, or department...',
              onChanged: (v) => setState(() {
                    _search = v;
                    if (v.isEmpty) _load();
                  })),
          if (widget.enableCreate) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    value: _filterDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      ..._departments.map((d) =>
                          DropdownMenuItem(value: d.name, child: Text(d.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _filterDepartment = v);
                      _load();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    value: _filterBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Branch',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('All')),
                      ..._branches.map((b) => DropdownMenuItem(
                          value: b.id, child: Text(b.branchName))),
                    ],
                    onChanged: widget.branchId != null
                        ? null
                        : (v) {
                            setState(() => _filterBranchId = v);
                            _load();
                          },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _joiningFromController,
                    decoration: const InputDecoration(
                      labelText: 'Joining from (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _joiningToController,
                    decoration: const InputDecoration(
                      labelText: 'Joining to (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterJoiningFrom =
                          _joiningFromController.text.trim().isEmpty
                              ? null
                              : _joiningFromController.text.trim();
                      _filterJoiningTo =
                          _joiningToController.text.trim().isEmpty
                              ? null
                              : _joiningToController.text.trim();
                    });
                    _load();
                  },
                  icon: const Icon(Icons.filter_list_rounded, size: 18),
                  label: const Text('Apply filters'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_loading && _staff.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else
            AppDataTable(
              columns: [
                const DataCol('Employee'),
                if (!widget.enableCreate) const DataCol('Company'),
                const DataCol('Designation'),
                const DataCol('Department'),
                if (widget.enableCreate) ...[
                  const DataCol('Role'),
                  const DataCol('Branch'),
                ],
                const DataCol('Status'),
                const DataCol('Joined'),
                if (widget.enableCreate) const DataCol('Actions'),
              ],
              rows: filtered
                  .map((s) => DataRow(
                        cells: [
                          DataCell(
                            InkWell(
                              onTap: widget.enableCreate
                                  ? () => _openStaffDetails(s)
                                  : null,
                              child: Row(children: [
                                AvatarCircle(
                                    name: s.name, seed: s.id, round: true),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text)),
                                    Text(s.employeeId,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textDim)),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          if (!widget.enableCreate) DataCell(Text(s.company)),
                          DataCell(Text(s.designation)),
                          DataCell(Text(s.department)),
                          if (widget.enableCreate) ...[
                            DataCell(Text(s.roleName ?? '—')),
                            DataCell(Text(s.branchName ?? '—')),
                          ],
                          DataCell(StatusBadge(status: s.status)),
                          DataCell(Text(s.joiningDate)),
                          if (widget.enableCreate)
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 20),
                                  onPressed: () => _openStaffDetails(s),
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () =>
                                      setState(() => _editingStaff = s),
                                  tooltip: 'Edit',
                                ),
                                if (s.status == 'active')
                                  IconButton(
                                    icon: const Icon(Icons.toggle_on_rounded,
                                        size: 24, color: AppColors.accent),
                                    onPressed: () async {
                                      try {
                                        await _updateStaff(s.id,
                                            status: 'inactive');
                                        if (mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Staff deactivated')));
                                      } catch (e) {
                                        if (mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                      }
                                    },
                                    tooltip: 'Deactivate',
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.toggle_off_rounded,
                                        size: 24),
                                    onPressed: () async {
                                      try {
                                        await _updateStaff(s.id,
                                            status: 'active');
                                        if (mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Staff activated')));
                                      } catch (e) {
                                        if (mounted)
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(e.toString())));
                                      }
                                    },
                                    tooltip: 'Activate',
                                  ),
                              ],
                            )),
                        ],
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CreateStaffDialog extends StatefulWidget {
  final VoidCallback onClose;
  final Future<void> Function({
    required String fullName,
    required String email,
    String? phone,
    String? employeeId,
    String? department,
    String? designation,
    String? joiningDate,
    String loginMethod,
    String? temporaryPassword,
    required int roleId,
    String status,
    int? branchId,
    int? attendanceModalId,
    int? shiftModalId,
    int? leaveModalId,
    int? holidayModalId,
  }) onSubmit;
  final StaffRepository staffRepo;
  final RolesRepository rolesRepo;
  final List<Branch> branches;
  final int? initialBranchId;
  final List<StaffModalOption> attendanceModals;
  final List<StaffModalOption> shiftModals;
  final List<StaffModalOption> leaveModals;
  final List<StaffModalOption> holidayModals;

  const _CreateStaffDialog({
    required this.onClose,
    required this.onSubmit,
    required this.staffRepo,
    required this.rolesRepo,
    this.branches = const [],
    this.initialBranchId,
    this.attendanceModals = const [],
    this.shiftModals = const [],
    this.leaveModals = const [],
    this.holidayModals = const [],
  });

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _employeeId = TextEditingController();
  final _department = TextEditingController();
  final _designation = TextEditingController();
  final _joiningDate = TextEditingController();
  final _tempPassword = TextEditingController();
  String _loginMethod = 'password';
  String _status = 'active';
  int? _selectedRoleId;
  int? _selectedBranchId;
  int? _selectedAttendanceModalId;
  int? _selectedShiftModalId;
  int? _selectedLeaveModalId;
  int? _selectedHolidayModalId;
  List<Role> _roles = [];
  Map<String, dynamic> _limits = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranchId;
    if (widget.attendanceModals.isNotEmpty) {
      _selectedAttendanceModalId = widget.attendanceModals.first.id;
    }
    if (widget.shiftModals.isNotEmpty) {
      _selectedShiftModalId = widget.shiftModals.first.id;
    }
    if (widget.leaveModals.isNotEmpty) {
      _selectedLeaveModalId = widget.leaveModals.first.id;
    }
    if (widget.holidayModals.isNotEmpty) {
      _selectedHolidayModalId = widget.holidayModals.first.id;
    }
    _loadRolesAndLimits();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _employeeId.dispose();
    _department.dispose();
    _designation.dispose();
    _joiningDate.dispose();
    _tempPassword.dispose();
    super.dispose();
  }

  Future<void> _loadRolesAndLimits() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await widget.rolesRepo.fetchRoles();
      final limits = await widget.staffRepo.getStaffLimits();
      if (mounted) {
        setState(() {
          _roles = roles;
          _limits = limits;
          _loading = false;
          if (_roles.isNotEmpty && _selectedRoleId == null) {
            _selectedRoleId = _roles.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim().toLowerCase();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required')),
      );
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is required')),
      );
      return;
    }
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }
    if (widget.attendanceModals.isNotEmpty && _selectedAttendanceModalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an attendance modal. Create one in Settings > Attendance Settings > Attendance Modals.',
          ),
        ),
      );
      return;
    }
    final maxUsers = _limits['maxUsers'] as int?;
    final currentUsers = (_limits['currentUsers'] as int?) ?? 0;
    if (maxUsers != null && currentUsers >= maxUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('User limit reached. Upgrade plan to add more staff.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        fullName: name,
        email: email,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        employeeId:
            _employeeId.text.trim().isEmpty ? null : _employeeId.text.trim(),
        department:
            _department.text.trim().isEmpty ? null : _department.text.trim(),
        designation:
            _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        joiningDate:
            _joiningDate.text.trim().isEmpty ? null : _joiningDate.text.trim(),
        loginMethod: _loginMethod,
        temporaryPassword: _tempPassword.text.trim().isEmpty
            ? null
            : _tempPassword.text.trim(),
        roleId: _selectedRoleId!,
        status: _status,
        branchId: _selectedBranchId,
        attendanceModalId: _selectedAttendanceModalId,
        shiftModalId: _selectedShiftModalId,
        leaveModalId: _selectedLeaveModalId,
        holidayModalId: _selectedHolidayModalId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('StaffException: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxUsers = _limits['maxUsers'] as int?;
    final currentUsers = (_limits['currentUsers'] as int?) ?? 0;
    final licenseActive = _limits['licenseActive'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Add Staff',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (!_loading && !licenseActive)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'License is not active. Cannot add staff.',
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          if (maxUsers != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Staff: $currentUsers / $maxUsers',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _employeeId,
              decoration: const InputDecoration(
                labelText: 'Employee ID (optional, auto-generated if empty)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _department,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _designation,
              decoration: const InputDecoration(
                labelText: 'Designation',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _joiningDate,
              decoration: const InputDecoration(
                labelText: 'Joining Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedRoleId,
              decoration: const InputDecoration(
                labelText: 'Role *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _roles
                  .map((r) => DropdownMenuItem(
                        value: r.id,
                        child: Text(r.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoleId = v),
            ),
            const SizedBox(height: 8),
            if (widget.attendanceModals.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedAttendanceModalId,
                decoration: const InputDecoration(
                  labelText: 'Attendance Modal *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.attendanceModals
                    .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedAttendanceModalId = v),
              ),
            if (widget.attendanceModals.isNotEmpty) const SizedBox(height: 8),
            if (widget.shiftModals.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _selectedShiftModalId,
                decoration: const InputDecoration(
                  labelText: 'Shift Modal',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('— None')),
                  ...widget.shiftModals.map((m) =>
                      DropdownMenuItem(value: m.id, child: Text(m.name))),
                ],
                onChanged: (v) => setState(() => _selectedShiftModalId = v),
              ),
            if (widget.shiftModals.isNotEmpty) const SizedBox(height: 8),
            if (widget.leaveModals.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _selectedLeaveModalId,
                decoration: const InputDecoration(
                  labelText: 'Leave Modal',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('— None')),
                  ...widget.leaveModals.map((m) =>
                      DropdownMenuItem(value: m.id, child: Text(m.name))),
                ],
                onChanged: (v) => setState(() => _selectedLeaveModalId = v),
              ),
            if (widget.leaveModals.isNotEmpty) const SizedBox(height: 8),
            if (widget.holidayModals.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _selectedHolidayModalId,
                decoration: const InputDecoration(
                  labelText: 'Holiday Modal',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('— None')),
                  ...widget.holidayModals.map((m) =>
                      DropdownMenuItem(value: m.id, child: Text(m.name))),
                ],
                onChanged: (v) => setState(() => _selectedHolidayModalId = v),
              ),
            if (widget.holidayModals.isNotEmpty) const SizedBox(height: 8),
            if (widget.branches.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _selectedBranchId,
                decoration: const InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('—')),
                  ...widget.branches.map((b) =>
                      DropdownMenuItem(value: b.id, child: Text(b.branchName))),
                ],
                onChanged: (v) => setState(() => _selectedBranchId = v),
              ),
            if (widget.branches.isNotEmpty) const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _loginMethod,
              decoration: const InputDecoration(
                labelText: 'Login Method',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'password', child: Text('Password')),
                DropdownMenuItem(value: 'otp', child: Text('OTP')),
              ],
              onChanged: (v) => setState(() => _loginMethod = v ?? 'password'),
            ),
            if (_loginMethod == 'password') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _tempPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: (_saving ||
                          !licenseActive ||
                          (widget.attendanceModals.isNotEmpty &&
                              _selectedAttendanceModalId == null))
                      ? null
                      : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Staff'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EditStaffDialog extends StatefulWidget {
  final Staff staff;
  final List<Branch> branches;
  final List<Department> departments;
  final RolesRepository rolesRepo;
  final VoidCallback onClose;
  final Future<void> Function(
    int staffId, {
    String? fullName,
    String? phone,
    String? department,
    String? designation,
    String? status,
    int? roleId,
    int? branchId,
  }) onSave;

  const _EditStaffDialog({
    required this.staff,
    required this.branches,
    required this.departments,
    required this.rolesRepo,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _department;
  late TextEditingController _designation;
  List<Role> _roles = [];
  bool _loading = true;
  bool _saving = false;
  int? _selectedRoleId;
  int? _selectedBranchId;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff.name);
    _phone = TextEditingController(text: widget.staff.phone);
    _department = TextEditingController(text: widget.staff.department);
    _designation = TextEditingController(text: widget.staff.designation);
    _selectedRoleId = widget.staff.roleId;
    _selectedBranchId = widget.staff.branchId;
    _status = widget.staff.status;
    _loadRoles();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _department.dispose();
    _designation.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await widget.rolesRepo.fetchRoles();
      if (mounted)
        setState(() {
          _roles = roles;
          _loading = false;
          if (_selectedRoleId == null && roles.isNotEmpty)
            _selectedRoleId = roles.first.id;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        widget.staff.id,
        fullName: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        department:
            _department.text.trim().isEmpty ? null : _department.text.trim(),
        designation:
            _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        status: _status,
        roleId: _selectedRoleId,
        branchId: _selectedBranchId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Staff updated')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Edit Staff',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const Spacer(),
              IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded)),
            ],
          ),
          if (_loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else ...[
            const SizedBox(height: 12),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: _phone,
                decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: _department,
                decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: _designation,
                decoration: const InputDecoration(
                    labelText: 'Designation',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedRoleId,
              decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: _roles
                  .map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoleId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _selectedBranchId,
              decoration: const InputDecoration(
                  labelText: 'Branch',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                ...widget.branches.map((b) =>
                    DropdownMenuItem(value: b.id, child: Text(b.branchName))),
              ],
              onChanged: (v) => setState(() => _selectedBranchId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive'))
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save')),
                const SizedBox(width: 12),
                TextButton(
                    onPressed: widget.onClose, child: const Text('Cancel')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
