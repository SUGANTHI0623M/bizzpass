import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/shift_modals_repository.dart';

/// Full page to manage shifts: add form and list with edit/delete.
/// Copy and layout aligned with web screenshots.
class ShiftsPage extends StatefulWidget {
  final VoidCallback onBack;

  const ShiftsPage({super.key, required this.onBack});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final ShiftModalsRepository _repo = ShiftModalsRepository();
  List<ShiftModal> _modals = [];
  bool _loading = true;
  String? _error;

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
      final list = await _repo.fetchModals();
      if (mounted) {
        setState(() {
          _modals = list;
          _loading = false;
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

  void _showEditDialog(ShiftModal modal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _EditShiftDialog(
        modal: modal,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (name, startTime, endTime, graceMinutes, graceUnit, isActive) async {
          try {
            await _repo.updateModal(
              modal.id,
              name: name,
              startTime: startTime,
              endTime: endTime,
              graceMinutes: graceMinutes,
              graceUnit: graceUnit,
              isActive: isActive,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shift updated')),
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

  Future<void> _confirmDelete(ShiftModal modal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete shift'),
        content: Text(
          'Are you sure you want to delete "${modal.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
          const SnackBar(content: Text('Shift deleted')),
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

  String _shortError(String err) {
    if (err.contains('connection') || err.contains('XMLHttpRequest') || err.contains('DioException')) {
      return 'Connection error. Check that the backend is running and try again.';
    }
    if (err.length > 120) return '${err.substring(0, 117)}...';
    return err;
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _shortError(_error!),
              style: const TextStyle(color: AppColors.text, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _load,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  minimumSize: const Size(40, 40),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SectionHeader(
                  title: 'Shifts',
                  subtitle: 'Configure shift timings and grace period',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Add New Shift card (inline form)
          _AddNewShiftCard(
            onAdded: _load,
            createModal: _repo.createModal,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildErrorBanner()
          else if (_modals.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 56,
                      color: AppColors.textMuted.withOpacity(0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No shifts yet. Add one above.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _ShiftsDataTable(
              modals: _modals,
              onEdit: _showEditDialog,
              onDelete: _confirmDelete,
            ),
        ],
      ),
    );
  }
}

class _ShiftsDataTable extends StatelessWidget {
  final List<ShiftModal> modals;
  final void Function(ShiftModal) onEdit;
  final void Function(ShiftModal) onDelete;

  const _ShiftsDataTable({
    required this.modals,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(0.6),
            2: FlexColumnWidth(0.6),
            3: FlexColumnWidth(0.5),
            4: FlexColumnWidth(0.5),
            5: FlexColumnWidth(0.6),
            6: FlexColumnWidth(1.0),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: AppColors.cardHover),
              children: [
                _tableHeader('SHIFT NAME'),
                _tableHeader('START TIME'),
                _tableHeader('END TIME'),
                _tableHeader('GRACE TIME'),
                _tableHeader('UNIT'),
                _tableHeader('STATUS'),
                _tableHeader('ACTIONS', alignRight: true),
              ],
            ),
            for (final m in modals)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                children: [
                  _tableCell(Text(m.name)),
                  _tableCell(Text(m.startTime)),
                  _tableCell(Text(m.endTime)),
                  _tableCell(Text('${m.graceMinutes}')),
                  _tableCell(Text(m.graceUnit)),
                  _tableCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: m.isActive
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.textMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: m.isActive ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                  )),
                  _tableCell(Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => onEdit(m),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => onDelete(m),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(36, 36),
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String label, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        child: child,
      ),
    );
  }
}

typedef _CreateShiftFn = Future<ShiftModal> Function({
  required String name,
  required String startTime,
  required String endTime,
  int graceMinutes,
  String graceUnit,
  bool isActive,
});

class _AddNewShiftCard extends StatefulWidget {
  final VoidCallback onAdded;
  final _CreateShiftFn createModal;

  const _AddNewShiftCard({
    required this.onAdded,
    required this.createModal,
  });

  @override
  State<_AddNewShiftCard> createState() => _AddNewShiftCardState();
}

class _AddNewShiftCardState extends State<_AddNewShiftCard> {
  final _nameController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _graceController = TextEditingController(text: '10');
  String _graceUnit = 'Minutes';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController c) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      c.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  void _clearForm() {
    _nameController.clear();
    _startController.clear();
    _endController.clear();
    _graceController.text = '10';
    setState(() => _graceUnit = 'Minutes');
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final startTime = _startController.text.trim();
    final endTime = _endController.text.trim();
    final graceStr = _graceController.text.trim();
    final graceMinutes = int.tryParse(graceStr) ?? 10;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift name is required')),
      );
      return;
    }
    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time and end time are required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.createModal(
        name: name,
        startTime: startTime,
        endTime: endTime,
        graceMinutes: graceMinutes,
        graceUnit: _graceUnit,
        isActive: true,
      );
      if (!mounted) return;
      _clearForm();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift added')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Shift',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildField(
                label: 'Shift Name',
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'General',
                    isDense: true,
                  ),
                ),
                width: 220,
              ),
              _buildField(
                label: 'Start Time',
                width: 140,
                child: TextField(
                  controller: _startController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: '--:--',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time_rounded, size: 20),
                      onPressed: () => _pickTime(_startController),
                    ),
                  ),
                  onTap: () => _pickTime(_startController),
                ),
              ),
              _buildField(
                label: 'End Time',
                width: 140,
                child: TextField(
                  controller: _endController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: '--:--',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.access_time_rounded, size: 20),
                      onPressed: () => _pickTime(_endController),
                    ),
                  ),
                  onTap: () => _pickTime(_endController),
                ),
              ),
              _buildField(
                label: 'Grace Time',
                width: 100,
                child: TextField(
                  controller: _graceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              _buildField(
                label: 'Unit',
                width: 120,
                child: DropdownButtonFormField<String>(
                  value: _graceUnit,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Minutes', child: Text('Minutes')),
                    DropdownMenuItem(value: 'Hours', child: Text('Hours')),
                  ],
                  onChanged: (v) => setState(() => _graceUnit = v ?? 'Minutes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _submitting ? null : _clearForm,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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
  }

  Widget _buildField({
    required String label,
    required Widget child,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _EditShiftDialog extends StatefulWidget {
  final ShiftModal modal;
  final VoidCallback onClose;
  final Future<void> Function(
    String name,
    String startTime,
    String endTime,
    int graceMinutes,
    String graceUnit,
    bool isActive,
  ) onSave;

  const _EditShiftDialog({
    required this.modal,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_EditShiftDialog> createState() => _EditShiftDialogState();
}

class _EditShiftDialogState extends State<_EditShiftDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _graceController;
  late String _graceUnit;
  late bool _isActive;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final m = widget.modal;
    _nameController = TextEditingController(text: m.name);
    _startController = TextEditingController(text: m.startTime);
    _endController = TextEditingController(text: m.endTime);
    _graceController = TextEditingController(text: '${m.graceMinutes}');
    _graceUnit = m.graceUnit;
    _isActive = m.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController c) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      c.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final startTime = _startController.text.trim();
    final endTime = _endController.text.trim();
    final graceMinutes = int.tryParse(_graceController.text.trim()) ?? 10;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift name is required')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSave(name, startTime, endTime, graceMinutes, _graceUnit, _isActive);
      if (mounted) widget.onClose();
    } catch (_) {
      // SnackBar shown by parent
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit shift'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shift Name', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g., General 1'),
              ),
              const SizedBox(height: 12),
              const Text('Start Time', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _startController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time_rounded),
                    onPressed: () => _pickTime(_startController),
                  ),
                ),
                onTap: () => _pickTime(_startController),
              ),
              const SizedBox(height: 12),
              const Text('End Time', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _endController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time_rounded),
                    onPressed: () => _pickTime(_endController),
                  ),
                ),
                onTap: () => _pickTime(_endController),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grace Time', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _graceController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unit', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _graceUnit,
                          items: const [
                            DropdownMenuItem(value: 'Minutes', child: Text('Minutes')),
                            DropdownMenuItem(value: 'Hours', child: Text('Hours')),
                          ],
                          onChanged: (v) => setState(() => _graceUnit = v ?? 'Minutes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v ?? true),
                    activeColor: AppColors.success,
                  ),
                  const Text('Active', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : widget.onClose,
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

