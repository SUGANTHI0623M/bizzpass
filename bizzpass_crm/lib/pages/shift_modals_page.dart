import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/shift_modals_repository.dart';

/// Full page to manage shift modals. Uses "modal" terminology (not "template").
class ShiftModalsPage extends StatefulWidget {
  final VoidCallback onBack;

  const ShiftModalsPage({super.key, required this.onBack});

  @override
  State<ShiftModalsPage> createState() => _ShiftModalsPageState();
}

class _ShiftModalsPageState extends State<ShiftModalsPage> {
  final ShiftModalsRepository _repo = ShiftModalsRepository();
  final _nameController = TextEditingController();
  final _graceController = TextEditingController(text: '10');

  List<ShiftModal> _modals = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _graceUnit = 'Minutes';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _graceController.dispose();
    super.dispose();
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

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null && mounted) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null && mounted) setState(() => _endTime = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _clearForm() {
    _nameController.clear();
    _graceController.text = '10';
    setState(() {
      _startTime = null;
      _endTime = null;
      _graceUnit = 'Minutes';
    });
  }

  Future<void> _submitAdd() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift name is required')),
      );
      return;
    }
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start time')),
      );
      return;
    }
    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end time')),
      );
      return;
    }
    final grace = int.tryParse(_graceController.text.trim()) ?? 10;
    if (grace < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grace time must be 0 or more')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.createModal(
        name: name,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        graceMinutes: grace,
        graceUnit: _graceUnit,
      );
      if (mounted) {
        _clearForm();
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift modal added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showEditDialog(ShiftModal modal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _EditShiftModalDialog(
        modal: modal,
        onClose: () => Navigator.of(ctx).pop(),
        onSaved: () {
          Navigator.of(ctx).pop();
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shift modal updated')),
            );
          }
        },
        repo: _repo,
      ),
    );
  }

  Future<void> _confirmDelete(ShiftModal modal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift Modal'),
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
            style: TextButton.styleFrom(foregroundColor: context.dangerColor),
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
          const SnackBar(content: Text('Shift modal deleted')),
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
                  title: 'Shift Modals',
                  subtitle: 'Manage employee shift timings and assigned staff',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAddForm(),
          const SizedBox(height: 24),
          _buildShiftsList(),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth > 700;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Shift',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (useRow) _buildAddFormFieldsRow() else _buildAddFormFieldsColumn(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : _clearForm,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submitAdd,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add Shift'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddFormFieldsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Shift Name',
              hintText: 'General',
              isDense: true,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(100),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TimePickerField(
            label: 'Start Time',
            value: _startTime,
            onTap: _pickStartTime,
            formatTime: _formatTime,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TimePickerField(
            label: 'End Time',
            value: _endTime,
            onTap: _pickEndTime,
            formatTime: _formatTime,
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 100,
          child: TextField(
            controller: _graceController,
            decoration: const InputDecoration(
              labelText: 'Grace Time',
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            value: _graceUnit,
            decoration: const InputDecoration(
              labelText: 'Unit',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'Minutes', child: Text('Minutes')),
              DropdownMenuItem(value: 'Hours', child: Text('Hours')),
            ],
            onChanged: (v) => setState(() => _graceUnit = v ?? 'Minutes'),
          ),
        ),
      ],
    );
  }

  Widget _buildAddFormFieldsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Shift Name',
            hintText: 'General',
            isDense: true,
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(100),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimePickerField(
                label: 'Start Time',
                value: _startTime,
                onTap: _pickStartTime,
                formatTime: _formatTime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimePickerField(
                label: 'End Time',
                value: _endTime,
                onTap: _pickEndTime,
                formatTime: _formatTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _graceController,
                decoration: const InputDecoration(
                  labelText: 'Grace Time',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _graceUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Minutes', child: Text('Minutes')),
                  DropdownMenuItem(value: 'Hours', child: Text('Hours')),
                ],
                onChanged: (v) => setState(() => _graceUnit = v ?? 'Minutes'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShiftsList() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: context.accentColor),
        ),
      );
    }
    if (_error != null) {
      return Container(
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
      );
    }
    if (_modals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.schedule_rounded, size: 48, color: context.textMutedColor),
              const SizedBox(height: 12),
              Text(
                'No shift modals yet',
                style: TextStyle(
                  fontSize: 15,
                  color: context.textMutedColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the form above to add your first shift',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textDimColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Shifts',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textMutedColor,
          ),
        ),
        const SizedBox(height: 12),
        ..._modals.map(
          (m) => _ShiftModalCard(
            modal: m,
            onEdit: () => _showEditDialog(m),
            onDelete: () => _confirmDelete(m),
          ),
        ),
      ],
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  final String Function(TimeOfDay) formatTime;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule_rounded, size: 20),
          isDense: true,
        ),
        child: Text(
          value != null ? formatTime(value!) : '--:--',
          style: TextStyle(
            color: value != null ? context.textColor : context.textDimColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ShiftModalCard extends StatelessWidget {
  final ShiftModal modal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ShiftModalCard({
    required this.modal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final graceLabel = modal.graceUnit == 'Hours'
        ? '${modal.graceMinutes} ${modal.graceUnit}'
        : '${modal.graceMinutes} ${modal.graceUnit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(Icons.schedule_rounded, size: 20, color: context.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modal.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time: ${modal.startTime} - ${modal.endTime}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textMutedColor,
                  ),
                ),
                Text(
                  'Grace Time: $graceLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textMutedColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_rounded, size: 20, color: context.dangerColor),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

class _EditShiftModalDialog extends StatefulWidget {
  final ShiftModal modal;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final ShiftModalsRepository repo;

  const _EditShiftModalDialog({
    required this.modal,
    required this.onClose,
    required this.onSaved,
    required this.repo,
  });

  @override
  State<_EditShiftModalDialog> createState() => _EditShiftModalDialogState();
}

class _EditShiftModalDialogState extends State<_EditShiftModalDialog> {
  late TextEditingController _nameController;
  late TextEditingController _graceController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _graceUnit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.modal.name);
    _graceController = TextEditingController(text: '${widget.modal.graceMinutes}');
    _graceUnit = widget.modal.graceUnit;
    _startTime = _parseTime(widget.modal.startTime);
    _endTime = _parseTime(widget.modal.endTime);
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift name is required')),
      );
      return;
    }
    final grace = int.tryParse(_graceController.text.trim()) ?? 10;
    if (grace < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grace time must be 0 or more')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repo.updateModal(
        widget.modal.id,
        name: name,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        graceMinutes: grace,
        graceUnit: _graceUnit,
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Shift Modal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update shift timing and grace period',
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
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Shift Name',
                  hintText: 'e.g., General 1',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final p = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (p != null) setState(() => _startTime = p);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          suffixIcon: Icon(Icons.schedule_rounded, size: 20),
                          isDense: true,
                        ),
                        child: Text(_formatTime(_startTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final p = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (p != null) setState(() => _endTime = p);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          suffixIcon: Icon(Icons.schedule_rounded, size: 20),
                          isDense: true,
                        ),
                        child: Text(_formatTime(_endTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _graceController,
                      decoration: const InputDecoration(
                        labelText: 'Grace Time',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _graceUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Minutes', child: Text('Minutes')),
                        DropdownMenuItem(value: 'Hours', child: Text('Hours')),
                      ],
                      onChanged: (v) => setState(() => _graceUnit = v ?? 'Minutes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : widget.onClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
