import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/licenses_repository.dart';
import '../data/plans_repository.dart';

class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});
  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  String _search = '';
  String _tab = 'all';
  List<License> _licenses = [];
  bool _loading = true;
  String? _error;
  final LicensesRepository _repo = LicensesRepository();

  @override
  void initState() {
    super.initState();
    _loadLicenses();
  }

  Future<void> _loadLicenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchLicenses(
        search: _search.isEmpty ? null : _search,
        tab: _tab,
      );
      setState(() {
        _licenses = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _licenses = [];
        _loading = false;
        _error = e.toString().replaceAll('LicensesException: ', '');
      });
    }
  }

  List<License> get _filtered {
    if (_search.isEmpty) return _licenses;
    final s = _search.toLowerCase();
    return _licenses.where((l) {
      return (l.licenseKey.toLowerCase().contains(s)) ||
          ((l.company ?? '').toLowerCase().contains(s));
    }).toList();
  }

  void _showViewLicense(License l) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.licenseKey,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: l.licenseKey));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('License key copied'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded,
                                  size: 18, color: AppColors.textMuted),
                              tooltip: 'Copy license key',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(32, 32),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: AppColors.textMuted),
                        style: IconButton.styleFrom(
                            backgroundColor: AppColors.cardHover),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          DetailTile(label: 'COMPANY', value: l.company ?? '—'),
                          DetailTile(label: 'PLAN', value: l.plan),
                          DetailTile(
                              label: 'MAX USERS', value: '${l.maxUsers}'),
                          DetailTile(
                              label: 'STATUS',
                              value: l.status,
                              valueColor: AppColors.info),
                          DetailTile(
                              label: 'VALID FROM', value: l.validFrom ?? '—'),
                          DetailTile(
                              label: 'VALID UNTIL', value: l.validUntil ?? '—'),
                          DetailTile(
                              label: 'TRIAL', value: l.isTrial ? 'Yes' : 'No'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEditLicenseDialog(l);
                            },
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 10),
                          if (l.status != 'revoked')
                            TextButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: AppColors.bg,
                                    title: const Text('Revoke license?'),
                                    content: const Text(
                                      'This will revoke the license. The company will no longer be able to use it.',
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Revoke',
                                            style: TextStyle(
                                                color: AppColors.danger)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && ctx.mounted) {
                                  try {
                                    await _repo.deleteLicense(l.id);
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      _loadLicenses();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('License revoked'),
                                            backgroundColor: AppColors.success),
                                      );
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceAll(
                                              'LicensesException: ', '')),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger),
                              child: const Text('Revoke'),
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

  void _showEditLicenseDialog(License l) {
    final maxUsersCtrl = TextEditingController(text: '${l.maxUsers}');
    final maxBranchesCtrl = TextEditingController(text: '1');
    String selectedStatus = l.status;
    final notesCtrl = TextEditingController();
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit License',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text)),
                        IconButton(
                          onPressed:
                              submitting ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: AppColors.textMuted),
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.cardHover),
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
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(submitError!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.danger))),
                              ],
                            ),
                          ),
                        ],
                        FormFieldWrapper(
                          label: 'MAX USERS',
                          child: TextFormField(
                            controller: maxUsersCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'STATUS',
                          child: DropdownButtonFormField<String>(
                            value: selectedStatus,
                            decoration: const InputDecoration(),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                            items: const [
                              DropdownMenuItem(
                                  value: 'unassigned',
                                  child: Text('Unassigned')),
                              DropdownMenuItem(
                                  value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'expired', child: Text('Expired')),
                              DropdownMenuItem(
                                  value: 'suspended', child: Text('Suspended')),
                              DropdownMenuItem(
                                  value: 'revoked', child: Text('Revoked')),
                            ],
                            onChanged: (v) => setDialogState(
                                () => selectedStatus = v ?? l.status),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'NOTES',
                          child: TextFormField(
                            controller: notesCtrl,
                            maxLines: 2,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                            decoration:
                                const InputDecoration(hintText: 'Optional'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final maxUsers = int.tryParse(
                                              maxUsersCtrl.text.trim()) ??
                                          l.maxUsers;
                                      if (maxUsers < 1) {
                                        setDialogState(() => submitError =
                                            'Max users must be at least 1');
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        await _repo.updateLicense(
                                          l.id,
                                          maxUsers: maxUsers,
                                          status: selectedStatus,
                                          notes: notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadLicenses();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('License updated'),
                                                backgroundColor:
                                                    AppColors.success),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'LicensesException: ', '');
                                        });
                                      }
                                    },
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Save'),
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

  Future<void> _showCreateDialog() async {
    List<Plan> plans = [];
    try {
      plans = await PlansRepository().fetchPlans(activeOnly: true);
    } catch (_) {}
    if (!mounted) return;

    final maxUsersCtrl = TextEditingController(text: '25');
    final maxBranchesCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    String selectedPlan = plans.isNotEmpty ? plans.first.planCode : 'starter';
    bool isTrial = false;
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Create New License',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            )),
                        IconButton(
                          onPressed:
                              submitting ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: AppColors.textMuted),
                          style: IconButton.styleFrom(
                              backgroundColor: AppColors.cardHover),
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
                              color: AppColors.danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    submitError!,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.danger),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        FormFieldWrapper(
                          label: 'SUBSCRIPTION PLAN',
                          child: DropdownButtonFormField<String>(
                            value: plans.isNotEmpty
                                ? (plans.any((p) => p.planCode == selectedPlan)
                                    ? selectedPlan
                                    : plans.first.planCode)
                                : selectedPlan,
                            decoration: const InputDecoration(),
                            dropdownColor: AppColors.card,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                            items: plans.isNotEmpty
                                ? plans
                                    .map((p) => DropdownMenuItem<String>(
                                          value: p.planCode,
                                          child: Text(
                                              '${p.planName} — ₹${fmtNumber(p.price)}/yr'),
                                        ))
                                    .toList()
                                : const [
                                    DropdownMenuItem(
                                        value: 'starter',
                                        child: Text('Starter — ₹19,999/yr')),
                                    DropdownMenuItem(
                                        value: 'professional',
                                        child:
                                            Text('Professional — ₹59,999/yr')),
                                    DropdownMenuItem(
                                        value: 'enterprise',
                                        child:
                                            Text('Enterprise — ₹1,49,999/yr')),
                                  ],
                            onChanged: (v) => setDialogState(() =>
                                selectedPlan = v ??
                                    (plans.isNotEmpty
                                        ? plans.first.planCode
                                        : 'starter')),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX USERS',
                                child: TextFormField(
                                  controller: maxUsersCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.text),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX BRANCHES',
                                child: TextFormField(
                                  controller: maxBranchesCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                        FormFieldWrapper(
                          label: 'TRIAL LICENSE',
                          child: Row(
                            children: [
                              Checkbox(
                                value: isTrial,
                                onChanged: (v) =>
                                    setDialogState(() => isTrial = v ?? false),
                                activeColor: AppColors.accent,
                              ),
                              const Text('Yes, this is a trial license',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'NOTES',
                          child: TextFormField(
                            controller: notesCtrl,
                            maxLines: 3,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.text),
                            decoration: const InputDecoration(
                                hintText: 'Optional internal notes...'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final maxUsers = int.tryParse(
                                              maxUsersCtrl.text.trim()) ??
                                          25;
                                      final maxBranches = int.tryParse(
                                              maxBranchesCtrl.text.trim()) ??
                                          1;
                                      if (maxUsers < 1 || maxBranches < 1) {
                                        setDialogState(() => submitError =
                                            'Max users and branches must be at least 1');
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        await _repo.createLicense(
                                          subscriptionPlan: selectedPlan,
                                          maxUsers: maxUsers,
                                          maxBranches: maxBranches,
                                          isTrial: isTrial,
                                          notes: notesCtrl.text.trim().isEmpty
                                              ? null
                                              : notesCtrl.text.trim(),
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadLicenses();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'License created successfully'),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'LicensesException: ', '');
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
                                  : const Text('Generate License'),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Licenses',
            subtitle: 'Create and manage license keys',
            actionLabel: 'Create License',
            actionIcon: Icons.add_rounded,
            onAction: _showCreateDialog,
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
                  TextButton(
                      onPressed: _loadLicenses, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: _licenses.length),
              TabItem(
                  id: 'active',
                  label: 'Active',
                  count: _licenses.where((l) => l.status == 'active').length),
              TabItem(
                  id: 'unassigned',
                  label: 'Unassigned',
                  count:
                      _licenses.where((l) => l.status == 'unassigned').length),
              TabItem(
                  id: 'expired',
                  label: 'Expired',
                  count: _licenses.where((l) => l.status == 'expired').length),
              TabItem(
                  id: 'suspended',
                  label: 'Suspended',
                  count: _licenses
                      .where((l) =>
                          l.status == 'suspended' || l.status == 'revoked')
                      .length),
            ],
            active: _tab,
            onChanged: (v) => setState(() {
              _tab = v;
              _loadLicenses();
            }),
          ),
          AppSearchBar(
              hint: 'Search by license key or company...',
              onChanged: (v) => setState(() {
                    _search = v;
                    if (v.isEmpty) _loadLicenses();
                  })),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else
            AppDataTable(
              columns: const [
                DataCol('License Key'),
                DataCol('Company'),
                DataCol('Plan'),
                DataCol('Max Users'),
                DataCol('Status'),
                DataCol('Valid Until'),
                DataCol('Trial'),
                DataCol(''),
              ],
              rows: filtered
                  .map((l) => DataRow(
                        onSelectChanged: (_) => _showViewLicense(l),
                        cells: [
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.licenseKey,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  )),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Copy license key',
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: l.licenseKey));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('License key copied'),
                                        backgroundColor: AppColors.success,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.copy_rounded,
                                        size: 16, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ],
                          )),
                          DataCell(Text(l.company ?? '—',
                              style: TextStyle(
                                color: l.company != null
                                    ? AppColors.textSecondary
                                    : AppColors.textDim,
                                fontStyle: l.company == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ))),
                          DataCell(Text(l.plan,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text('${l.maxUsers}')),
                          DataCell(StatusBadge(status: l.status)),
                          DataCell(Text(l.validUntil ?? '—',
                              style:
                                  const TextStyle(color: AppColors.textMuted))),
                          DataCell(l.isTrial
                              ? const Text('TRIAL',
                                  style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11))
                              : const Text('—',
                                  style: TextStyle(color: AppColors.textDim))),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                  onPressed: () => _showViewLicense(l),
                                  child: const Text('View',
                                      style: TextStyle(fontSize: 12))),
                              TextButton(
                                  onPressed: () => _showEditLicenseDialog(l),
                                  child: const Text('Edit',
                                      style: TextStyle(fontSize: 12))),
                              if (l.status != 'revoked')
                                TextButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: AppColors.bg,
                                        title: const Text('Revoke license?'),
                                        content: const Text(
                                            'This will revoke the license.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('Cancel')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('Revoke',
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.danger))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _repo.deleteLicense(l.id);
                                        _loadLicenses();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('License revoked'),
                                                backgroundColor:
                                                    AppColors.success),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(e
                                                    .toString()
                                                    .replaceAll(
                                                        'LicensesException: ',
                                                        '')),
                                                backgroundColor:
                                                    AppColors.danger),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: const Text('Revoke',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.danger)),
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
