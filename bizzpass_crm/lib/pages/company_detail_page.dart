import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/companies_repository.dart';
import '../data/plans_repository.dart';
import '../data/mock_data.dart';

/// Full-page company view or edit. Shown when super admin opens View/Edit company.
/// Sidebar remains (handled by parent AppShell).
class CompanyDetailPage extends StatefulWidget {
  final int companyId;
  final bool initialIsEdit;
  final VoidCallback onBack;

  const CompanyDetailPage({
    super.key,
    required this.companyId,
    required this.initialIsEdit,
    required this.onBack,
  });

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  final CompaniesRepository _repo = CompaniesRepository();
  Company? _company;
  bool _loading = true;
  String? _error;
  bool _isEdit = false;
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.initialIsEdit;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final company = await _repo.getCompany(widget.companyId);
      if (mounted) {
        setState(() {
          _company = company;
          _loading = false;
        });
        if (_isEdit) _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('CompaniesException: ', '');
        });
      }
    }
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await PlansRepository().fetchPlans(activeOnly: true);
      if (mounted) setState(() => _plans = plans);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _company == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && _company == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to companies',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: context.textSecondaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return _isEdit ? _buildEdit() : _buildView();
  }

  Widget _buildView() {
    final c = _company!;
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
                tooltip: 'Back to companies',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SectionHeader(
                  title: c.name,
                  subtitle: 'Company details',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gridWrap([
                  DetailTile(label: 'EMAIL', value: c.email),
                  DetailTile(label: 'PHONE', value: c.phone.isEmpty ? '—' : c.phone),
                  DetailTile(
                    label: 'LICENSE KEY',
                    value: c.licenseKey,
                    mono: true,
                    valueColor: context.accentColor,
                  ),
                  DetailTile(label: 'PLAN', value: c.subscriptionPlan),
                ]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InfoMetric(
                        label: 'Staff',
                        value: c.maxStaff != null
                            ? '${c.staffCount}/${c.maxStaff}'
                            : '${c.staffCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoMetric(
                        label: 'Branches',
                        value: c.maxBranches != null
                            ? '${c.branches}/${c.maxBranches}'
                            : '${c.branches}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoMetric(
                        label: 'Active',
                        value: c.isActive ? 'Yes' : 'No',
                        valueColor:
                            c.isActive ? context.successColor : context.dangerColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    StatusBadge(status: c.subscriptionStatus, large: true),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: ${c.subscriptionEndDate}',
                      style: TextStyle(fontSize: 12, color: context.textDimColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _isEdit = true;
                        _loadPlans();
                      }),
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => _confirmDeactivate(c),
                      style: TextButton.styleFrom(
                        foregroundColor: context.dangerColor,
                      ),
                      child: const Text('Deactivate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdit() {
    return _CompanyEditForm(
      company: _company!,
      plans: _plans,
      repo: _repo,
      onBack: () => setState(() => _isEdit = false),
      onSaved: () async {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company updated')),
          );
        }
      },
      onNavigateBack: widget.onBack,
    );
  }

  Future<void> _confirmDeactivate(Company c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Deactivate company?'),
        content: const Text(
          'This will deactivate the company. You can reactivate by editing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Deactivate', style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _repo.deleteCompany(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company deactivated')),
        );
        widget.onBack();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _gridWrap(List<Widget> tiles) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: tiles,
    );
  }
}

class _CompanyEditForm extends StatefulWidget {
  final Company company;
  final List<Plan> plans;
  final CompaniesRepository repo;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final VoidCallback onNavigateBack;

  const _CompanyEditForm({
    required this.company,
    required this.plans,
    required this.repo,
    required this.onBack,
    required this.onSaved,
    required this.onNavigateBack,
  });

  @override
  State<_CompanyEditForm> createState() => _CompanyEditFormState();
}

class _CompanyEditFormState extends State<_CompanyEditForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _adminPasswordCtrl;
  late TextEditingController _reEnterCtrl;
  late String _selectedPlan;
  late bool _isActive;
  bool _submitting = false;
  String? _submitError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final c = widget.company;
    _nameCtrl = TextEditingController(text: c.name);
    _emailCtrl = TextEditingController(text: c.email);
    _phoneCtrl = TextEditingController(text: c.phone);
    _cityCtrl = TextEditingController(text: c.city);
    _stateCtrl = TextEditingController(text: c.state);
    _adminPasswordCtrl = TextEditingController();
    _reEnterCtrl = TextEditingController();
    _selectedPlan = widget.plans.any((p) => p.planName == c.subscriptionPlan)
        ? c.subscriptionPlan
        : (widget.plans.isNotEmpty ? widget.plans.first.planName : 'Starter');
    _isActive = c.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _reEnterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final newPassword = _adminPasswordCtrl.text.trim();
    final reEnter = _reEnterCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() {
        _submitError = 'Company name and email are required';
        _passwordError = null;
      });
      return;
    }
    if (newPassword.isNotEmpty || reEnter.isNotEmpty) {
      if (newPassword.length < 8) {
        setState(() {
          _passwordError = 'Password must be at least 8 characters';
          _submitError = null;
        });
        return;
      }
      if (newPassword != reEnter) {
        setState(() {
          _passwordError = 'Passwords do not match';
          _submitError = null;
        });
        return;
      }
    }
    setState(() {
      _submitting = true;
      _submitError = null;
      _passwordError = null;
    });
    try {
      await widget.repo.updateCompany(
        widget.company.id,
        name: name,
        email: email,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        subscriptionPlan: _selectedPlan,
        isActive: _isActive,
        adminPassword: newPassword.isEmpty ? null : newPassword,
      );
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = e.toString().replaceAll('CompaniesException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _submitting ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to view',
              ),
              const SizedBox(width: 8),
              Text(
                'Edit Company',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_submitError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: context.dangerColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _submitError!,
                            style: TextStyle(
                                fontSize: 13, color: context.dangerColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                FormFieldWrapper(
                  label: 'COMPANY NAME *',
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(fontSize: 13, color: context.textColor),
                  ),
                ),
                FormFieldWrapper(
                  label: 'EMAIL *',
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 13, color: context.textColor),
                  ),
                ),
                FormFieldWrapper(
                  label: 'PHONE',
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 13, color: context.textColor),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormFieldWrapper(
                        label: 'CITY',
                        child: TextFormField(
                          controller: _cityCtrl,
                          style: TextStyle(
                              fontSize: 13, color: context.textColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: FormFieldWrapper(
                        label: 'STATE',
                        child: TextFormField(
                          controller: _stateCtrl,
                          style: TextStyle(
                              fontSize: 13, color: context.textColor),
                        ),
                      ),
                    ),
                  ],
                ),
                FormFieldWrapper(
                  label: 'SUBSCRIPTION PLAN',
                  child: DropdownButtonFormField<String>(
                    value: plans.isNotEmpty
                        ? (plans.any((p) => p.planName == _selectedPlan)
                            ? _selectedPlan
                            : plans.first.planName)
                        : _selectedPlan,
                    decoration: const InputDecoration(),
                    style: TextStyle(fontSize: 13, color: context.textColor),
                    items: plans.isNotEmpty
                        ? plans
                            .map((p) => DropdownMenuItem<String>(
                                  value: p.planName,
                                  child: Text(p.planName),
                                ))
                            .toList()
                        : ['Starter', 'Professional', 'Enterprise']
                            .map((p) => DropdownMenuItem<String>(
                                  value: p,
                                  child: Text(p),
                                ))
                            .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedPlan = v ?? _selectedPlan),
                  ),
                ),
                FormFieldWrapper(
                  label: 'ACTIVE',
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isActive,
                        onChanged: (v) =>
                            setState(() => _isActive = v ?? true),
                        activeColor: context.accentColor,
                      ),
                      Text(
                        'Company is active',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                FormFieldWrapper(
                  label: 'ADMIN PASSWORD',
                  child: TextFormField(
                    controller: _adminPasswordCtrl,
                    obscureText: true,
                    style: TextStyle(fontSize: 13, color: context.textColor),
                    decoration: const InputDecoration(
                      hintText: 'Leave blank to keep current password',
                    ),
                  ),
                ),
                FormFieldWrapper(
                  label: 'RE-ENTER PASSWORD',
                  child: TextFormField(
                    controller: _reEnterCtrl,
                    obscureText: true,
                    style: TextStyle(fontSize: 13, color: context.textColor),
                    decoration: const InputDecoration(
                      hintText: 'Re-enter new password',
                    ),
                  ),
                ),
                if (_passwordError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _passwordError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.dangerColor,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting ? null : widget.onBack,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
