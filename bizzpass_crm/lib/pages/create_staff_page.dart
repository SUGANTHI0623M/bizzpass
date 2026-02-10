import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../data/staff_repository.dart';
import '../data/roles_repository.dart' show Role, RolesRepository;
import '../data/branches_repository.dart' show Branch;
import '../data/departments_repository.dart' show Department;
import 'staff_page.dart' show StaffModalOption;

class CreateStaffPage extends StatefulWidget {
  final StaffRepository staffRepo;
  final RolesRepository rolesRepo;
  final List<Branch> branches;
  final List<Department> departments;
  final int? initialBranchId;
  final List<StaffModalOption> attendanceModals;
  final List<StaffModalOption> shiftModals;
  final List<StaffModalOption> leaveModals;
  final List<StaffModalOption> holidayModals;

  const CreateStaffPage({
    super.key,
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
  State<CreateStaffPage> createState() => _CreateStaffPageState();
}

class _CreateStaffPageState extends State<CreateStaffPage> {
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
      padding: const EdgeInsets.only(top: 16, bottom: 8),
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
      await widget.staffRepo.createStaff(
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
          const SnackBar(content: Text('Staff created successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
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

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add New Staff',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textColor,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: (_loading ||
                        !licenseActive ||
                        (widget.attendanceModals.isNotEmpty &&
                            _selectedAttendanceModalId == null))
                    ? null
                    : _submit,
                icon: Icon(Icons.check_rounded, size: 18),
                label: const Text('Create Staff'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!licenseActive)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.dangerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: context.dangerColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'License is not active. Cannot add staff.',
                                style: TextStyle(
                                    color: context.dangerColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (maxUsers != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_outline_rounded,
                                color: context.textSecondaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Staff Count: $currentUsers / $maxUsers',
                              style: TextStyle(
                                  color: context.textSecondaryColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.dangerColor),
                        ),
                        child: Text(_error!,
                            style: TextStyle(
                                color: context.dangerColor, fontSize: 13)),
                      ),
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
                                    ...widget.departments.where((d) => d.name != null).map((d) => DropdownMenuItem(value: d.name!, child: Text(d.name!))),
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
                        items: [const DropdownMenuItem<int?>(value: null, child: Text('—')), ...widget.branches.where((b) => b.id != null && b.branchName != null).map((b) => DropdownMenuItem(value: b.id!, child: Text(b.branchName!)))],
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
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
                    _sectionTitle('Current Address'),
                    Row(children: [Expanded(child: TextField(controller: _addressLine1, decoration: const InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressCity, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _addressState, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressPostalCode, decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _addressCountry, decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder(), isDense: true)))]),
                    _sectionTitle('Employment Information'),
                    Row(children: [Expanded(child: TextField(controller: _uan, decoration: const InputDecoration(labelText: 'UAN', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _panNumber, decoration: const InputDecoration(labelText: 'PAN Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _aadhaarNumber, decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _pfNumber, decoration: const InputDecoration(labelText: 'PF Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _esiNumber, decoration: const InputDecoration(labelText: 'ESI Number', border: OutlineInputBorder(), isDense: true)))]),
                    _sectionTitle('Bank Details'),
                    Row(children: [Expanded(child: TextField(controller: _bankName, decoration: const InputDecoration(labelText: 'Name of Bank', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _ifscCode, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _accountNumber, decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: TextField(controller: _accountHolderName, decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder(), isDense: true)))]),
                    const SizedBox(height: 8),
                    Row(children: [Expanded(child: TextField(controller: _upiId, decoration: const InputDecoration(labelText: 'UPI ID', border: OutlineInputBorder(), isDense: true))), const SizedBox(width: 12), Expanded(child: DropdownButtonFormField<String>(value: _bankVerificationStatus, decoration: const InputDecoration(labelText: 'Verification Status', border: OutlineInputBorder(), isDense: true), items: _bankVerificationStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _bankVerificationStatus = v ?? 'Pending')))]),
                    _sectionTitle('Login & Status'),
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
