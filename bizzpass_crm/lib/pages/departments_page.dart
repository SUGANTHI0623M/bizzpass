import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/departments_repository.dart';

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
  bool _showCreateDialog = false;
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

  Future<void> _deleteDepartment(Department dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete department'),
        content: Text('Delete "${dept.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: TextStyle(color: ctx.dangerColor))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteDepartment(dept.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Department deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Manage departments',
            subtitle: 'Add, edit, or delete departments.',
          ),
          if (_showCreateDialog)
            _DepartmentFormDialog(
              onClose: () => setState(() => _showCreateDialog = false),
              onSaved: () {
                setState(() => _showCreateDialog = false);
                _load();
              },
              repo: _repo,
            ),
          if (_editingDepartment != null)
            _DepartmentFormDialog(
              department: _editingDepartment,
              onClose: () => setState(() => _editingDepartment = null),
              onSaved: () {
                setState(() => _editingDepartment = null);
                _load();
              },
              repo: _repo,
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
                onPressed: () => setState(() => _showCreateDialog = true),
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
              columns: const [DataCol('Name'), DataCol('Status'), DataCol('Actions')],
              rows: _departments
                  .map((d) => DataRow(
                        cells: [
                          DataCell(Text(d.name)),
                          DataCell(Text(d.active ? 'Active' : 'Inactive')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => setState(() => _editingDepartment = d),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                onPressed: () => _deleteDepartment(d),
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
}

class _DepartmentFormDialog extends StatefulWidget {
  final Department? department;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final DepartmentsRepository repo;

  const _DepartmentFormDialog({
    this.department,
    required this.onClose,
    required this.onSaved,
    required this.repo,
  });

  @override
  State<_DepartmentFormDialog> createState() => _DepartmentFormDialogState();
}

class _DepartmentFormDialogState extends State<_DepartmentFormDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  late bool _active;

  @override
  void initState() {
    super.initState();
    if (widget.department != null) {
      _name.text = widget.department!.name;
      _active = widget.department!.active;
    } else {
      _active = true;
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
        );
      } else {
        await widget.repo.createDepartment(name: _name.text.trim(), active: _active);
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
          Row(
            children: [
              Text(widget.department != null ? 'Edit department' : 'Add department',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textColor)),
              const Spacer(),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
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
