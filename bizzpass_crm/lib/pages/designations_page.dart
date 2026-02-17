import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/designations_repository.dart';

/// Manage designations (job titles). Same pattern as Departments. Shown from Business settings.
class DesignationsPage extends StatefulWidget {
  /// When set, a back icon is shown to navigate back (e.g. to Settings).
  final VoidCallback? onBack;

  const DesignationsPage({super.key, this.onBack});

  @override
  State<DesignationsPage> createState() => _DesignationsPageState();
}

class _DesignationsPageState extends State<DesignationsPage> {
  final DesignationsRepository _repo = DesignationsRepository();
  List<Designation> _designations = [];
  bool _loading = true;
  String? _error;
  bool _showCreateDialog = false;
  Designation? _editingDesignation;
  String _search = '';
  bool? _filterActive;

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
      final list = await _repo.fetchDesignations(
        active: _filterActive,
        search: _search.trim().isEmpty ? null : _search.trim(),
      );
      if (mounted) {
        setState(() {
          _designations = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('DesignationsException: ', '');
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBack != null) ...[
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: context.accentColor.withOpacity(0.12),
                    foregroundColor: context.accentColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: SectionHeader(
                  title: 'Designations',
                  subtitle: 'Add, edit, or set active/inactive for job designations.',
                ),
              ),
            ],
          ),
          if (_showCreateDialog)
            _DesignationFormDialog(
              onClose: () => setState(() => _showCreateDialog = false),
              onSaved: () {
                setState(() => _showCreateDialog = false);
                _load();
              },
              repo: _repo,
            ),
          if (_editingDesignation != null)
            _DesignationFormDialog(
              designation: _editingDesignation,
              onClose: () => setState(() => _editingDesignation = null),
              onSaved: () {
                setState(() => _editingDesignation = null);
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
                label: const Text('Add designation'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by designation name...',
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
          if (_loading && _designations.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else
            AppDataTable(
              showCheckboxColumn: false,
              columns: const [DataCol('Name'), DataCol('Status'), DataCol('Created at'), DataCol('Actions')],
              rows: _designations
                  .map((d) => DataRow(
                        cells: [
                          DataCell(Text(d.name)),
                          DataCell(Text(d.active ? 'Active' : 'Inactive')),
                          DataCell(Text(d.createdAt != null && d.createdAt!.isNotEmpty ? _formatCreatedAt(d.createdAt!) : '—')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => setState(() => _editingDesignation = d),
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

class _DesignationFormDialog extends StatefulWidget {
  final Designation? designation;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final DesignationsRepository repo;

  const _DesignationFormDialog({
    this.designation,
    required this.onClose,
    required this.onSaved,
    required this.repo,
  });

  @override
  State<_DesignationFormDialog> createState() => _DesignationFormDialogState();
}

class _DesignationFormDialogState extends State<_DesignationFormDialog> {
  final _name = TextEditingController();
  bool _saving = false;
  late bool _active;

  @override
  void initState() {
    super.initState();
    if (widget.designation != null) {
      _name.text = widget.designation!.name;
      _active = widget.designation!.active;
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
      if (widget.designation != null) {
        await widget.repo.updateDesignation(
          widget.designation!.id,
          name: _name.text.trim(),
          active: _active,
        );
      } else {
        await widget.repo.createDesignation(name: _name.text.trim(), active: _active);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.designation != null ? 'Designation updated' : 'Designation created')));
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
              Text(widget.designation != null ? 'Edit designation' : 'Add designation',
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
