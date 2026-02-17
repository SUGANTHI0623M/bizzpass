import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/fine_modals_repository.dart';

/// Page to manage fine modal templates (grace rules + fine calculation).
class FineModalsPage extends StatefulWidget {
  final VoidCallback onBack;

  const FineModalsPage({super.key, required this.onBack});

  @override
  State<FineModalsPage> createState() => _FineModalsPageState();
}

class _FineModalsPageState extends State<FineModalsPage> {
  final FineModalsRepository _repo = FineModalsRepository();
  final _searchController = TextEditingController();
  List<FineModal> _modals = [];
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

  List<FineModal> get _filteredModals {
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
            msg.contains('SocketException');
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
      builder: (ctx) => _FineModalDialog(
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data) async {
          try {
            await _repo.createModal(
              name: data.name,
              description: data.description.isNotEmpty ? data.description : null,
              isActive: data.isActive,
              graceConfig: data.graceConfig,
              fineCalculationMethod: data.fineCalculationMethod,
              fineFixedAmount: data.fineFixedAmount,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fine modal created')),
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

  void _showEditDialog(FineModal modal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _FineModalDialog(
        existing: modal,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (data) async {
          try {
            await _repo.updateModal(
              modal.id,
              name: data.name,
              description: data.description.isNotEmpty ? data.description : null,
              isActive: data.isActive,
              graceConfig: data.graceConfig,
              fineCalculationMethod: data.fineCalculationMethod,
              fineFixedAmount: data.fineFixedAmount,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fine modal updated')),
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

  Future<void> _confirmDelete(FineModal modal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fine Modal'),
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
          const SnackBar(content: Text('Fine modal deleted')),
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
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
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
                  title: 'Fine Modals',
                  subtitle:
                      'Grace rules (late login, early logout) and fine calculation templates',
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Icon(Icons.gavel_rounded, size: 48, color: context.textMutedColor),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.trim().isEmpty
                          ? 'No fine modals yet. Add one to configure grace rules and fine calculation.'
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
                DataCol('Grace Rules'),
                DataCol('Status'),
                DataCol('Actions'),
              ],
              rows: _filteredModals
                  .map((m) => DataRow(
                        cells: [
                          DataCell(Text(m.name)),
                          DataCell(Text(
                            m.description.isEmpty ? '—' : m.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(_formatGraceRules(m.graceConfig))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                                color: m.isActive
                                    ? context.successColor
                                    : context.textMutedColor,
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
                                icon: Icon(Icons.delete_outline_rounded,
                                    color: context.dangerColor),
                                tooltip: 'Delete',
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

  String _formatGraceRules(GraceConfig gc) {
    final parts = <String>[];
    if (gc.lateLogin.enabled) {
      parts.add(
          'Late: ${gc.lateLogin.graceMinutesPerDay}m, ${gc.lateLogin.graceCountPerMonth}/cycle');
    }
    if (gc.earlyLogout.enabled) {
      parts.add(
          'Early: ${gc.earlyLogout.graceMinutesPerDay}m, ${gc.earlyLogout.graceCountPerMonth}/cycle');
    }
    return parts.isEmpty ? '—' : parts.join(' • ');
  }
}

class _FineModalDialog extends StatefulWidget {
  final FineModal? existing;
  final VoidCallback onClose;
  final void Function(_FineModalFormData) onSave;

  const _FineModalDialog({
    this.existing,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_FineModalDialog> createState() => _FineModalDialogState();
}

class _FineModalFormData {
  String name;
  String description;
  bool isActive;
  Map<String, dynamic> graceConfig;
  String fineCalculationMethod;
  double? fineFixedAmount;

  _FineModalFormData({
    required this.name,
    required this.description,
    required this.isActive,
    required this.graceConfig,
    required this.fineCalculationMethod,
    this.fineFixedAmount,
  });
}

class _FineModalDialogState extends State<_FineModalDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _active = true;
  bool _graceLateLogin = true;
  int _graceMinutesLate = 10;
  int _graceCountLate = 3;
  String _resetCycleLate = 'MONTHLY';
  String _graceTypeLate = 'PER_OCCURRENCE';
  bool _graceEarlyLogout = false;
  int _graceMinutesEarly = 0;
  int _graceCountEarly = 0;
  String _resetCycleEarly = 'MONTHLY';
  String _graceTypeEarly = 'PER_OCCURRENCE';
  String _fineCalcMethod = 'per_minute';
  final _fineFixedController = TextEditingController(text: '0');
  final _graceMinutesLateController = TextEditingController(text: '10');
  final _graceCountLateController = TextEditingController(text: '3');
  final _graceMinutesEarlyController = TextEditingController(text: '0');
  final _graceCountEarlyController = TextEditingController(text: '0');
  bool _saving = false;

  static const _resetCycles = ['MONTHLY', 'WEEKLY', 'NEVER'];
  static const _graceTypes = [
    ('PER_OCCURRENCE', 'Per Occurrence'),
    ('COUNT_BASED', 'Count-Based'),
    ('COMBINED', 'Combined Mode'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) {
      _graceMinutesLateController.text = '10';
      _graceCountLateController.text = '3';
      _graceMinutesEarlyController.text = '0';
      _graceCountEarlyController.text = '0';
    } else {
      _name.text = e.name;
      _desc.text = e.description;
      _active = e.isActive;
      _graceLateLogin = e.graceConfig.lateLogin.enabled;
      _graceMinutesLate = e.graceConfig.lateLogin.graceMinutesPerDay;
      _graceCountLate = e.graceConfig.lateLogin.graceCountPerMonth;
      _graceMinutesLateController.text = _graceMinutesLate.toString();
      _graceCountLateController.text = _graceCountLate.toString();
      _resetCycleLate = e.graceConfig.lateLogin.resetCycle;
      _graceTypeLate = e.graceConfig.lateLogin.graceType;
      _graceEarlyLogout = e.graceConfig.earlyLogout.enabled;
      _graceMinutesEarly = e.graceConfig.earlyLogout.graceMinutesPerDay;
      _graceCountEarly = e.graceConfig.earlyLogout.graceCountPerMonth;
      _graceMinutesEarlyController.text = _graceMinutesEarly.toString();
      _graceCountEarlyController.text = _graceCountEarly.toString();
      _resetCycleEarly = e.graceConfig.earlyLogout.resetCycle;
      _graceTypeEarly = e.graceConfig.earlyLogout.graceType;
      _fineCalcMethod = e.fineCalculationMethod;
      _fineFixedController.text =
          (e.fineFixedAmount ?? 0).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _fineFixedController.dispose();
    _graceMinutesLateController.dispose();
    _graceCountLateController.dispose();
    _graceMinutesEarlyController.dispose();
    _graceCountEarlyController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildGraceConfig() {
    final minutesLate = int.tryParse(_graceMinutesLateController.text) ?? _graceMinutesLate;
    final countLate = int.tryParse(_graceCountLateController.text) ?? _graceCountLate;
    final minutesEarly = int.tryParse(_graceMinutesEarlyController.text) ?? _graceMinutesEarly;
    final countEarly = int.tryParse(_graceCountEarlyController.text) ?? _graceCountEarly;
    return {
      'lateLogin': {
        'enabled': _graceLateLogin,
        'graceMinutesPerDay': minutesLate.clamp(0, 60),
        'graceCountPerMonth': countLate.clamp(0, 31),
        'resetCycle': _resetCycleLate,
        'graceType': _graceTypeLate,
        'weekStartDay': 1,
      },
      'earlyLogout': {
        'enabled': _graceEarlyLogout,
        'graceMinutesPerDay': minutesEarly.clamp(0, 60),
        'graceCountPerMonth': countEarly.clamp(0, 31),
        'resetCycle': _resetCycleEarly,
        'graceType': _graceTypeEarly,
        'weekStartDay': 1,
      },
    };
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modal name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    widget.onSave(_FineModalFormData(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      isActive: _active,
      graceConfig: _buildGraceConfig(),
      fineCalculationMethod: _fineCalcMethod,
      fineFixedAmount: double.tryParse(_fineFixedController.text),
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
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
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
                          isEdit ? 'Edit Fine Modal' : 'Create Fine Modal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure grace rules for late login and early logout',
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
                        hintText: 'e.g. IT Standard, Factory Strict',
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
                        hintText: 'Describe this fine template...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SwitchRow(
                      label: 'Active',
                      subtitle: 'Only active modals can be assigned',
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Grace for LATE_LOGIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      label: 'Enable grace for late login',
                      subtitle: 'Allow grace minutes/count for late arrivals',
                      value: _graceLateLogin,
                      onChanged: (v) => setState(() => _graceLateLogin = v),
                    ),
                    if (_graceLateLogin) ...[
                      _buildNumberField(
                        'Grace minutes per day',
                        _graceMinutesLateController,
                        (v) => setState(() => _graceMinutesLate = v),
                        0,
                        60,
                      ),
                      _buildNumberField(
                        'Grace count per cycle',
                        _graceCountLateController,
                        (v) => setState(() => _graceCountLate = v),
                        0,
                        30,
                      ),
                      _buildDropdown(
                        'Reset cycle',
                        _resetCycleLate,
                        _resetCycles,
                        (v) => setState(() => _resetCycleLate = v ?? 'MONTHLY'),
                      ),
                      _buildDropdown(
                        'Grace type',
                        _graceTypeLate,
                        _graceTypes.map((e) => e.$1).toList(),
                        (v) =>
                            setState(() => _graceTypeLate = v ?? 'PER_OCCURRENCE'),
                        labels: _graceTypes.map((e) => e.$2).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Grace for EARLY_LOGOUT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SwitchRow(
                      label: 'Enable grace for early logout',
                      subtitle: 'Allow grace for early departures',
                      value: _graceEarlyLogout,
                      onChanged: (v) => setState(() => _graceEarlyLogout = v),
                    ),
                    if (_graceEarlyLogout) ...[
                      _buildNumberField(
                        'Grace minutes per day',
                        _graceMinutesEarlyController,
                        (v) => setState(() => _graceMinutesEarly = v),
                        0,
                        60,
                      ),
                      _buildNumberField(
                        'Grace count per cycle',
                        _graceCountEarlyController,
                        (v) => setState(() => _graceCountEarly = v),
                        0,
                        30,
                      ),
                      _buildDropdown(
                        'Reset cycle',
                        _resetCycleEarly,
                        _resetCycles,
                        (v) => setState(() => _resetCycleEarly = v ?? 'MONTHLY'),
                      ),
                      _buildDropdown(
                        'Grace type',
                        _graceTypeEarly,
                        _graceTypes.map((e) => e.$1).toList(),
                        (v) =>
                            setState(() => _graceTypeEarly = v ?? 'PER_OCCURRENCE'),
                        labels: _graceTypes.map((e) => e.$2).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Fine Calculation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      'Method',
                      _fineCalcMethod,
                      ['per_minute', 'fixed_per_occurrence'],
                      (v) => setState(() => _fineCalcMethod = v ?? 'per_minute'),
                      labels: const ['Per minute (salary-based)', 'Fixed per occurrence'],
                    ),
                    if (_fineCalcMethod == 'fixed_per_occurrence')
                      TextFormField(
                        controller: _fineFixedController,
                        decoration: const InputDecoration(
                          labelText: 'Fixed amount (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
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

  Widget _SwitchRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
          Switch(value: value, onChanged: onChanged, activeColor: context.accentColor),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController ctrl,
    ValueChanged<int> onChanged,
    int min,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= min && n <= max) onChanged(n);
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    List<String>? labels,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : options.first,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: List.generate(options.length, (i) {
          final opt = options[i];
          final lbl = (labels != null && i < labels.length) ? labels[i] : opt;
          return DropdownMenuItem(value: opt, child: Text(lbl));
        }),
        onChanged: onChanged,
      ),
    );
  }
}
