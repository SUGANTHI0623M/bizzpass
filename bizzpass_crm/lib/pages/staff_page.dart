import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../data/holiday_modals_repository.dart';
import 'staff_details_page.dart';
import 'create_staff_page.dart';

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

  /// When set, Add Staff navigates to create-staff page (sidebar kept). Otherwise opens full-screen.
  final VoidCallback? onAddStaff;
  /// When set, Edit opens edit-staff page (sidebar kept). Otherwise opens edit dialog.
  final void Function(Staff)? onEditStaff;
  /// When set, View opens staff-detail page (sidebar kept). Otherwise pushes full-screen.
  final void Function(Staff)? onViewStaff;

  const StaffPage({
    super.key,
    this.enableCreate = false,
    this.branchId,
    this.branchName,
    this.onAddStaff,
    this.onEditStaff,
    this.onViewStaff,
  });
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
  final HolidayModalsRepository _holidayModalsRepo = HolidayModalsRepository();
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
  Staff? _editingStaff;
  String? _filterDepartment;
  String? _filterJoiningFrom;
  String? _filterJoiningTo;
  int? _filterBranchId;
  final _joiningFromController = TextEditingController();
  final _joiningToController = TextEditingController();
  Timer? _debounce;

  int? get _effectiveBranchId => widget.branchId ?? _filterBranchId;

  @override
  void dispose() {
    _debounce?.cancel();
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
      final departments = await _departmentsRepo.fetchDepartments(activeOnly: true);
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
      final holiday = await _holidayModalsRepo.fetchModals();
      if (mounted) {
        setState(() {
          _attendanceModals = att.map((m) => StaffModalOption(m.id, m.name)).toList();
          _shiftModals = shift.map((m) => StaffModalOption(m.id, m.name)).toList();
          _leaveModals = leave.map((m) => StaffModalOption(m.id, m.name)).toList();
          _holidayModals = holiday.map((m) => StaffModalOption(m.id, m.name)).toList();
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

  static String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.accentColor,
              onPrimary: Colors.white,
              surface: context.cardColor,
              onSurface: context.textColor,
            ),
            dialogBackgroundColor: context.cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _openCreateStaff() {
    if (widget.onAddStaff != null) {
      widget.onAddStaff!();
      return;
    }
    Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => CreateStaffPage(
          staffRepo: _repo,
          rolesRepo: _rolesRepo,
          onBack: () => Navigator.of(ctx).pop(true),
          branches: _branches,
          departments: _departments,
          initialBranchId: _effectiveBranchId,
          attendanceModals: _attendanceModals,
          shiftModals: _shiftModals,
          leaveModals: _leaveModals,
          holidayModals: _holidayModals,
        ),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _load();
      }
    });
  }

  /// Wraps cell content so the entire cell is clickable (like branches). Full row tap opens staff details.
  Widget _staffCellTap(Staff s, Widget child, {AlignmentGeometry alignment = Alignment.centerLeft}) {
    if (!widget.enableCreate) return child;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: InkWell(
        onTap: () => _openStaffDetails(s),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Align(
          alignment: alignment,
          child: child,
        ),
      ),
    );
  }

  void _openStaffDetails(Staff s) {
    if (widget.onViewStaff != null) {
      widget.onViewStaff!(s);
      return;
    }
    Navigator.of(context).push<Staff?>(
      MaterialPageRoute<Staff?>(
        builder: (ctx) => Scaffold(
          backgroundColor: context.bgColor,
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
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
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
          if (_editingStaff != null && widget.onEditStaff == null)
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
                color: context.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
            if (_error!.toLowerCase().contains('cannot reach the backend'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  ApiConstants.backendUnreachableHint,
                  style: TextStyle(
                    color: context.textMutedColor,
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
              onChanged: (v) {
                setState(() => _search = v);
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (mounted) _load();
                });
              }),
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
                  width: 160,
                  child: TextField(
                    controller: _joiningFromController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _joiningFromController),
                    decoration: const InputDecoration(
                      labelText: 'Joining from',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _joiningToController,
                    readOnly: true,
                    onTap: () => _selectDate(context, _joiningToController),
                    decoration: const InputDecoration(
                      labelText: 'Joining to',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
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
                const DataCol('Created at'),
              ],
              rows: filtered
                  .map((s) => DataRow(
                        onSelectChanged: widget.enableCreate
                            ? (_) => _openStaffDetails(s)
                            : null,
                        cells: [
                          DataCell(
                            _staffCellTap(
                              s,
                              Row(children: [
                                AvatarCircle(
                                    name: s.name, seed: s.id, round: true),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: context.textColor)),
                                    Text(s.employeeId,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: context.textDimColor)),
                                  ],
                                ),
                              ]),
                            ),
                          ),
                          if (!widget.enableCreate)
                            DataCell(_staffCellTap(s, Text(s.company))),
                          DataCell(_staffCellTap(s, Text(s.designation))),
                          DataCell(_staffCellTap(s, Text(s.department))),
                          if (widget.enableCreate) ...[
                            DataCell(_staffCellTap(s, Text(s.roleName ?? '—'))),
                            DataCell(_staffCellTap(s, Text(s.branchName ?? '—'))),
                          ],
                          DataCell(_staffCellTap(s, StatusBadge(status: s.status))),
                          DataCell(_staffCellTap(s, Text(s.joiningDate))),
                          DataCell(_staffCellTap(s, Text(s.createdAt != null && s.createdAt!.isNotEmpty ? _formatCreatedAt(s.createdAt!) : '—'))),
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
    String? staffType,
    String? reportingManager,
    String? salaryCycle,
    double? grossSalary,
    double? netSalary,
    String? gender,
    String? dob,
    String? maritalStatus,
    String? bloodGroup,
    String? addressLine1,
    String? addressCity,
    String? addressState,
    String? addressPostalCode,
    String? addressCountry,
    String? uan,
    String? panNumber,
    String? aadhaarNumber,
    String? pfNumber,
    String? esiNumber,
    String? bankName,
    String? ifscCode,
    String? accountNumber,
    String? accountHolderName,
    String? upiId,
    String? bankVerificationStatus,
  }) onSubmit;
  final StaffRepository staffRepo;
  final RolesRepository rolesRepo;
  final List<Branch> branches;
  final List<Department> departments;
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
    this.departments = const [],
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
  final _designation = TextEditingController();
  final _joiningDate = TextEditingController();
  final _tempPassword = TextEditingController();
  final _reportingManager = TextEditingController();
  final _grossSalary = TextEditingController();
  final _netSalary = TextEditingController();
  final _dob = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressCity = TextEditingController();
  final _addressState = TextEditingController();
  final _addressPostalCode = TextEditingController();
  final _addressCountry = TextEditingController();
  final _uan = TextEditingController();
  final _panNumber = TextEditingController();
  final _aadhaarNumber = TextEditingController();
  final _pfNumber = TextEditingController();
  final _esiNumber = TextEditingController();
  final _bankName = TextEditingController();
  final _ifscCode = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountHolderName = TextEditingController();
  final _upiId = TextEditingController();
  String _loginMethod = 'password';
  String _status = 'active';
  String? _selectedDepartmentName;
  String? _staffType;
  String? _salaryCycle;
  String? _gender;
  String? _maritalStatus;
  String? _bloodGroup;
  String _bankVerificationStatus = 'Pending';
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
  static const List<String> _staffTypes = ['Full Time', 'Part Time', 'Contract'];
  static const List<String> _salaryCycles = ['Monthly', 'Weekly'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const List<String> _bankVerificationStatuses = ['Pending', 'Verified', 'Failed'];

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
    _designation.dispose();
    _joiningDate.dispose();
    _tempPassword.dispose();
    _reportingManager.dispose();
    _grossSalary.dispose();
    _netSalary.dispose();
    _dob.dispose();
    _addressLine1.dispose();
    _addressCity.dispose();
    _addressState.dispose();
    _addressPostalCode.dispose();
    _addressCountry.dispose();
    _uan.dispose();
    _panNumber.dispose();
    _aadhaarNumber.dispose();
    _pfNumber.dispose();
    _esiNumber.dispose();
    _bankName.dispose();
    _ifscCode.dispose();
    _accountNumber.dispose();
    _accountHolderName.dispose();
    _upiId.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.textColor,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.accentColor,
              onPrimary: Colors.white,
              surface: context.cardColor,
              onSurface: context.textColor,
            ),
            dialogBackgroundColor: context.cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
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
    double? gross;
    double? net;
    try {
      if (_grossSalary.text.trim().isNotEmpty) gross = double.tryParse(_grossSalary.text.trim());
      if (_netSalary.text.trim().isNotEmpty) net = double.tryParse(_netSalary.text.trim());
    } catch (_) {}
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        fullName: name,
        email: email,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        employeeId: _employeeId.text.trim().isEmpty ? null : _employeeId.text.trim(),
        department: _selectedDepartmentName,
        designation: _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        joiningDate: _joiningDate.text.trim().isEmpty ? null : _joiningDate.text.trim(),
        loginMethod: _loginMethod,
        temporaryPassword: _tempPassword.text.trim().isEmpty ? null : _tempPassword.text.trim(),
        roleId: _selectedRoleId!,
        status: _status,
        branchId: _selectedBranchId,
        attendanceModalId: _selectedAttendanceModalId,
        shiftModalId: _selectedShiftModalId,
        leaveModalId: _selectedLeaveModalId,
        holidayModalId: _selectedHolidayModalId,
        staffType: _staffType,
        reportingManager: _reportingManager.text.trim().isEmpty ? null : _reportingManager.text.trim(),
        salaryCycle: _salaryCycle,
        grossSalary: gross,
        netSalary: net,
        gender: _gender,
        dob: _dob.text.trim().isEmpty ? null : _dob.text.trim(),
        maritalStatus: _maritalStatus,
        bloodGroup: _bloodGroup,
        addressLine1: _addressLine1.text.trim().isEmpty ? null : _addressLine1.text.trim(),
        addressCity: _addressCity.text.trim().isEmpty ? null : _addressCity.text.trim(),
        addressState: _addressState.text.trim().isEmpty ? null : _addressState.text.trim(),
        addressPostalCode: _addressPostalCode.text.trim().isEmpty ? null : _addressPostalCode.text.trim(),
        addressCountry: _addressCountry.text.trim().isEmpty ? null : _addressCountry.text.trim(),
        uan: _uan.text.trim().isEmpty ? null : _uan.text.trim(),
        panNumber: _panNumber.text.trim().isEmpty ? null : _panNumber.text.trim(),
        aadhaarNumber: _aadhaarNumber.text.trim().isEmpty ? null : _aadhaarNumber.text.trim(),
        pfNumber: _pfNumber.text.trim().isEmpty ? null : _pfNumber.text.trim(),
        esiNumber: _esiNumber.text.trim().isEmpty ? null : _esiNumber.text.trim(),
        bankName: _bankName.text.trim().isEmpty ? null : _bankName.text.trim(),
        ifscCode: _ifscCode.text.trim().isEmpty ? null : _ifscCode.text.trim(),
        accountNumber: _accountNumber.text.trim().isEmpty ? null : _accountNumber.text.trim(),
        accountHolderName: _accountHolderName.text.trim().isEmpty ? null : _accountHolderName.text.trim(),
        upiId: _upiId.text.trim().isEmpty ? null : _upiId.text.trim(),
        bankVerificationStatus: _bankVerificationStatus,
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
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
                style: TextStyle(color: context.dangerColor, fontSize: 13),
              ),
            ),
          if (maxUsers != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Staff: $currentUsers / $maxUsers',
                style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!,
                  style: TextStyle(color: context.dangerColor, fontSize: 13)),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Profile Information'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Name *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _employeeId,
                            decoration: const InputDecoration(
                              labelText: 'Employee ID (auto if empty)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _designation,
                            decoration: const InputDecoration(
                              labelText: 'Designation',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _staffType,
                            decoration: const InputDecoration(
                              labelText: 'Staff Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('—')),
                              ..._staffTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                            ],
                            onChanged: (v) => setState(() => _staffType = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Number',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: widget.departments.isEmpty
                              ? TextField(
                                  onChanged: (_) {},
                                  decoration: const InputDecoration(
                                    labelText: 'Department (add in Settings)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                )
                              : DropdownButtonFormField<String?>(
                                  value: _selectedDepartmentName,
                                  decoration: const InputDecoration(
                                    labelText: 'Department',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(value: null, child: Text('—')),
                                    ...widget.departments.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))),
                                  ],
                                  onChanged: (v) => setState(() => _selectedDepartmentName = v),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reportingManager,
                            decoration: const InputDecoration(
                              labelText: 'Reporting Manager',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedRoleId,
                            decoration: const InputDecoration(
                              labelText: 'Role *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                            onChanged: (v) => setState(() => _selectedRoleId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('General Information'),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _salaryCycle,
                            decoration: const InputDecoration(labelText: 'Salary Cycle', border: OutlineInputBorder(), isDense: true),
                            items: [const DropdownMenuItem<String?>(value: null, child: Text('—')), ..._salaryCycles.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
                            onChanged: (v) => setState(() => _salaryCycle = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _grossSalary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gross Salary', border: OutlineInputBorder(), isDense: true))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _netSalary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Net Salary', border: OutlineInputBorder(), isDense: true))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.shiftModals.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: _selectedShiftModalId,
                        decoration: const InputDecoration(labelText: 'Shift', border: OutlineInputBorder(), isDense: true),
                        items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ...widget.shiftModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
                        onChanged: (v) => setState(() => _selectedShiftModalId = v),
                      ),
                    if (widget.shiftModals.isNotEmpty) const SizedBox(height: 8),
                    if (widget.attendanceModals.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: _selectedAttendanceModalId,
                        decoration: const InputDecoration(labelText: 'Attendance Template *', border: OutlineInputBorder(), isDense: true),
                        items: widget.attendanceModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                        onChanged: (v) => setState(() => _selectedAttendanceModalId = v),
                      ),
                    if (widget.attendanceModals.isNotEmpty) const SizedBox(height: 8),
                    if (widget.leaveModals.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: _selectedLeaveModalId,
                        decoration: const InputDecoration(labelText: 'Leave Template', border: OutlineInputBorder(), isDense: true),
                        items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ...widget.leaveModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
                        onChanged: (v) => setState(() => _selectedLeaveModalId = v),
                      ),
                    if (widget.leaveModals.isNotEmpty) const SizedBox(height: 8),
                    if (widget.holidayModals.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: _selectedHolidayModalId,
                        decoration: const InputDecoration(labelText: 'Holiday Template', border: OutlineInputBorder(), isDense: true),
                        items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ...widget.holidayModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
                        onChanged: (v) => setState(() => _selectedHolidayModalId = v),
                      ),
                    if (widget.holidayModals.isNotEmpty) const SizedBox(height: 8),
                    if (widget.branches.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: _selectedBranchId,
                        decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder(), isDense: true),
                        items: [const DropdownMenuItem<int?>(value: null, child: Text('—')), ...widget.branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.branchName)))],
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
                    const SizedBox(height: 16),
                    _sectionTitle('Personal Information'),
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder(), isDense: true)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: DropdownButtonFormField<String?>(value: _gender, decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<String?>(value: null, child: Text('—')), ..._genders.map((g) => DropdownMenuItem(value: g, child: Text(g)))], onChanged: (v) => setState(() => _gender = v))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dob,
                            readOnly: true,
                            onTap: () => _selectDate(context, _dob),
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String?>(value: _maritalStatus, decoration: const InputDecoration(labelText: 'Marital Status', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<String?>(value: null, child: Text('—')), ..._maritalStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s)))], onChanged: (v) => setState(() => _maritalStatus = v))),
                        const SizedBox(width: 12),
                        Expanded(child: DropdownButtonFormField<String?>(value: _bloodGroup, decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<String?>(value: null, child: Text('—')), ..._bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b)))], onChanged: (v) => setState(() => _bloodGroup = v))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _joiningDate,
                      readOnly: true,
                      onTap: () => _selectDate(context, _joiningDate),
                      decoration: const InputDecoration(
                        labelText: 'Joining Date',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Current Address'),
                    Row(children: [Expanded(child: TextField(controller: _addressLine1, decoration: const InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressCity, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _addressState, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressPostalCode, decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressCountry, decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 16),
                    _sectionTitle('Employment Information'),
                    Row(children: [Expanded(child: TextField(controller: _uan, decoration: const InputDecoration(labelText: 'UAN', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _panNumber, decoration: const InputDecoration(labelText: 'PAN Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _aadhaarNumber, decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _pfNumber, decoration: const InputDecoration(labelText: 'PF Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _esiNumber, decoration: const InputDecoration(labelText: 'ESI Number', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 16),
                    _sectionTitle('Bank Details'),
                    Row(children: [Expanded(child: TextField(controller: _bankName, decoration: const InputDecoration(labelText: 'Name of Bank', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _ifscCode, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _accountNumber, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _accountHolderName, decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _upiId, decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: DropdownButtonFormField<String>(value: _bankVerificationStatus, decoration: const InputDecoration(labelText: 'Verification Status', border: OutlineInputBorder(), isDense: true), items: _bankVerificationStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _bankVerificationStatus = v ?? 'Pending')))]),
                    const SizedBox(height: 16),
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
                ),
              ),
            ),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
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
