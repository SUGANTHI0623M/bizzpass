import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/leave_modals_repository.dart';
import '../data/leave_categories_repository.dart';

/// Leave modals (templates) management: search, add, edit, delete, activate/deactivate.
class LeaveModalsPage extends StatefulWidget {
  final VoidCallback onBack;

  const LeaveModalsPage({super.key, required this.onBack});

  @override
  State<LeaveModalsPage> createState() => _LeaveModalsPageState();
}

class _LeaveModalsPageState extends State<LeaveModalsPage> {
  final LeaveModalsRepository _repo = LeaveModalsRepository();
  final _searchController = TextEditingController();
  List<LeaveModal> _modals = [];
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

  void _showManageCategories() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ManageCategoriesDialog(
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  List<LeaveModal> get _filteredModals {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _modals;
    return _modals.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q);
    }).toList();
  }

  void _showCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LeaveModalDialog(
        categoriesRepository: LeaveCategoriesRepository(),
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (name, description, leaveTypes, isActive) async {
          try {
            await _repo.createModal(
              name: name,
              description: description.isEmpty ? null : description,
              leaveTypes: leaveTypes,
              isActive: isActive,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Leave modal created')),
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

  void _showEditDialog(LeaveModal modal) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LeaveModalDialog(
        existing: modal,
        categoriesRepository: LeaveCategoriesRepository(),
        onClose: () => Navigator.of(ctx).pop(),
        onSave: (name, description, leaveTypes, isActive) async {
          try {
            await _repo.updateModal(
              modal.id,
              name: name,
              description: description.isEmpty ? null : description,
              leaveTypes: leaveTypes,
              isActive: isActive,
            );
            if (ctx.mounted) Navigator.of(ctx).pop();
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Leave modal updated')),
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

  Future<void> _confirmDelete(LeaveModal modal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete leave modal'),
        content: Text('Remove "${modal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
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
      await _repo.deleteModal(modal.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave modal deleted')),
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
    final filtered = _filteredModals;
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
                  title: 'Leave Templates',
                  subtitle: 'Manage company leave policies and assign them to staff.',
                ),
              ),
              TextButton.icon(
                onPressed: _showManageCategories,
                icon: const Icon(Icons.category_rounded, size: 18),
                label: const Text('Manage categories'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Template'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.text, fontSize: 13),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (filtered.isEmpty)
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
                    Icon(Icons.beach_access_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.trim().isEmpty
                          ? 'No leave templates yet. Add one to get started.'
                          : 'No results for "${_searchController.text.trim()}".',
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchController.text.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Template'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Name'),
                DataCol('Description'),
                DataCol('Categories'),
                DataCol('Status'),
                DataCol('Actions'),
              ],
              rows: filtered.map((m) => DataRow(
                cells: [
                  DataCell(Text(m.name)),
                  DataCell(Text(
                    m.description.isEmpty ? '—' : m.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
                  DataCell(Text('${m.leaveTypes.length}')),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: m.isActive
                          ? AppColors.accent.withOpacity(0.15)
                          : AppColors.textMuted.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: m.isActive ? AppColors.accent : AppColors.textMuted,
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
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
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

class _LeaveModalDialog extends StatefulWidget {
  final LeaveModal? existing;
  final LeaveCategoriesRepository categoriesRepository;
  final VoidCallback onClose;
  final void Function(String name, String description, List<dynamic> leaveTypes, bool isActive) onSave;

  const _LeaveModalDialog({
    this.existing,
    required this.categoriesRepository,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<_LeaveModalDialog> createState() => _LeaveModalDialogState();
}

class _LeaveModalDialogState extends State<_LeaveModalDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  List<LeaveCategory> _categories = [];
  bool _categoriesLoading = true;
  final List<String?> _selectedCategoryNames = [];
  final List<TextEditingController> _ltDaysControllers = [];
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _descController.text = e.description;
      _isActive = e.isActive;
      for (final lt in e.leaveTypes) {
        if (lt is Map) {
          final m = Map<String, dynamic>.from(lt);
          _selectedCategoryNames.add((m['name'] ?? '').toString());
          _ltDaysControllers.add(TextEditingController(text: (m['days'] ?? 0).toString()));
        } else {
          _selectedCategoryNames.add(lt.toString());
          _ltDaysControllers.add(TextEditingController(text: '0'));
        }
      }
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await widget.categoriesRepository.fetchCategories();
      if (mounted) setState(() {
        _categories = list;
        _categoriesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _ltDaysControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCategoryRow() {
    setState(() {
      _selectedCategoryNames.add(_categories.isNotEmpty ? _categories.first.name : null);
      _ltDaysControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeCategoryRow(int i) {
    setState(() {
      _selectedCategoryNames.removeAt(i);
      _ltDaysControllers[i].dispose();
      _ltDaysControllers.removeAt(i);
    });
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template name is required')),
      );
      return;
    }
    final leaveTypes = <Map<String, dynamic>>[];
    for (var i = 0; i < _selectedCategoryNames.length; i++) {
      final name = _selectedCategoryNames[i]?.trim() ?? '';
      if (name.isEmpty) continue;
      leaveTypes.add({
        'name': name,
        'days': int.tryParse(_ltDaysControllers[i].text.trim()) ?? 0,
      });
    }
    setState(() => _saving = true);
    widget.onSave(
      _nameController.text.trim(),
      _descController.text.trim(),
      leaveTypes,
      _isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Create Leave Template' : 'Edit Leave Template'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Template Name *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Standard Leave Policy 2024',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Optional description for this template',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Leave Category *', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _categories.isEmpty ? null : _addCategoryRow,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add category'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_categoriesLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No categories yet. Click \'Manage categories\' on the Leave Templates page to create categories (e.g. Sick, Casual).',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                )
              else if (_selectedCategoryNames.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No categories added yet. Click \'Add category\' to select a leave category and days.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                )
              else
                ...List.generate(_selectedCategoryNames.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryNames[i] != null &&
                                    (_categories.any((c) => c.name == _selectedCategoryNames[i]) ||
                                        _selectedCategoryNames[i]!.isNotEmpty)
                                ? _selectedCategoryNames[i]
                                : _categories.isNotEmpty
                                    ? _categories.first.name
                                    : null,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              isDense: true,
                            ),
                            items: [
                              ..._categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))),
                              if (_selectedCategoryNames[i] != null &&
                                  _selectedCategoryNames[i]!.isNotEmpty &&
                                  !_categories.any((c) => c.name == _selectedCategoryNames[i]))
                                DropdownMenuItem(
                                  value: _selectedCategoryNames[i],
                                  child: Text(_selectedCategoryNames[i]!),
                                ),
                            ],
                            onChanged: (v) => setState(() => _selectedCategoryNames[i] = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _ltDaysControllers[i],
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeCategoryRow(i),
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v ?? true),
                    activeColor: AppColors.accent,
                  ),
                  const Text('Active', style: TextStyle(fontSize: 14)),
                ],
              ),
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
              : Text(widget.existing == null ? 'Create Template' : 'Save'),
        ),
      ],
    );
  }
}

/// Dialog to manage leave categories (Sick, Casual, etc.).
class _ManageCategoriesDialog extends StatefulWidget {
  final VoidCallback onClose;

  const _ManageCategoriesDialog({required this.onClose});

  @override
  State<_ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<_ManageCategoriesDialog> {
  final LeaveCategoriesRepository _repo = LeaveCategoriesRepository();
  List<LeaveCategory> _categories = [];
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
      final list = await _repo.fetchCategories();
      if (mounted) setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Add category'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Category name',
              hintText: 'e.g. Sick, Casual',
            ),
            autofocus: true,
            onSubmitted: (_) => Navigator.of(ctx).pop(c.text.trim()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(c.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await _repo.createCategory(name: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(LeaveCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Remove "${cat.name}"?'),
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
      await _repo.deleteCategory(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage leave categories'),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create categories like Sick, Casual, etc. They will appear in the dropdown when creating leave templates.',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add category'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No categories yet. Click \'Add category\' to create one.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        )
                      else
                        ..._categories.map((c) => ListTile(
                              title: Text(c.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                onPressed: () => _confirmDelete(c),
                                tooltip: 'Delete',
                              ),
                            )),
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: const Text('Close')),
      ],
    );
  }
}
