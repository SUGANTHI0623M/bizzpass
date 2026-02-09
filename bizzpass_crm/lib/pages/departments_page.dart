import 'package:flutter/material.dart';
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
      final list = await _repo.fetchDepartments();
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
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
          const SizedBox(height: 16),
          if (_loading && _departments.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else
            AppDataTable(
              columns: const [DataCol('Name'), DataCol('Actions')],
              rows: _departments
                  .map((d) => DataRow(
                        cells: [
                          DataCell(Text(d.name)),
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

  @override
  void initState() {
    super.initState();
    if (widget.department != null) _name.text = widget.department!.name;
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
        await widget.repo.updateDepartment(widget.department!.id, name: _name.text.trim());
      } else {
        await widget.repo.createDepartment(name: _name.text.trim());
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
              Text(widget.department != null ? 'Edit department' : 'Add department',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
              const Spacer(),
              IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder(), isDense: true)),
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
