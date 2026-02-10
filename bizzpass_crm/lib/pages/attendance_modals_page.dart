import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/attendance_modals_repository.dart';

/// Full page to manage attendance modals. Uses "modal" terminology.
class AttendanceModalsPage extends StatefulWidget {
  final VoidCallback onBack;

  const AttendanceModalsPage({super.key, required this.onBack});

  @override
  State<AttendanceModalsPage> createState() => _AttendanceModalsPageState();
}

class _AttendanceModalsPageState extends State<AttendanceModalsPage> {
  final AttendanceModalsRepository _repo = AttendanceModalsRepository();
  final _searchController = TextEditingController();
  List<AttendanceModal> _modals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttendanceModal> get _filteredModals {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _modals;
    return _modals.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchModals();
      if (mounted) {
        setState(() {
          _modals = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isConnectionError = msg.contains('connection') ||
            msg.contains('Connection') ||
            msg.contains('DioException') ||
            msg.contains('SocketException') ||
            msg.contains('NetworkException');
        setState(() {
          _loading = false;
          _error = isConnectionError
              ? 'Cannot reach the backend at ${ApiConstants.baseUrl}. ${ApiConstants.backendUnreachableHint}'
              : msg;
        });
      }
    }
  }

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AttendanceModalDialog(
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (modal) async {
          try {
            await _repo.createModal(
              name: modal.name,
              description: modal.description.isNotEmpty ? modal.description : null,
              isActive: modal.isActive,
              requireGeolocation: modal.requireGeolocation,
              requireSelfie: modal.requireSelfie,
              allowAttendanceOnHolidays: modal.allowOnHolidays,
              allowAttendanceOnWeeklyOff: modal.allowOnWeeklyOff,
              allowLateEntry: modal.allowLateEntry,
              allowEarlyExit: modal.allowEarlyExit,
              allowOvertime: modal.allowOvertime,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance modal created')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(AttendanceModal modal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AttendanceModalDialog(
        existing: modal,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data) async {
          try {
            await _repo.updateModal(
              modal.id,
              name: data.name,
              description: data.description.isNotEmpty ? data.description : null,
              isActive: data.isActive,
              requireGeolocation: data.requireGeolocation,
              requireSelfie: data.requireSelfie,
              allowAttendanceOnHolidays: data.allowOnHolidays,
              allowAttendanceOnWeeklyOff: data.allowOnWeeklyOff,
              allowLateEntry: data.allowLateEntry,
              allowEarlyExit: data.allowEarlyExit,
              allowOvertime: data.allowOvertime,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance modal updated')),
              );
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(AttendanceModal modal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attendance Modal'),
        content: Text(
          'Are you sure you want to delete "${modal.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ctx.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.deleteModal(modal.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance modal deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

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
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SectionHeader(
                  title: 'Attendance Modals',
                  subtitle: 'Manage attendance modals for your company',
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add modal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name or description...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: context.accentColor),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.dangerColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.dangerColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: context.textColor),
                    ),
                  ),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_filteredModals.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.tune_rounded, size: 48, color: context.textMutedColor),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.trim().isEmpty
                          ? 'No attendance modals yet. Add one to get started.'
                          : 'No results for "${_searchController.text.trim()}".',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textMutedColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add modal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Name'),
                DataCol('Description'),
                DataCol('Status'),
                DataCol('Actions'),
              ],
              rows: _filteredModals.map((m) => DataRow(
                cells: [
                  DataCell(Text(m.name)),
                  DataCell(Text(
                    m.description.isEmpty ? '—' : m.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: m.isActive
                          ? context.successColor.withOpacity(0.15)
                          : context.textMutedColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: m.isActive ? context.successColor : context.textMutedColor,
                      ),
                    ),
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditDialog(m),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(m),
                        icon: Icon(Icons.delete_outline_rounded, color: context.dangerColor),
                        tooltip: 'Delete',
                      ),
                    ],
                  )),
                ],
              )).toList(),
            ),
        ],
      ),
    );
  }
}

class _AttendanceModalDialog extends StatefulWidget {
  final AttendanceModal? existing;
  final VoidCallback onClose;
  final void Function(_ModalFormData) onSave;

  const _AttendanceModalDialog({
    this.existing,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_AttendanceModalDialog> createState() => _AttendanceModalDialogState();
}

class _ModalFormData {
  String name;
  String description;
  bool isActive;
  bool requireGeolocation;
  bool requireSelfie;
  bool allowOnHolidays;
  bool allowOnWeeklyOff;
  bool allowLateEntry;
  bool allowEarlyExit;
  bool allowOvertime;

  _ModalFormData({
    required this.name,
    required this.description,
    required this.isActive,
    required this.requireGeolocation,
    required this.requireSelfie,
    required this.allowOnHolidays,
    required this.allowOnWeeklyOff,
    required this.allowLateEntry,
    required this.allowEarlyExit,
    required this.allowOvertime,
  });
}

class _AttendanceModalDialogState extends State<_AttendanceModalDialog> {
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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _desc.text = e.description;
      _active = e.isActive;
      _requireGeolocation = e.requireGeolocation;
      _requireSelfie = e.requireSelfie;
      _allowOnHolidays = e.allowAttendanceOnHolidays;
      _allowOnWeeklyOff = e.allowAttendanceOnWeeklyOff;
      _allowLateEntry = e.allowLateEntry;
      _allowEarlyExit = e.allowEarlyExit;
      _allowOvertime = e.allowOvertime;
    }
  }

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
    setState(() => _saving = true);
    widget.onSave(_ModalFormData(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      isActive: _active,
      requireGeolocation: _requireGeolocation,
      requireSelfie: _requireSelfie,
      allowOnHolidays: _allowOnHolidays,
      allowOnWeeklyOff: _allowOnWeeklyOff,
      allowLateEntry: _allowLateEntry,
      allowEarlyExit: _allowEarlyExit,
      allowOvertime: _allowOvertime,
    ));
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: context.cardColor,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Attendance Modal' : 'Create Attendance Modal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure attendance modal settings and requirements',
                          style: TextStyle(fontSize: 12, color: context.textMutedColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : widget.onClose,
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
                        hintText: 'e.g. Standard Attendance, Selfie & Location',
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
                    _SwitchRow(
                      label: 'Active Status',
                      subtitle: 'Only active modals can be assigned to staff',
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Attendance Requirements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      label: 'Require Geolocation',
                      subtitle: 'Employees must provide location when marking attendance',
                      value: _requireGeolocation,
                      onChanged: (v) => setState(() => _requireGeolocation = v),
                    ),
                    _SwitchRow(
                      label: 'Require Selfie',
                      subtitle: 'Employees must take a selfie when marking attendance',
                      value: _requireSelfie,
                      onChanged: (v) => setState(() => _requireSelfie = v),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Attendance Rules',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      label: 'Allow Attendance on Holidays',
                      subtitle: 'Allow employees to mark attendance on holiday days',
                      value: _allowOnHolidays,
                      onChanged: (v) => setState(() => _allowOnHolidays = v),
                    ),
                    _SwitchRow(
                      label: 'Allow Attendance on Weekly Off',
                      subtitle: 'Allow employees to mark attendance on weekly off days',
                      value: _allowOnWeeklyOff,
                      onChanged: (v) => setState(() => _allowOnWeeklyOff = v),
                    ),
                    _SwitchRow(
                      label: 'Allow Late Entry',
                      subtitle: 'Allow employees to mark attendance after shift start time',
                      value: _allowLateEntry,
                      onChanged: (v) => setState(() => _allowLateEntry = v),
                    ),
                    _SwitchRow(
                      label: 'Allow Early Exit',
                      subtitle: 'Allow employees to mark exit before shift end time',
                      value: _allowEarlyExit,
                      onChanged: (v) => setState(() => _allowEarlyExit = v),
                    ),
                    _SwitchRow(
                      label: 'Allow Overtime',
                      subtitle: 'Allow employees to work beyond shift end time',
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
                    onPressed: _saving ? null : widget.onClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(isEdit ? 'Update Modal' : 'Create Modal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentColor,
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

class _SwitchRow extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: context.textMutedColor),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.accentColor,
          ),
        ],
      ),
    );
  }
}
