import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/companies_repository.dart';
import '../data/plans_repository.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});
  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  String _search = '';
  String _tab = 'all';
  List<Company> _companies = [];
  bool _loading = true;
  String? _error;
  final CompaniesRepository _repo = CompaniesRepository();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchCompanies(
        search: _search.isEmpty ? null : _search,
        tab: _tab,
      );
      setState(() {
        _companies = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _companies = [];
        _loading = false;
        _error = e.toString().replaceAll('CompaniesException: ', '');
      });
    }
  }

  List<Company> get _filtered {
    if (_search.isEmpty) return _companies;
    final s = _search.toLowerCase();
    return _companies.where((c) {
      return c.name.toLowerCase().contains(s) ||
          c.city.toLowerCase().contains(s);
    }).toList();
  }

  Future<void> _showAddCompanyDialog() async {
    List<Plan> plans = [];
    try {
      plans = await PlansRepository().fetchPlans(activeOnly: true);
    } catch (_) {}
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final licenseKeyCtrl = TextEditingController();
    String selectedPlan = plans.isNotEmpty ? plans.first.planName : 'Starter';
    bool isActive = true;
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: context.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Company',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.textColor,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              submitting ? null : () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded,
                              size: 20, color: context.textMutedColor),
                          style: IconButton.styleFrom(
                              backgroundColor: context.cardHoverColor),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (submitError != null) ...[
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
                                    submitError!,
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
                            controller: nameCtrl,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            decoration: const InputDecoration(
                                hintText: 'e.g. Acme Solutions'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormFieldWrapper(
                          label: 'EMAIL *',
                          child: TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            decoration: const InputDecoration(
                                hintText: 'admin@company.com'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'PHONE',
                                child: TextFormField(
                                  controller: phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  decoration: const InputDecoration(
                                      hintText: '+91 XXXXX XXXXX'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'SUBSCRIPTION PLAN',
                                child: DropdownButtonFormField<String>(
                                  value: plans.any(
                                          (p) => p.planName == selectedPlan)
                                      ? selectedPlan
                                      : (plans.isNotEmpty
                                          ? plans.first.planName
                                          : 'Starter'),
                                  decoration: const InputDecoration(),
                                  dropdownColor: context.cardColor,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  items: plans.isNotEmpty
                                      ? plans
                                          .map((p) => DropdownMenuItem<String>(
                                                value: p.planName,
                                                child: Text(p.planName),
                                              ))
                                          .toList()
                                      : const [
                                          DropdownMenuItem(
                                              value: 'Starter',
                                              child: Text('Starter')),
                                          DropdownMenuItem(
                                              value: 'Professional',
                                              child: Text('Professional')),
                                          DropdownMenuItem(
                                              value: 'Enterprise',
                                              child: Text('Enterprise')),
                                        ],
                                  onChanged: (v) => setDialogState(() =>
                                      selectedPlan = v ??
                                          (plans.isNotEmpty
                                              ? plans.first.planName
                                              : 'Starter')),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'CITY',
                                child: TextFormField(
                                  controller: cityCtrl,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  decoration:
                                      const InputDecoration(hintText: 'City'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'STATE',
                                child: TextFormField(
                                  controller: stateCtrl,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  decoration:
                                      const InputDecoration(hintText: 'State'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FormFieldWrapper(
                          label: 'LICENSE KEY (required)',
                          child: TextFormField(
                            controller: licenseKeyCtrl,
                            style: TextStyle(
                                fontSize: 13,
                                color: context.textColor,
                                fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              hintText: 'Enter an unassigned license key',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'License key is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        FormFieldWrapper(
                          label: 'ACTIVE',
                          child: Row(
                            children: [
                              Checkbox(
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v ?? true),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      final email = emailCtrl.text.trim();
                                      final licenseKey = licenseKeyCtrl.text.trim();
                                      if (name.isEmpty || email.isEmpty) {
                                        setDialogState(() {
                                          submitError =
                                              'Company name and email are required';
                                        });
                                        return;
                                      }
                                      if (licenseKey.isEmpty) {
                                        setDialogState(() {
                                          submitError =
                                              'License key is required';
                                        });
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        final result =
                                            await _repo.createCompany(
                                          name: name,
                                          email: email,
                                          phone: phoneCtrl.text.trim().isEmpty
                                              ? null
                                              : phoneCtrl.text.trim(),
                                          city: cityCtrl.text.trim().isEmpty
                                              ? null
                                              : cityCtrl.text.trim(),
                                          state: stateCtrl.text.trim().isEmpty
                                              ? null
                                              : stateCtrl.text.trim(),
                                          subscriptionPlan: selectedPlan,
                                          licenseKey: licenseKey,
                                          isActive: isActive,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadCompanies();
                                          if (result.adminLogin != null) {
                                            final em = result
                                                .adminLogin!['email']
                                                ?.toString();
                                            final pw = result.adminLogin![
                                                    'temporaryPassword']
                                                ?.toString();
                                            if (em != null && pw != null) {
                                              showDialog(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  backgroundColor: context.bgColor,
                                                  title: Text(
                                                      'Company created – Admin login'),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Company admin can log in with:',
                                                          style: TextStyle(
                                                              color: c.textSecondaryColor),
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        SelectableText(
                                                          'Email: $em',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        SelectableText(
                                                          'Password: $pw',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          result.adminLogin![
                                                                      'message']
                                                                  ?.toString() ??
                                                              'Ask them to change password after first login.',
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: c.textMutedColor),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(c),
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Company created successfully'),
                                              backgroundColor:
                                                  context.successColor,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'CompaniesException: ', '');
                                        });
                                      }
                                    },
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text('Create Company'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(Company c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  child: Row(
                    children: [
                      AvatarCircle(name: c.name, seed: c.id, size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: context.textColor,
                                )),
                            Text('${c.city}, ${c.state}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.textMutedColor,
                                )),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: context.textMutedColor),
                        style: IconButton.styleFrom(
                            backgroundColor: context.cardHoverColor),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _gridWrap([
                        DetailTile(label: 'EMAIL', value: c.email),
                        DetailTile(label: 'PHONE', value: c.phone),
                        DetailTile(
                            label: 'LICENSE KEY',
                            value: c.licenseKey,
                            mono: true,
                            valueColor: context.accentColor),
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
                                      : '${c.staffCount}')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: InfoMetric(
                                  label: 'Branches',
                                  value: c.maxBranches != null
                                      ? '${c.branches}/${c.maxBranches}'
                                      : '${c.branches}')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: InfoMetric(
                            label: 'Active',
                            value: c.isActive ? 'Yes' : 'No',
                            valueColor: c.isActive
                                ? context.successColor
                                : context.dangerColor,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Spacer(),
                          StatusBadge(
                              status: c.subscriptionStatus, large: true),
                          const SizedBox(width: 8),
                          Text('Expires: ${c.subscriptionEndDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textDimColor,
                              )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEditCompanyDialog(c);
                            },
                            child: Text('Edit'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: context.bgColor,
                                  title: Text('Deactivate company?'),
                                  content: Text(
                                    'This will deactivate the company. You can reactivate by editing.',
                                  ),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, false),
                                        child: Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx, true),
                                        child: Text('Deactivate',
                                            style: TextStyle(
                                                color: context.dangerColor))),
                                  ],
                                ),
                              );
                              if (confirm == true && ctx.mounted) {
                                try {
                                  await _repo.deleteCompany(c.id);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    _loadCompanies();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Company deactivated'),
                                        backgroundColor: context.successColor,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceAll(
                                            'CompaniesException: ', '')),
                                        backgroundColor: context.dangerColor,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: context.dangerColor),
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditCompanyDialog(Company c) async {
    List<Plan> plans = [];
    try {
      plans = await PlansRepository().fetchPlans(activeOnly: true);
    } catch (_) {}
    if (!mounted) return;

    final nameCtrl = TextEditingController(text: c.name);
    final emailCtrl = TextEditingController(text: c.email);
    final phoneCtrl = TextEditingController(text: c.phone);
    final cityCtrl = TextEditingController(text: c.city);
    final stateCtrl = TextEditingController(text: c.state);
    String selectedPlan = plans.any((p) => p.planName == c.subscriptionPlan)
        ? c.subscriptionPlan
        : (plans.isNotEmpty ? plans.first.planName : c.subscriptionPlan);
    bool isActive = c.isActive;
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: context.borderColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Company',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.textColor)),
                        IconButton(
                          onPressed:
                              submitting ? null : () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded,
                              size: 20, color: context.textMutedColor),
                          style: IconButton.styleFrom(
                              backgroundColor: context.cardHoverColor),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (submitError != null) ...[
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
                                    child: Text(submitError!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: context.dangerColor))),
                              ],
                            ),
                          ),
                        ],
                        FormFieldWrapper(
                          label: 'COMPANY NAME *',
                          child: TextFormField(
                            controller: nameCtrl,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'EMAIL *',
                          child: TextFormField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'PHONE',
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'CITY',
                                child: TextFormField(
                                  controller: cityCtrl,
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
                                  controller: stateCtrl,
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
                                ? (plans.any((p) => p.planName == selectedPlan)
                                    ? selectedPlan
                                    : plans.first.planName)
                                : (['Starter', 'Professional', 'Enterprise']
                                        .contains(selectedPlan)
                                    ? selectedPlan
                                    : 'Starter'),
                            decoration: const InputDecoration(),
                            dropdownColor: context.cardColor,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            items: plans.isNotEmpty
                                ? plans
                                    .map((p) => DropdownMenuItem<String>(
                                          value: p.planName,
                                          child: Text(p.planName),
                                        ))
                                    .toList()
                                : const [
                                    DropdownMenuItem(
                                        value: 'Starter',
                                        child: Text('Starter')),
                                    DropdownMenuItem(
                                        value: 'Professional',
                                        child: Text('Professional')),
                                    DropdownMenuItem(
                                        value: 'Enterprise',
                                        child: Text('Enterprise')),
                                  ],
                            onChanged: (v) => setDialogState(() =>
                                selectedPlan = v ??
                                    (plans.isNotEmpty
                                        ? plans.first.planName
                                        : 'Starter')),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'ACTIVE',
                          child: Row(
                            children: [
                              Checkbox(
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v ?? true),
                                activeColor: context.accentColor,
                              ),
                              Text('Company is active',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecondaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final name = nameCtrl.text.trim();
                                      final email = emailCtrl.text.trim();
                                      if (name.isEmpty || email.isEmpty) {
                                        setDialogState(() => submitError =
                                            'Company name and email are required');
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        await _repo.updateCompany(
                                          c.id,
                                          name: name,
                                          email: email,
                                          phone: phoneCtrl.text.trim().isEmpty
                                              ? null
                                              : phoneCtrl.text.trim(),
                                          city: cityCtrl.text.trim().isEmpty
                                              ? null
                                              : cityCtrl.text.trim(),
                                          state: stateCtrl.text.trim().isEmpty
                                              ? null
                                              : stateCtrl.text.trim(),
                                          subscriptionPlan: selectedPlan,
                                          isActive: isActive,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadCompanies();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Company updated'),
                                              backgroundColor:
                                                  context.successColor,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'CompaniesException: ', '');
                                        });
                                      }
                                    },
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridWrap(List<Widget> children) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children.map((c) => SizedBox(width: 250, child: c)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            title: 'Companies',
            subtitle: _loading
                ? 'Loading...'
                : '${_companies.length} registered companies',
            actionLabel: 'Add Company',
            actionIcon: Icons.add_rounded,
            onAction: _showAddCompanyDialog,
            bottomPadding: 12,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
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
                            fontSize: 13, color: context.textSecondaryColor)),
                  ),
                  TextButton(
                    onPressed: _loadCompanies,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Expanded(
                  child: AppTabBar(
                    tabs: [
                      TabItem(
                          id: 'all', label: 'All', count: _companies.length),
                      TabItem(
                          id: 'active',
                          label: 'Active',
                          count: _companies.where((c) => c.isActive).length),
                      TabItem(
                          id: 'inactive',
                          label: 'Inactive',
                          count: _companies.where((c) => !c.isActive).length),
                      TabItem(
                          id: 'expiring',
                          label: 'Expiring',
                          count: _companies
                              .where((c) =>
                                  c.subscriptionStatus == 'expiring_soon')
                              .length),
                    ],
                    active: _tab,
                    onChanged: (v) => setState(() {
                      _tab = v;
                      _loadCompanies();
                    }),
                    marginBottom: 12,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 280,
                  child: AppSearchBar(
                      hint: 'Search companies...',
                      onChanged: (v) => setState(() {
                            _search = v;
                            if (v.isEmpty) _loadCompanies();
                          })),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else
            AppDataTable(
              columns: const [
                DataCol('Company'),
                DataCol('Plan'),
                DataCol('Status'),
                DataCol('Staff'),
                DataCol('Branches'),
                DataCol('Expires'),
                DataCol(''),
              ],
              rows: filtered
                  .map((c) => DataRow(
                        onSelectChanged: (_) => _showDetail(c),
                        cells: [
                          DataCell(Row(children: [
                            AvatarCircle(name: c.name, seed: c.id),
                            const SizedBox(width: 10),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: context.textColor)),
                                Text('${c.city}, ${c.state}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.textDimColor)),
                              ],
                            ),
                          ])),
                          DataCell(Text(c.subscriptionPlan,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(StatusBadge(status: c.subscriptionStatus)),
                          DataCell(Text('${c.staffCount}')),
                          DataCell(Text('${c.branches}')),
                          DataCell(Text(c.subscriptionEndDate,
                              style: TextStyle(
                                  fontSize: 12, color: context.textMutedColor))),
                          DataCell(TextButton(
                            onPressed: () => _showDetail(c),
                            child: Text('View',
                                style: TextStyle(fontSize: 12)),
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
