import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/roles_repository.dart';

class RolesPermissionsPage extends StatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  State<RolesPermissionsPage> createState() => _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends State<RolesPermissionsPage> {
  final RolesRepository _repo = RolesRepository();
  List<Role> _roles = [];
  Map<String, List<Map<String, dynamic>>> _permissions = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  bool _showCreateForm = false;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Set<String> _selectedPerms = {};
  bool _saving = false;
  Role? _viewRole;
  Role? _editingRole;
  final _editNameController = TextEditingController();
  final _editDescController = TextEditingController();
  final Set<String> _editSelectedPerms = {};
  bool _savingEdit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _editNameController.dispose();
    _editDescController.dispose();
    super.dispose();
  }

  List<Role> get _filteredRoles {
    if (_searchQuery.trim().isEmpty) return _roles;
    final q = _searchQuery.trim().toLowerCase();
    return _roles.where((r) {
      final nameMatch = r.name.toLowerCase().contains(q);
      final descMatch = (r.description ?? '').toLowerCase().contains(q);
      return nameMatch || descMatch;
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _repo.fetchRoles();
      final perms = await _repo.fetchPermissions();
      if (mounted) {
        setState(() {
          _roles = roles;
          _permissions = perms;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('RolesException: ', '');
        });
      }
    }
  }

  void _openCreateRole() {
    _nameController.clear();
    _descController.clear();
    _selectedPerms.clear();
    setState(() => _showCreateForm = true);
  }

  Future<void> _submitCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.createRole(
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        permissionCodes: _selectedPerms.toList(),
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _showCreateForm = false;
        });
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('RolesException: ', ''))),
        );
      }
    }
  }

  void _openView(Role r) {
    setState(() => _viewRole = r);
  }

  void _openEdit(Role r) {
    if (r.code.toUpperCase() == 'COMPANY_ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit Company Admin role')),
      );
      return;
    }
    if (r.isSystemRole == false && r.staffCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit role'),
          content: Text(
            'This role is assigned to ${r.staffCount} staff. Are you sure you want to edit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startEdit(r);
              },
              child: const Text('Yes, edit'),
            ),
          ],
        ),
      );
    } else {
      _startEdit(r);
    }
  }

  void _startEdit(Role r) {
    _editingRole = r;
    _editNameController.text = r.name;
    _editDescController.text = r.description ?? '';
    _editSelectedPerms.clear();
    _editSelectedPerms.addAll(r.permissionCodes);
    setState(() {});
  }

  Future<void> _submitEdit() async {
    final role = _editingRole;
    if (role == null) return;
    final name = _editNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role name is required')),
      );
      return;
    }
    setState(() => _savingEdit = true);
    try {
      await _repo.updateRole(
        role.id,
        name: name,
        description: _editDescController.text.trim().isEmpty
            ? null
            : _editDescController.text.trim(),
        permissionCodes: _editSelectedPerms.toList(),
      );
      if (mounted) {
        setState(() {
          _savingEdit = false;
          _editingRole = null;
        });
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingEdit = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('RolesException: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteRole(Role r) async {
    if (r.isSystemRole) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete system roles')),
      );
      return;
    }
    if (r.code.toUpperCase() == 'COMPANY_ADMIN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete Company Admin role')),
      );
      return;
    }
    if (r.staffCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete. This role is assigned to ${r.staffCount} staff. Reassign them first.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role'),
        content: Text(
          'Are you sure you want to delete "${r.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.deleteRole(r.id);
      if (mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('RolesException: ', ''))),
        );
      }
    }
  }

  String? _permissionDescription(String code) {
    for (final list in _permissions.values) {
      for (final p in list) {
        if ((p['code'] as String? ?? '') == code) {
          return p['description'] as String?;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoles;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: SectionHeader(
                      title: 'Roles & Permissions',
                      subtitle: 'Manage roles and their permissions',
                    ),
                  ),
                  if (!_showCreateForm && _editingRole == null)
                    TextButton.icon(
                      onPressed: _openCreateRole,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create role'),
                    ),
                ],
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
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              ],
              AppSearchBar(
                hint: 'Search by role name or description...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 12),
              if (_showCreateForm) _buildCreateForm(),
              if (_editingRole != null) _buildEditForm(),
              if (_loading && _roles.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                AppDataTable(
                  columns: const [
                    DataCol('Role'),
                    DataCol('Type'),
                    DataCol('Permissions'),
                    DataCol('Assigned'),
                    DataCol('Actions'),
                  ],
                  rows: filtered
                      .map((r) => DataRow(
                            cells: [
                              DataCell(
                                InkWell(
                                  onTap: () => _openView(r),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text)),
                                      if (r.description != null &&
                                          r.description!.isNotEmpty)
                                        Text(r.description!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textDim)),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                  r.isSystemRole ? 'System' : 'Custom',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: r.isSystemRole
                                          ? AppColors.textMuted
                                          : AppColors.accent))),
                              DataCell(Text(
                                '${r.permissionCodes.length} permissions',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              )),
                              DataCell(Text(
                                '${r.staffCount} staff',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 20, color: AppColors.textMuted),
                                    onPressed: () => _openView(r),
                                    tooltip: 'View details',
                                  ),
                                  if (r.code.toUpperCase() != 'COMPANY_ADMIN')
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 20, color: AppColors.textMuted),
                                      onPressed: () => _openEdit(r),
                                      tooltip: 'Edit',
                                    ),
                                  if (!r.isSystemRole)
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 20,
                                          color: r.staffCount > 0
                                              ? AppColors.textDim
                                              : AppColors.danger),
                                      onPressed: () => _deleteRole(r),
                                      tooltip: r.staffCount > 0
                                          ? 'Cannot delete: assigned to staff'
                                          : 'Delete',
                                    ),
                                ],
                              )),
                            ],
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        if (_viewRole != null) _buildViewDialog(),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New custom role',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Role name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const Text('Permissions',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: 6),
          ..._permissions.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (e.value).map((p) {
                      final code = (p['code'] as String? ?? '').toString();
                      final isOn = _selectedPerms.contains(code);
                      return FilterChip(
                        label: Text(
                          p['description'] ?? code,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isOn,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedPerms.add(code);
                            } else {
                              _selectedPerms.remove(code);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : _submitCreate,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _showCreateForm = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    final r = _editingRole!;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit role: ${r.name}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _editingRole = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _editNameController,
            decoration: const InputDecoration(
              labelText: 'Role name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _editDescController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const Text('Permissions',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: 6),
          ..._permissions.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (e.value).map((p) {
                      final code = (p['code'] as String? ?? '').toString();
                      final isOn = _editSelectedPerms.contains(code);
                      return FilterChip(
                        label: Text(
                          p['description'] ?? code,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: isOn,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _editSelectedPerms.add(code);
                            } else {
                              _editSelectedPerms.remove(code);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _savingEdit ? null : _submitEdit,
                child: _savingEdit
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _editingRole = null),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewDialog() {
    final r = _viewRole!;
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black54,
          onDismiss: () => setState(() => _viewRole = null),
        ),
        Center(
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _viewRole = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (r.description != null && r.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(r.description!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          r.isSystemRole ? 'System' : 'Custom',
                          style: TextStyle(
                              fontSize: 12,
                              color: r.isSystemRole
                                  ? AppColors.textMuted
                                  : AppColors.accent),
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Assigned to ${r.staffCount} staff',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Permissions',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: r.permissionCodes.map((code) {
                          final desc = _permissionDescription(code) ?? code;
                          return Chip(
                            label: Text(desc,
                                style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
