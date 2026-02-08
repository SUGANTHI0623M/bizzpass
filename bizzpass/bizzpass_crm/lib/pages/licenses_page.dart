import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});
  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  String _search = '';
  String _tab = 'all';

  List<License> get _filtered {
    return licenses.where((l) {
      final matchSearch = l.licenseKey.toLowerCase().contains(_search.toLowerCase()) ||
          (l.company ?? '').toLowerCase().contains(_search.toLowerCase());
      switch (_tab) {
        case 'active': return matchSearch && l.status == 'active';
        case 'expired': return matchSearch && l.status == 'expired';
        case 'unassigned': return matchSearch && l.status == 'unassigned';
        case 'suspended': return matchSearch && (l.status == 'suspended' || l.status == 'revoked');
        default: return matchSearch;
      }
    }).toList();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Create New License', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text,
                      )),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                        style: IconButton.styleFrom(backgroundColor: AppColors.cardHover),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      FormFieldWrapper(
                        label: 'SUBSCRIPTION PLAN',
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(),
                          dropdownColor: AppColors.card,
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          items: const [
                            DropdownMenuItem(value: 'starter', child: Text('Starter — ₹19,999/yr')),
                            DropdownMenuItem(value: 'professional', child: Text('Professional — ₹59,999/yr')),
                            DropdownMenuItem(value: 'enterprise', child: Text('Enterprise — ₹1,49,999/yr')),
                          ],
                          onChanged: (_) {},
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: FormFieldWrapper(
                              label: 'MAX USERS',
                              child: TextFormField(
                                initialValue: '25',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, color: AppColors.text),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: FormFieldWrapper(
                              label: 'MAX BRANCHES',
                              child: TextFormField(
                                initialValue: '1',
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 13, color: AppColors.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                      FormFieldWrapper(
                        label: 'TRIAL LICENSE',
                        child: Row(
                          children: [
                            Checkbox(value: false, onChanged: (_) {}, activeColor: AppColors.accent),
                            const Text('Yes, this is a trial license', style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary,
                            )),
                          ],
                        ),
                      ),
                      FormFieldWrapper(
                        label: 'NOTES',
                        child: TextFormField(
                          maxLines: 3,
                          style: const TextStyle(fontSize: 13, color: AppColors.text),
                          decoration: const InputDecoration(hintText: 'Optional internal notes...'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Generate License'),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
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
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: licenses.length),
              TabItem(id: 'active', label: 'Active', count: licenses.where((l) => l.status == 'active').length),
              TabItem(id: 'unassigned', label: 'Unassigned', count: licenses.where((l) => l.status == 'unassigned').length),
              TabItem(id: 'expired', label: 'Expired', count: licenses.where((l) => l.status == 'expired').length),
              TabItem(id: 'suspended', label: 'Suspended', count: licenses.where((l) => l.status == 'suspended' || l.status == 'revoked').length),
            ],
            active: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          AppSearchBar(hint: 'Search by license key or company...', onChanged: (v) => setState(() => _search = v)),
          AppDataTable(
            columns: const [
              DataCol('License Key'), DataCol('Company'), DataCol('Plan'),
              DataCol('Max Users'), DataCol('Status'), DataCol('Valid Until'), DataCol('Trial'),
            ],
            rows: filtered.map((l) => DataRow(cells: [
              DataCell(Text(l.licenseKey, style: const TextStyle(
                fontFamily: 'monospace', fontWeight: FontWeight.w600,
                color: AppColors.accent, fontSize: 12, letterSpacing: 0.5,
              ))),
              DataCell(Text(l.company ?? '—', style: TextStyle(
                color: l.company != null ? AppColors.textSecondary : AppColors.textDim,
                fontStyle: l.company == null ? FontStyle.italic : FontStyle.normal,
              ))),
              DataCell(Text(l.plan, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text('${l.maxUsers}')),
              DataCell(StatusBadge(status: l.status)),
              DataCell(Text(l.validUntil ?? '—', style: const TextStyle(color: AppColors.textMuted))),
              DataCell(l.isTrial
                ? const Text('TRIAL', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 11))
                : const Text('—', style: TextStyle(color: AppColors.textDim))),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
