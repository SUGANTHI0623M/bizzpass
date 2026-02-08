import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});
  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  String _search = '';
  String _tab = 'all';

  List<Company> get _filtered {
    return companies.where((c) {
      final matchSearch = c.name.toLowerCase().contains(_search.toLowerCase()) ||
          c.city.toLowerCase().contains(_search.toLowerCase());
      switch (_tab) {
        case 'active': return matchSearch && c.isActive;
        case 'inactive': return matchSearch && !c.isActive;
        case 'expiring': return matchSearch && c.subscriptionStatus == 'expiring_soon';
        default: return matchSearch;
      }
    }).toList();
  }

  void _showDetail(Company c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      AvatarCircle(name: c.name, seed: c.id, size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text,
                            )),
                            Text('${c.city}, ${c.state}', style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted,
                            )),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                        style: IconButton.styleFrom(backgroundColor: AppColors.cardHover),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _gridWrap([
                        DetailTile(label: 'EMAIL', value: c.email),
                        DetailTile(label: 'PHONE', value: c.phone),
                        DetailTile(label: 'LICENSE KEY', value: c.licenseKey, mono: true, valueColor: AppColors.accent),
                        DetailTile(label: 'PLAN', value: c.subscriptionPlan),
                      ]),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: InfoMetric(label: 'Staff', value: '${c.staffCount}')),
                          const SizedBox(width: 12),
                          Expanded(child: InfoMetric(label: 'Branches', value: '${c.branches}')),
                          const SizedBox(width: 12),
                          Expanded(child: InfoMetric(
                            label: 'Active',
                            value: c.isActive ? 'Yes' : 'No',
                            valueColor: c.isActive ? AppColors.success : AppColors.danger,
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Spacer(),
                          StatusBadge(status: c.subscriptionStatus, large: true),
                          const SizedBox(width: 8),
                          Text('Expires: ${c.subscriptionEndDate}', style: const TextStyle(
                            fontSize: 12, color: AppColors.textDim,
                          )),
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

  Widget _gridWrap(List<Widget> children) {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: children.map((c) => SizedBox(width: 250, child: c)).toList(),
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
            title: 'Companies',
            subtitle: '${companies.length} registered companies',
            actionLabel: 'Add Company', actionIcon: Icons.add_rounded,
            onAction: () {},
          ),
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: companies.length),
              TabItem(id: 'active', label: 'Active', count: companies.where((c) => c.isActive).length),
              TabItem(id: 'inactive', label: 'Inactive', count: companies.where((c) => !c.isActive).length),
              TabItem(id: 'expiring', label: 'Expiring', count: companies.where((c) => c.subscriptionStatus == 'expiring_soon').length),
            ],
            active: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          AppSearchBar(hint: 'Search companies...', onChanged: (v) => setState(() => _search = v)),
          AppDataTable(
            columns: const [
              DataCol('Company'), DataCol('Plan'), DataCol('Status'),
              DataCol('Staff'), DataCol('Branches'), DataCol('Expires'), DataCol(''),
            ],
            rows: filtered.map((c) => DataRow(
              onSelectChanged: (_) => _showDetail(c),
              cells: [
                DataCell(Row(children: [
                  AvatarCircle(name: c.name, seed: c.id),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                      Text('${c.city}, ${c.state}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                    ],
                  ),
                ])),
                DataCell(Text(c.subscriptionPlan, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(StatusBadge(status: c.subscriptionStatus)),
                DataCell(Text('${c.staffCount}')),
                DataCell(Text('${c.branches}')),
                DataCell(Text(c.subscriptionEndDate, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                DataCell(TextButton(
                  onPressed: () => _showDetail(c),
                  child: const Text('View', style: TextStyle(fontSize: 12)),
                )),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}
