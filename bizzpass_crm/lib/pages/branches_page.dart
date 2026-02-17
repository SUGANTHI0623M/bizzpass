import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/map_location_picker.dart';
import '../data/branches_repository.dart';

class BranchesPage extends StatefulWidget {
  /// When user taps a branch name (e.g. to see details).
  final void Function(Branch branch)? onBranchTap;
  /// When user taps "View staff" for a branch.
  final void Function(int branchId, String branchName)? onViewStaff;
  /// If set, open edit dialog for this branch when page loads.
  final Branch? initialEditBranch;
  /// When the edit form is closed (e.g. user clicked close). If set, parent may navigate back to branch details.
  final VoidCallback? onEditFormClosed;

  const BranchesPage({
    super.key,
    this.onBranchTap,
    this.onViewStaff,
    this.initialEditBranch,
    this.onEditFormClosed,
  });

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
    if (widget.initialEditBranch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingBranch = widget.initialEditBranch);
      });
    }
  }

  @override
  void didUpdateWidget(covariant BranchesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEditBranch != null &&
        widget.initialEditBranch != oldWidget.initialEditBranch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _editingBranch = widget.initialEditBranch);
      });
    }
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

  Future<void> _setBranchStatus(Branch branch, bool activate) async {
    final action = activate ? 'Activate' : 'Deactivate';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardColor,
        title: Text('$action branch', style: TextStyle(color: ctx.textColor)),
        content: Text(
          activate
              ? 'Activate "${branch.branchName}"?'
              : 'Deactivate "${branch.branchName}"? You can activate it again from branch details.',
          style: TextStyle(color: ctx.textSecondaryColor),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(action, style: TextStyle(color: ctx.accentColor))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.setBranchStatus(branch.id, activate ? 'active' : 'inactive');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Branch ${activate ? 'activated' : 'deactivated'}')),
        );
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
    final isEditing = _editingBranch != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: isEditing ? 'Edit branch' : 'Manage branches',
            subtitle: isEditing
                ? 'Update branch details below.'
                : 'Add or manage branches. Click a row for details. Deactivate a branch to add more when at limit.',
          ),
          if (_showCreateDialog)
            _BranchFormDialog(
              existingBranches: _branches,
              onClose: () => setState(() => _showCreateDialog = false),
              onSaved: () {
                setState(() => _showCreateDialog = false);
                _load();
              },
              repo: _repo,
            ),
          if (_editingBranch != null)
            _BranchFormDialog(
              existingBranches: _branches,
              branch: _editingBranch,
              onClose: () {
                widget.onEditFormClosed?.call();
                setState(() => _editingBranch = null);
              },
              onSaved: () {
                widget.onEditFormClosed?.call();
                setState(() => _editingBranch = null);
                _load();
              },
              repo: _repo,
            ),
          if (_error != null) _errorBox(),
          if (!isEditing) ...[
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
        ],
      ),
    );
  }

  Widget _branchCell({required Widget child, required Branch branch}) {
    if (widget.onBranchTap == null) return child;
    return InkWell(
      onTap: () => widget.onBranchTap!(branch),
      child: child,
    );
  }

  Widget _errorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: context.warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_error!,
                  style: TextStyle(
                      fontSize: 13, color: context.textSecondaryColor))),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  static String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildTable() {
    return AppDataTable(
      showCheckboxColumn: false,
      columns: const [
        DataCol('Branch name'),
        DataCol('Code'),
        DataCol('Head office'),
        DataCol('City'),
        DataCol('Contact'),
        DataCol('Status'),
        DataCol('Created at'),
        DataCol('Actions'),
      ],
      rows: _branches
          .map((b) => DataRow(
                onSelectChanged: widget.onBranchTap != null
                    ? (_) => widget.onBranchTap!(b)
                    : null,
                cells: [
                  DataCell(_branchCell(
                    child: Text(b.branchName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: widget.onBranchTap != null
                                ? context.accentColor
                                : context.textColor)),
                    branch: b,
                  )),
                  DataCell(_branchCell(child: Text(b.branchCode), branch: b)),
                  DataCell(_branchCell(
                      child: Text(b.isHeadOffice ? 'Yes' : 'No'), branch: b)),
                  DataCell(_branchCell(
                      child: Text(b.addressCity ?? '—'), branch: b)),
                  DataCell(_branchCell(
                      child: Text(b.contactNumber ?? '—'), branch: b)),
                  DataCell(_branchCell(
                      child: Text(b.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                              color: b.isActive
                                  ? context.successColor
                                  : context.textMutedColor)),
                      branch: b)),
                  DataCell(_branchCell(
                      child: Text(b.createdAt != null && b.createdAt!.isNotEmpty ? _formatCreatedAt(b.createdAt!) : '—'),
                      branch: b)),
                  DataCell(
                    IconButton(
                      icon: Icon(
                        b.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                        size: 28,
                        color: b.isActive ? context.accentColor : context.textMutedColor,
                      ),
                      onPressed: () => _setBranchStatus(b, !b.isActive),
                      tooltip: b.isActive ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

class _BranchFormDialog extends StatefulWidget {
  final List<Branch> existingBranches;
  final Branch? branch;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final BranchesRepository repo;

  const _BranchFormDialog({
    required this.existingBranches,
    this.branch,
    required this.onClose,
    required this.onSaved,
    required this.repo,
  });

  @override
  State<_BranchFormDialog> createState() => _BranchFormDialogState();
}

const _radiusOptions = [50.0, 100.0, 200.0, 500.0, 1000.0];

class _BranchFormDialogState extends State<_BranchFormDialog> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _aptBuilding = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _country = TextEditingController();
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
    _name.addListener(_onNameChanged);
    if (widget.branch != null) {
      _name.text = widget.branch!.branchName;
      _code.text = widget.branch!.branchCode;
      _aptBuilding.text = widget.branch!.addressAptBuilding ?? '';
      _street.text = widget.branch!.addressStreet ?? '';
      _city.text = widget.branch!.addressCity ?? '';
      _state.text = widget.branch!.addressState ?? '';
      _zip.text = widget.branch!.addressZip ?? '';
      _country.text = widget.branch!.addressCountry ?? '';
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

  void _onNameChanged() => setState(() {});

  bool get _isDuplicateBranchName {
    final name = _name.text.trim();
    if (name.isEmpty) return false;
    return widget.existingBranches.any((b) {
      if (widget.branch != null && b.id == widget.branch!.id) return false;
      return b.branchName.trim().toLowerCase() == name.toLowerCase();
    });
  }

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    _code.dispose();
    _aptBuilding.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _country.dispose();
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
        await _setAddressFromCoords(pos.latitude, pos.longitude);
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

  Future<void> _setAddressFromCoords(double lat, double lng) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));
      final res = await dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lng, 'format': 'json', 'addressdetails': 1},
        options: Options(headers: {'User-Agent': 'BizzPass-CRM/1.0'}),
      );
      final data = res.data;
      if (mounted && data != null) {
        final displayName = data['display_name'] as String?;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null || displayName != null) {
          setState(() {
            if (displayName != null && displayName.isNotEmpty) _street.text = displayName;
            if (addr != null) {
              final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'];
              final state = addr['state'] ?? addr['county'];
              if (city != null) _city.text = city.toString();
              if (state != null) _state.text = state.toString();
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _openMapPicker() async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_long.text.trim());
    final result = await MapLocationPickerDialog.show(
      context,
      initialLat: lat,
      initialLng: lng,
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat.text = result.latitude.toStringAsFixed(6);
      _long.text = result.longitude.toStringAsFixed(6);
      if (result.address != null && result.address!.isNotEmpty) _street.text = result.address!;
      if (result.city != null) _city.text = result.city!;
      if (result.state != null) _state.text = result.state!;
    });
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch name is required')));
      return;
    }
    if (_isDuplicateBranchName) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch name already exists.')));
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
          addressAptBuilding: _aptBuilding.text.trim().isEmpty ? null : _aptBuilding.text.trim(),
          addressStreet: _street.text.trim().isEmpty ? null : _street.text.trim(),
          addressCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
          addressState: _state.text.trim().isEmpty ? null : _state.text.trim(),
          addressZip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
          addressCountry: _country.text.trim().isEmpty ? null : _country.text.trim(),
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
          addressAptBuilding: _aptBuilding.text.trim().isEmpty ? null : _aptBuilding.text.trim(),
          addressStreet: _street.text.trim().isEmpty ? null : _street.text.trim(),
          addressCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
          addressState: _state.text.trim().isEmpty ? null : _state.text.trim(),
          addressZip: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
          addressCountry: _country.text.trim().isEmpty ? null : _country.text.trim(),
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
              Text(widget.branch != null ? 'Edit branch' : 'Add branch',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textColor)),
              const Spacer(),
              IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: 'Branch name *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _isDuplicateBranchName ? 'Branch name already exists.' : null)),
          const SizedBox(height: 8),
          TextField(
              controller: _code,
              decoration: const InputDecoration(
                  labelText: 'Branch code',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final otherBranchIsHeadOffice = widget.existingBranches
                  .any((b) => b.isHeadOffice && b.id != (widget.branch?.id ?? -1));
              return CheckboxListTile(
                value: _isHeadOffice,
                onChanged: otherBranchIsHeadOffice
                    ? null
                    : (v) => setState(() => _isHeadOffice = v ?? false),
                title: const Text('Head office', style: TextStyle(fontSize: 14)),
                subtitle: otherBranchIsHeadOffice
                    ? Text(
                        'Another branch is already set as head office.',
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      )
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            },
          ),
          TextField(
              controller: _aptBuilding,
              decoration: const InputDecoration(
                  labelText: 'Apt / Building',
                  hintText: 'e.g. Suite 101, Tower A',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _street,
              decoration: const InputDecoration(
                  labelText: 'Street address',
                  hintText: 'e.g. 123 Main Street, Tech Park',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        isDense: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _state,
                    decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                        isDense: true)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                    controller: _zip,
                    decoration: const InputDecoration(
                        labelText: 'ZIP / Postal code',
                        border: OutlineInputBorder(),
                        isDense: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                    controller: _country,
                    decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        isDense: true)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
              controller: _contact,
              decoration: const InputDecoration(
                  labelText: 'Contact number',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 12),
          Text('Branch location (for attendance check-in)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textColor)),
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
              OutlinedButton.icon(
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Set on map'),
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
