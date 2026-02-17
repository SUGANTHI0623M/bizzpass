import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/departments_repository.dart';
import '../data/attendance_modals_repository.dart';
import '../data/shift_modals_repository.dart';
import '../data/leave_modals_repository.dart';
import '../data/holiday_modals_repository.dart';
import '../data/payroll_repository.dart';
import '../data/fine_modals_repository.dart';
import '../data/mock_data.dart';

class DepartmentsPage extends StatefulWidget {
  const DepartmentsPage({super.key});

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  final DepartmentsRepository _repo = DepartmentsRepository();
  List<Department> _departments = [];
  bool _loading = true;
  String? _error;
  /// When true, show Add/Edit form as a separate screen (with Back). When false, show list.
  bool _showingFormScreen = false;
  /// When on form screen: null = Add department, non-null = Edit this department.
  Department? _editingDepartment;
  String _search = '';
  bool? _filterActive; // null = all, true = active, false = inactive

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchDepartments(
        active: _filterActive,
        search: _search.trim().isEmpty ? null : _search.trim(),
      );
      if (mounted) {
        setState(() {
          _departments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('DepartmentsException: ', '');
        });
      }
    }
  }

  static String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingFormScreen) {
      return _DepartmentFormScreen(
        department: _editingDepartment,
        repo: _repo,
        onBack: () => setState(() {
          _showingFormScreen = false;
          _editingDepartment = null;
        }),
        onSaved: () {
          setState(() {
            _showingFormScreen = false;
            _editingDepartment = null;
          });
          _load();
        },
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Manage departments',
            subtitle: 'Add, edit, or set active/inactive for departments.',
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
                  Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
            if (_error!.toLowerCase().contains('cannot reach the backend'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  ApiConstants.backendUnreachableHint,
                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                ),
              ),
          ],
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _showingFormScreen = true;
                  _editingDepartment = null;
                }),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add department'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by department name...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<bool?>(
                  value: _filterActive,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem<bool?>(value: null, child: Text('All')),
                    DropdownMenuItem<bool?>(value: true, child: Text('Active')),
                    DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
                  ],
                  onChanged: (v) {
                    setState(() => _filterActive = v);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading && _departments.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else
            AppDataTable(
              columns: const [DataCol('Name'), DataCol('Status'), DataCol('Created at'), DataCol('Actions')],
              rows: _departments
                  .map((d) => DataRow(
                        cells: [
                          DataCell(Text(d.name)),
                          DataCell(Text(d.active ? 'Active' : 'Inactive')),
                          DataCell(Text(d.createdAt != null && d.createdAt!.isNotEmpty ? _formatCreatedAt(d.createdAt!) : '—')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => setState(() {
                              _showingFormScreen = true;
                              _editingDepartment = d;
                            }),
                            tooltip: 'Edit',
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

/// Full-screen Add/Edit department form with Back button in the app bar.
class _DepartmentFormScreen extends StatelessWidget {
  final Department? department;
  final DepartmentsRepository repo;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  const _DepartmentFormScreen({
    this.department,
    required this.repo,
    required this.onBack,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        foregroundColor: context.textColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
          tooltip: 'Back',
        ),
        title: Text(
          department != null ? 'Edit department' : 'Add department',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: _DepartmentFormDialog(
          department: department,
          onClose: onBack,
          onSaved: onSaved,
          repo: repo,
          showHeader: false,
        ),
      ),
    );
  }
}

class _DepartmentFormDialog extends StatefulWidget {
  final Department? department;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final DepartmentsRepository repo;
  final bool showHeader;

  const _DepartmentFormDialog({
    this.department,
    required this.onClose,
    required this.onSaved,
    required this.repo,
    this.showHeader = true,
  });

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  late bool _active;
  int? _attendanceModalId;
  int? _overtimeTemplateId;
  int? _leaveModalId;
  int? _shiftModalId;
  int? _holidayModalId;
  int? _salaryModalId;
  int? _fineModalId;
  List<AttendanceModal> _attendanceModals = [];
  List<ShiftModal> _shiftModals = [];
  List<LeaveModal> _leaveModals = [];
  List<HolidayModal> _holidayModals = [];
  List<Map<String, dynamic>> _overtimeTemplates = [];
  List<SalaryModal> _salaryModals = [];
  List<FineModal> _fineModals = [];
  bool _loadingTemplates = true;

  @override
  void initState() {
    super.initState();
    if (widget.department != null) {
      _name.text = widget.department!.name;
      _active = widget.department!.active;
      _attendanceModalId = widget.department!.attendanceModalId;
      _overtimeTemplateId = widget.department!.overtimeTemplateId;
      _leaveModalId = widget.department!.leaveModalId;
      _shiftModalId = widget.department!.shiftModalId;
      _holidayModalId = widget.department!.holidayModalId;
      _salaryModalId = widget.department!.salaryModalId;
      _fineModalId = widget.department!.fineModalId;
    } else {
      _active = true;
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final attRepo = AttendanceModalsRepository();
    final shiftRepo = ShiftModalsRepository();
    final leaveRepo = LeaveModalsRepository();
    final holidayRepo = HolidayModalsRepository();
    final payrollRepo = PayrollRepository();
    // Load each list independently so one API failure does not leave all dropdowns empty
    final fineRepo = FineModalsRepository();
    final results = await Future.wait([
      attRepo.fetchModals().catchError((_) => <AttendanceModal>[]),
      shiftRepo.fetchModals().catchError((_) => <ShiftModal>[]),
      leaveRepo.fetchModals().catchError((_) => <LeaveModal>[]),
      holidayRepo.fetchModals().catchError((_) => <HolidayModal>[]),
      payrollRepo.fetchOvertimeTemplates().catchError((_) => <Map<String, dynamic>>[]),
      payrollRepo.fetchSalaryModals(activeOnly: false).catchError((_) => <SalaryModal>[]),
      fineRepo.fetchModals().catchError((_) => <FineModal>[]),
    ]);
    if (mounted) {
      setState(() {
        _attendanceModals = results[0] as List<AttendanceModal>;
        _shiftModals = results[1] as List<ShiftModal>;
        _leaveModals = results[2] as List<LeaveModal>;
        _holidayModals = results[3] as List<HolidayModal>;
        _overtimeTemplates = results[4] as List<Map<String, dynamic>>;
        _salaryModals = results[5] as List<SalaryModal>;
        _fineModals = results[6] as List<FineModal>;
        _loadingTemplates = false;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.department != null) {
        await widget.repo.updateDepartment(
          widget.department!.id,
          name: _name.text.trim(),
          active: _active,
          attendanceModalId: _attendanceModalId,
          overtimeTemplateId: _overtimeTemplateId,
          leaveModalId: _leaveModalId,
          shiftModalId: _shiftModalId,
          holidayModalId: _holidayModalId,
          salaryModalId: _salaryModalId,
          fineModalId: _fineModalId,
          includeTemplateIds: true,
        );
      } else {
        await widget.repo.createDepartment(
          name: _name.text.trim(),
          active: _active,
          attendanceModalId: _attendanceModalId,
          overtimeTemplateId: _overtimeTemplateId,
          leaveModalId: _leaveModalId,
          shiftModalId: _shiftModalId,
          holidayModalId: _holidayModalId,
          salaryModalId: _salaryModalId,
          fineModalId: _fineModalId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.department != null ? 'Department updated' : 'Department created')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
          if (widget.showHeader) ...[
            Row(
              children: [
                Text(widget.department != null ? 'Edit department' : 'Add department',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textColor)),
                const Spacer(),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder(), isDense: true)),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _active,
            onChanged: (v) => setState(() => _active = v ?? true),
            title: const Text('Active'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 12),
          Text('Templates (optional – staff in this department can use these by default)',
              style: TextStyle(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 8),
          if (!_loadingTemplates &&
              _attendanceModals.isEmpty &&
              _overtimeTemplates.isEmpty &&
              _leaveModals.isEmpty &&
              _shiftModals.isEmpty &&
              _holidayModals.isEmpty &&
              _salaryModals.isEmpty &&
              _fineModals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Add templates in Settings (Attendance, Shift, Leave, Holiday) and Payroll (Overtime, Salary modals) to select them here.',
                style: TextStyle(fontSize: 12, color: context.textMutedColor, fontStyle: FontStyle.italic),
              ),
            ),
          if (_loadingTemplates)
            const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else ...[
            DropdownButtonFormField<int?>(
              value: _attendanceModalId,
              decoration: InputDecoration(
                labelText: 'Attendance template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _attendanceModals.isEmpty ? 'Add in Settings' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._attendanceModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _attendanceModalId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _overtimeTemplateId,
              decoration: InputDecoration(
                labelText: 'Overtime template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _overtimeTemplates.isEmpty ? 'Add in Payroll' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._overtimeTemplates.map((t) => DropdownMenuItem(value: (t['id'] as num?)?.toInt(), child: Text((t['name'] as String?) ?? '')))],
              onChanged: (v) => setState(() => _overtimeTemplateId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _leaveModalId,
              decoration: InputDecoration(
                labelText: 'Leave template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _leaveModals.isEmpty ? 'Add in Settings' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._leaveModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _leaveModalId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _shiftModalId,
              decoration: InputDecoration(
                labelText: 'Shift time template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _shiftModals.isEmpty ? 'Add in Settings' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._shiftModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _shiftModalId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _holidayModalId,
              decoration: InputDecoration(
                labelText: 'Holiday template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _holidayModals.isEmpty ? 'Add in Settings' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._holidayModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _holidayModalId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _salaryModalId,
              decoration: InputDecoration(
                labelText: 'Salary template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _salaryModals.isEmpty ? 'Add in Payroll > Salary Modals' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._salaryModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _salaryModalId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: _fineModalId,
              decoration: InputDecoration(
                labelText: 'Fine template',
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: _fineModals.isEmpty ? 'Add in Settings > Fine Modals' : null,
              ),
              items: [const DropdownMenuItem<int?>(value: null, child: Text('— None')), ..._fineModals.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))],
              onChanged: (v) => setState(() => _fineModalId = v),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(onPressed: _saving ? null : _submit, child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save')),
              const SizedBox(width: 12),
              TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }
}
