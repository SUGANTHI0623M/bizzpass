import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/branches_repository.dart';

class BranchesPage extends StatefulWidget {
  final void Function(int branchId, String branchName)? onSelectBranch;

  const BranchesPage({super.key, this.onSelectBranch});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  final BranchesRepository _repo = BranchesRepository();
  List<Branch> _branches = [];
  bool _loading = true;
  String? _error;
  bool _showCreateDialog = false;
  Branch? _editingBranch;

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
      final list = await _repo.fetchBranches();
      if (mounted) {
        setState(() {
          _branches = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('BranchesException: ', '');
        });
      }
    }
  }

  Future<void> _deleteBranch(Branch branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete branch'),
        content: Text(
          'Delete "${branch.branchName}"? This will fail if any staff are assigned to this branch.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteBranch(branch.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Branch deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
          const SectionHeader(
            title: 'Manage branches',
            subtitle:
                'Add, edit, or delete branches. Click a branch to view staff.',
          ),
          if (_showCreateDialog)
            _BranchFormDialog(
              onClose: () => setState(() => _showCreateDialog = false),
              onSaved: () {
                setState(() => _showCreateDialog = false);
                _load();
              },
              repo: _repo,
            ),
          if (_editingBranch != null)
            _BranchFormDialog(
              branch: _editingBranch,
              onClose: () => setState(() => _editingBranch = null),
              onSaved: () {
                setState(() => _editingBranch = null);
                _load();
              },
              repo: _repo,
            ),
          if (_error != null) _errorBox(),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _showCreateDialog = true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add branch'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading && _branches.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else
            _buildTable(),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
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
                      fontSize: 13, color: AppColors.textSecondary))),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return AppDataTable(
      columns: const [
        DataCol('Branch name'),
        DataCol('Code'),
        DataCol('Head office'),
        DataCol('City'),
        DataCol('Contact'),
        DataCol('Actions'),
      ],
      rows: _branches
          .map((b) => DataRow(
                cells: [
                  DataCell(
                    widget.onSelectBranch != null
                        ? InkWell(
                            onTap: () =>
                                widget.onSelectBranch!(b.id, b.branchName),
                            child: Text(b.branchName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent)),
                          )
                        : Text(b.branchName),
                  ),
                  DataCell(Text(b.branchCode)),
                  DataCell(Text(b.isHeadOffice ? 'Yes' : 'No')),
                  DataCell(Text(b.addressCity ?? '—')),
                  DataCell(Text(b.contactNumber ?? '—')),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => setState(() => _editingBranch = b),
                          tooltip: 'Edit'),
                      IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20),
                          onPressed: () => _deleteBranch(b),
                          tooltip: 'Delete'),
                      if (widget.onSelectBranch != null)
                        TextButton(
                            onPressed: () =>
                                widget.onSelectBranch!(b.id, b.branchName),
                            child: const Text('View staff')),
                    ],
                  )),
                ],
              ))
          .toList(),
    );
  }
}

class _BranchFormDialog extends StatefulWidget {
  final Branch? branch;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final BranchesRepository repo;

  const _BranchFormDialog(
      {this.branch,
      required this.onClose,
      required this.onSaved,
      required this.repo});

  @override
  State<_BranchFormDialog> createState() => _BranchFormDialogState();
}

const _radiusOptions = [50.0, 100.0, 200.0, 500.0, 1000.0];

class _BranchFormDialogState extends State<_BranchFormDialog> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _contact = TextEditingController();
  final _lat = TextEditingController();
  final _long = TextEditingController();
  bool _isHeadOffice = false;
  bool _saving = false;
  bool _loadingLocation = false;
  double? _attendanceRadiusM;

  @override
  void initState() {
    super.initState();
    if (widget.branch != null) {
      _name.text = widget.branch!.branchName;
      _code.text = widget.branch!.branchCode;
      _city.text = widget.branch!.addressCity ?? '';
      _state.text = widget.branch!.addressState ?? '';
      _contact.text = widget.branch!.contactNumber ?? '';
      _isHeadOffice = widget.branch!.isHeadOffice;
      if (widget.branch!.latitude != null) _lat.text = widget.branch!.latitude.toString();
      if (widget.branch!.longitude != null) _long.text = widget.branch!.longitude.toString();
      _attendanceRadiusM = widget.branch!.attendanceRadiusM;
    }
    if (_attendanceRadiusM == null && _radiusOptions.isNotEmpty) {
      _attendanceRadiusM = _radiusOptions.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _city.dispose();
    _state.dispose();
    _contact.dispose();
    _lat.dispose();
    _long.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Enable them and try again.')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() {
          _lat.text = pos.latitude.toStringAsFixed(6);
          _long.text = pos.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final lat = double.tryParse(_lat.text.trim());
      final lng = double.tryParse(_long.text.trim());
      if (widget.branch != null) {
        await widget.repo.updateBranch(
          widget.branch!.id,
          branchName: _name.text.trim(),
          branchCode: _code.text.trim().isEmpty ? null : _code.text.trim(),
          isHeadOffice: _isHeadOffice,
          addressCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
          addressState: _state.text.trim().isEmpty ? null : _state.text.trim(),
          contactNumber:
              _contact.text.trim().isEmpty ? null : _contact.text.trim(),
          latitude: lat,
          longitude: lng,
          attendanceRadiusM: _attendanceRadiusM,
        );
      } else {
        await widget.repo.createBranch(
          branchName: _name.text.trim(),
          branchCode: _code.text.trim().isEmpty ? null : _code.text.trim(),
          isHeadOffice: _isHeadOffice,
          addressCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
          addressState: _state.text.trim().isEmpty ? null : _state.text.trim(),
          contactNumber:
              _contact.text.trim().isEmpty ? null : _contact.text.trim(),
          latitude: lat,
          longitude: lng,
          attendanceRadiusM: _attendanceRadiusM,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                widget.branch != null ? 'Branch updated' : 'Branch created')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
              Text(widget.branch != null ? 'Edit branch' : 'Add branch',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const Spacer(),
              IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Branch name *',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _code,
              decoration: const InputDecoration(
                  labelText: 'Branch code',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _isHeadOffice,
            onChanged: (v) => setState(() => _isHeadOffice = v ?? false),
            title: const Text('Head office', style: TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          TextField(
              controller: _city,
              decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _state,
              decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _contact,
              decoration: const InputDecoration(
                  labelText: 'Contact number',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 12),
          const Text('Branch location (for attendance check-in)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g. 12.9716',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _long,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g. 77.5946',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                child: OutlinedButton.icon(
                  onPressed: _loadingLocation ? null : _useCurrentLocation,
                  icon: _loadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label: Text(_loadingLocation ? '…' : 'Use current'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<double?>(
            value: _attendanceRadiusM,
            decoration: const InputDecoration(
              labelText: 'Attendance check-in radius',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<double?>(value: null, child: Text('Not set')),
              ..._radiusOptions.map((r) => DropdownMenuItem<double?>(
                    value: r,
                    child: Text('${r.toInt()} m'),
                  )),
            ],
            onChanged: (v) => setState(() => _attendanceRadiusM = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save')),
              const SizedBox(width: 12),
              TextButton(
                  onPressed: widget.onClose, child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }
}
