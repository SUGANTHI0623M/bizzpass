import 'package:flutter/material.dart';

import '../data/company_profile_repository.dart';
import '../utils/image_picker_stub.dart' if (dart.library.html) '../utils/image_picker_web.dart' as image_picker;
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Company Profile: view/edit company details, branches list, upload logo. Shown when profile icon is clicked.
class CompanyProfilePage extends StatefulWidget {
  /// When set, a back icon is shown to navigate back (e.g. to dashboard).
  final VoidCallback? onBack;

  const CompanyProfilePage({super.key, this.onBack});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final CompanyProfileRepository _repo = CompanyProfileRepository();
  CompanyProfile? _profile;
  bool _loading = true;
  String? _error;
  bool _isEditing = false;
  bool _saving = false;
  String? _editError;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repo.fetchProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('CompanyProfileException: ', '');
        });
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    try {
      if (!mounted) return;
      final bytes = await image_picker.pickImageBytes();
      if (bytes == null || bytes.isEmpty || !mounted) return;
      setState(() => _loading = true);
      await _repo.uploadLogo(bytes);
      if (mounted) await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo updated'),
            backgroundColor: context.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final msg = e.toString().contains('LateInitializationError') || e.toString().contains('_instance')
            ? 'File picker failed to start. Try again or use a different browser (e.g. Chrome).'
            : e.toString().replaceAll('CompanyProfileException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: context.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove logo?'),
        content: const Text(
          'This will remove your company logo. You can add a new one anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: ctx.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      setState(() => _loading = true);
      await _repo.deleteLogo();
      if (mounted) await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo removed'),
            backgroundColor: context.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('CompanyProfileException: ', '')),
            backgroundColor: context.dangerColor,
          ),
        );
      }
    }
  }

  void _startEditing() {
    if (_profile == null) return;
    final p = _profile!;
    _nameCtrl.text = p.name;
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phone;
    _cityCtrl.text = p.city;
    _stateCtrl.text = p.state;
    setState(() {
      _isEditing = true;
      _editError = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editError = null;
    });
  }

  Future<void> _saveEditing() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _editError = 'Name and email are required');
      return;
    }
    setState(() {
      _editError = null;
      _saving = true;
    });
    try {
      await _repo.updateProfile(
        name: name,
        email: email,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _saving = false;
        });
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company details updated'),
            backgroundColor: context.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _editError = e.toString().replaceAll('CompanyProfileException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _profile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8),
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
            ),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_error != null && _profile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8),
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final p = _profile!;
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
                    backgroundColor: context.cardHoverColor,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SectionHeader(
                  title: 'Company Profile',
                  subtitle: 'View and edit your company details and branches.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Logo + Company card
          Card(
            color: context.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company logo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textMutedColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _loading ? null : _pickAndUploadLogo,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: context.cardHoverColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: _loading
                              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                              : (p.logo != null && p.logo!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        p.logo!,
                                        fit: BoxFit.cover,
                                        width: 88,
                                        height: 88,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.business_rounded,
                                          size: 40,
                                          color: context.textMutedColor,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_rounded,
                                            size: 28, color: context.textMutedColor),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add logo',
                                          style: TextStyle(fontSize: 11, color: context.textMutedColor),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_editError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: context.dangerColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _editError!,
                                  style: TextStyle(fontSize: 13, color: context.dangerColor),
                                ),
                              ),
                            ],
                            if (_isEditing) ...[
                              FormFieldWrapper(
                                label: 'COMPANY NAME *',
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  style: TextStyle(fontSize: 13, color: context.textColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FormFieldWrapper(
                                label: 'EMAIL *',
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(fontSize: 13, color: context.textColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FormFieldWrapper(
                                label: 'PHONE',
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 13, color: context.textColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FormFieldWrapper(
                                label: 'CITY',
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  style: TextStyle(fontSize: 13, color: context.textColor),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FormFieldWrapper(
                                label: 'STATE',
                                child: TextFormField(
                                  controller: _stateCtrl,
                                  style: TextStyle(fontSize: 13, color: context.textColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: _saving ? null : _cancelEditing,
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: _saving ? null : _saveEditing,
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Save'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _detailRow('Email', p.email),
                              _detailRow('Phone', p.phone),
                              if (p.city.isNotEmpty || p.state.isNotEmpty)
                                _detailRow('Address', '${p.city}${p.city.isNotEmpty && p.state.isNotEmpty ? ', ' : ''}${p.state}'),
                              _detailRow('License', p.licenseKey, mono: true),
                              _detailRow('Plan', p.subscriptionPlan),
                              Row(
                                children: [
                                  InfoMetric(
                                    label: 'Staff',
                                    value: p.maxStaff != null ? '${p.staffCount}/${p.maxStaff}' : '${p.staffCount}',
                                  ),
                                  const SizedBox(width: 16),
                                  InfoMetric(
                                    label: 'Branches',
                                    value: p.maxBranches != null ? '${p.branchesCount}/${p.maxBranches}' : '${p.branchesCount}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _startEditing,
                                    icon: const Icon(Icons.edit_rounded, size: 18),
                                    label: const Text('Edit details'),
                                  ),
                                  const SizedBox(width: 10),
                                  TextButton.icon(
                                    onPressed: _loading ? null : _pickAndUploadLogo,
                                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                                    label: Text(p.logo != null && p.logo!.isNotEmpty ? 'Change logo' : 'Add logo'),
                                  ),
                                  if (p.logo != null && p.logo!.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    TextButton.icon(
                                      onPressed: _loading ? null : _deleteLogo,
                                      icon: Icon(Icons.delete_outline_rounded, size: 18, color: context.dangerColor),
                                      label: Text('Delete logo', style: TextStyle(color: context.dangerColor)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Branches
          Text(
            'Branches (${p.branches.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (p.branches.isEmpty)
            Card(
              color: context.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No branches yet. Add branches from the Branches page.',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
              ),
            )
          else
            ...p.branches.map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: context.cardColor,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.accentColor.withOpacity(0.15),
                      child: Icon(Icons.business_rounded, color: context.accentColor, size: 20),
                    ),
                    title: Text(
                      b.branchName,
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    subtitle: Text(
                      [
                        if (b.isHeadOffice) 'Head office',
                        if (b.addressCity != null && b.addressCity!.isNotEmpty) b.addressCity,
                        if (b.addressState != null && b.addressState!.isNotEmpty) b.addressState,
                        if (b.contactNumber != null && b.contactNumber!.isNotEmpty) b.contactNumber,
                      ].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
                      style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                    ),
                    trailing: StatusBadge(status: b.status ?? 'active'),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool mono = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: context.textColor,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
