import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../data/auth_repository.dart';
import '../data/holiday_modals_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Holidays Settings: 2 tabs — Office Holidays and Holiday Modal (weekly off).
class HolidaysSettingsPage extends StatefulWidget {
  final VoidCallback onBack;

  const HolidaysSettingsPage({super.key, required this.onBack});

  @override
  State<HolidaysSettingsPage> createState() => _HolidaysSettingsPageState();
}

class _HolidaysSettingsPageState extends State<HolidaysSettingsPage> {
  int _selectedTab = 0; // 0 = Office Holidays, 1 = Holiday Modal

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
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: SectionHeader(
                  title: 'Holidays Settings',
                  subtitle: 'Office holidays and weekly off (holiday modal)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TabChip(
                label: 'Office Holidays',
                selected: _selectedTab == 0,
                onTap: () => setState(() => _selectedTab = 0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Holiday Modal (weekly off)',
                selected: _selectedTab == 1,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_selectedTab == 0) const _OfficeHolidaysTab(),
          if (_selectedTab == 1) const _HolidayModalTab(),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.border : AppColors.border.withOpacity(0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.text : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Office Holidays tab: list and add office holidays (wired to backend).
class _OfficeHolidaysTab extends StatefulWidget {
  const _OfficeHolidaysTab();

  @override
  State<_OfficeHolidaysTab> createState() => _OfficeHolidaysTabState();
}

class _OfficeHolidaysTabState extends State<_OfficeHolidaysTab> {
  List<OfficeHolidayEntry> _holidays = [];
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
      final repo = OfficeHolidaysRepository();
      final list = await repo.list();
      if (mounted) {
        setState(() {
          _holidays = list;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Office Holidays',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add and manage company-wide office holidays.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Office Holiday'),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.text, fontSize: 13))),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        else if (_holidays.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No office holidays added yet.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ..._holidays.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.date,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete holiday'),
                            content: Text('Remove "${h.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && mounted) {
                          try {
                            await OfficeHolidaysRepository().delete(h.id);
                            _load();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddOfficeHolidayDialog(
        onClose: () => Navigator.pop(ctx),
        onAdded: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }
}

class _AddOfficeHolidayDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onAdded;

  const _AddOfficeHolidayDialog({
    required this.onClose,
    required this.onAdded,
  });

  @override
  State<_AddOfficeHolidayDialog> createState() => _AddOfficeHolidayDialogState();
}

class _AddOfficeHolidayDialogState extends State<_AddOfficeHolidayDialog> {
  final _nameController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await OfficeHolidaysRepository().create(
        name: name,
        date: '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      );
      if (mounted) widget.onAdded();
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
    return AlertDialog(
      title: const Text('Add Office Holiday'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Republic Day',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(
              '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_rounded),
              onPressed: _pickDate,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : widget.onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
        ),
      ],
    );
  }
}

/// Holiday Modal tab: Holiday Modal List (manage all created holiday modals).
class _HolidayModalTab extends StatefulWidget {
  const _HolidayModalTab();

  @override
  State<_HolidayModalTab> createState() => _HolidayModalTabState();
}

class _HolidayModalTabState extends State<_HolidayModalTab> {
  final HolidayModalsRepository _repo = HolidayModalsRepository();
  final _searchController = TextEditingController();
  List<HolidayModal> _modals = [];
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchModals();
      if (mounted) setState(() {
        _modals = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<HolidayModal> get _filteredModals {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _modals;
    return _modals.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.patternLabel.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Holiday Modal List',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage all created holiday modals. Search, add, edit, delete, or view.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search by name or pattern...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showAddOrEditModal(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add holiday modal'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.text, fontSize: 13))),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        else if (_filteredModals.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.calendar_view_week_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    _searchController.text.trim().isEmpty
                        ? 'No holiday modals yet. Add one to define a weekly off pattern.'
                        : 'No results for "${_searchController.text.trim()}".',
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.trim().isEmpty) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showAddOrEditModal(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add holiday modal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (final m in _filteredModals)
                  ListTile(
                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(m.patternLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _showViewModal(m),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => _showAddOrEditModal(existing: m),
                          child: const Text('Edit'),
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(m),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddOrEditModal({HolidayModal? existing}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _HolidayModalFormDialog(
        existing: existing,
        onClose: () => Navigator.of(ctx).pop(),
        onSave: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  void _showViewModal(HolidayModal m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Pattern', value: m.patternLabel),
            _DetailRow(label: 'Status', value: m.isActive ? 'Active' : 'Inactive'),
            if (m.patternType == 'custom' && m.customDays.isNotEmpty)
              _DetailRow(
                label: 'Custom days',
                value: _formatCustomDays(m.customDays),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showAddOrEditModal(existing: m);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  String _formatCustomDays(List<int> days) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => d >= 0 && d < 7 ? labels[d] : '?').join(', ');
  }

  Future<void> _confirmDelete(HolidayModal m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete holiday modal'),
        content: Text('Remove "${m.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.deleteModal(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday modal deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Dialog to add or edit a holiday modal (name + pattern type + custom days).
class _HolidayModalFormDialog extends StatefulWidget {
  final HolidayModal? existing;
  final VoidCallback onClose;
  final VoidCallback onSave;

  const _HolidayModalFormDialog({
    this.existing,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_HolidayModalFormDialog> createState() => _HolidayModalFormDialogState();
}

class _HolidayModalFormDialogState extends State<_HolidayModalFormDialog> {
  final HolidayModalsRepository _repo = HolidayModalsRepository();
  final _nameController = TextEditingController();
  String _pattern = 'sundays';
  List<int> _customDays = [0, 6]; // Sun, Sat by default (backend: 0=Sun .. 6=Sat)
  bool _saving = false;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _pattern = e.patternType;
      _customDays = List.from(e.customDays);
      if (_customDays.isEmpty) _customDays = [5, 6];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await _repo.updateModal(
          widget.existing!.id,
          name: name,
          patternType: _pattern,
          customDays: _pattern == 'custom' ? _customDays : null,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday modal updated')));
      } else {
        await _repo.createModal(
          name: name,
          patternType: _pattern,
          customDays: _pattern == 'custom' ? _customDays : null,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Holiday modal created')));
      }
      widget.onSave();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openCustomDaysPicker() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _CustomDaysPickerDialog(
        selected: List.from(_customDays),
        onSave: (days) {
          setState(() => _customDays = days);
          Navigator.of(ctx).pop();
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add holiday modal' : 'Edit holiday modal'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Name *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'e.g. Standard Sat-Sun'),
              ),
              const SizedBox(height: 20),
              const Text('Weekly off pattern', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              _PatternOption(
                value: 'sundays',
                groupValue: _pattern,
                title: 'Sundays Holiday',
                subtitle: 'Sun: off. Mon–Sat: working.',
                onTap: () => setState(() => _pattern = 'sundays'),
              ),
              const SizedBox(height: 8),
              _PatternOption(
                value: 'odd_saturday',
                groupValue: _pattern,
                title: 'Odd Saturday Holiday',
                subtitle: 'Odd Sats (1st, 3rd, 5th) + Sun: off.',
                onTap: () => setState(() => _pattern = 'odd_saturday'),
              ),
              const SizedBox(height: 8),
              _PatternOption(
                value: 'even_saturday',
                groupValue: _pattern,
                title: 'Even Saturday Holiday',
                subtitle: 'Even Sats (2nd, 4th, 6th) + Sun: off.',
                onTap: () => setState(() => _pattern = 'even_saturday'),
              ),
              const SizedBox(height: 8),
              _PatternOption(
                value: 'all_saturday',
                groupValue: _pattern,
                title: 'All Saturday Holiday',
                subtitle: 'Sat + Sun: off. Mon–Fri: working.',
                onTap: () => setState(() => _pattern = 'all_saturday'),
              ),
              const SizedBox(height: 8),
              _PatternOption(
                value: 'custom',
                groupValue: _pattern,
                title: 'Customise',
                subtitle: 'Define your own weekly off days.',
                onTap: () => setState(() => _pattern = 'custom'),
              ),
              if (_pattern == 'custom') ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openCustomDaysPicker,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text('Configure: ${_customDays.map((d) => _dayLabels[d]).join(', ')}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : widget.onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

class _CustomDaysPickerDialog extends StatefulWidget {
  final List<int> selected;
  final void Function(List<int>) onSave;
  final VoidCallback onClose;

  const _CustomDaysPickerDialog({
    required this.selected,
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_CustomDaysPickerDialog> createState() => _CustomDaysPickerDialogState();
}

class _CustomDaysPickerDialogState extends State<_CustomDaysPickerDialog> {
  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  late List<bool> _daysOff;

  @override
  void initState() {
    super.initState();
    _daysOff = List.filled(7, false);
    for (final d in widget.selected) {
      if (d >= 0 && d < 7) _daysOff[d] = true;
    }
    if (!_daysOff.any((x) => x)) {
      _daysOff[5] = true;
      _daysOff[6] = true;
    }
  }

  List<int> get _selected => [for (var i = 0; i < 7; i++) if (_daysOff[i]) i];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom holiday days'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 7; i++)
            FilterChip(
              label: Text(_dayLabels[i]),
              selected: _daysOff[i],
              onSelected: (v) => setState(() => _daysOff[i] = v),
              selectedColor: AppColors.accent.withOpacity(0.3),
              checkmarkColor: AppColors.accent,
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => widget.onSave(_selected),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PatternOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PatternOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.success : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Radio<String>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomHolidayFormModal extends StatefulWidget {
  final void Function(List<String> daysOff) onSave;
  final VoidCallback onClose;

  const _CustomHolidayFormModal({
    required this.onSave,
    required this.onClose,
  });

  @override
  State<_CustomHolidayFormModal> createState() => _CustomHolidayFormModalState();
}

class _CustomHolidayFormModalState extends State<_CustomHolidayFormModal> {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late List<bool> _daysOff;

  @override
  void initState() {
    super.initState();
    _daysOff = List.filled(7, false);
    _daysOff[5] = true; // Saturday
    _daysOff[6] = true; // Sunday - default
  }

  List<String> get _selectedDays => [
        for (var i = 0; i < 7; i++) if (_daysOff[i]) _dayLabels[i],
      ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Holiday Pattern'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select days as weekly holiday (off)',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 7; i++)
                  FilterChip(
                    label: Text(_dayLabels[i]),
                    selected: _daysOff[i],
                    onSelected: (v) => setState(() => _daysOff[i] = v),
                    selectedColor: AppColors.success.withOpacity(0.3),
                    checkmarkColor: AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedDays.isEmpty)
              Text(
                'Select at least one day as holiday.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.danger.withOpacity(0.9),
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
        FilledButton(
          onPressed: _selectedDays.isEmpty
              ? null
              : () {
                  widget.onSave(_selectedDays);
                  widget.onClose();
                },
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─── Office Holidays API (will be implemented in backend) ───────────────────

class OfficeHolidayEntry {
  final int id;
  final String name;
  final String date;

  OfficeHolidayEntry({
    required this.id,
    required this.name,
    required this.date,
  });
}

class OfficeHolidaysRepository {
  OfficeHolidaysRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;
  final AuthRepository _auth = AuthRepository();

  Future<void> _addAuthToken() async {
    final token = await _auth.getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<List<OfficeHolidayEntry>> list() async {
    await _addAuthToken();
    final res = await _dio.get<Map<String, dynamic>>('/office-holidays');
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Failed to fetch office holidays');
    }
    final list = res.data!['holidays'] as List<dynamic>? ?? [];
    return list
        .map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return OfficeHolidayEntry(
            id: (m['id'] as num?)?.toInt() ?? 0,
            name: (m['name'] as String?) ?? '',
            date: (m['date'] as String?) ?? '',
          );
        })
        .toList();
  }

  Future<OfficeHolidayEntry> create({required String name, required String date}) async {
    await _addAuthToken();
    final res = await _dio.post<Map<String, dynamic>>(
      '/office-holidays',
      data: {'name': name, 'date': date},
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final d = res.data;
      final detail = (d is Map) ? d!['detail'] : null;
      throw Exception(detail != null ? detail.toString() : 'Failed to create');
    }
    final data = res.data!;
    final m = Map<String, dynamic>.from(data as Map);
    return OfficeHolidayEntry(
      id: (m['id'] as num?)?.toInt() ?? 0,
      name: (m['name'] as String?) ?? name,
      date: (m['date'] as String?) ?? date,
    );
  }

  Future<void> delete(int id) async {
    await _addAuthToken();
    final res = await _dio.delete('/office-holidays/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      final d = res.data;
      final detail = d is Map ? d['detail'] : null;
      throw Exception(detail != null ? detail.toString() : 'Failed to delete');
    }
  }
}
