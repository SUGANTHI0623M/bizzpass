import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});
  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  String _search = '';
  String _tab = 'all';

  List<Staff> get _filtered {
    return staffData.where((s) {
      final matchSearch = s.name.toLowerCase().contains(_search.toLowerCase()) ||
          s.company.toLowerCase().contains(_search.toLowerCase()) ||
          s.department.toLowerCase().contains(_search.toLowerCase());
      switch (_tab) {
        case 'active': return matchSearch && s.status == 'active';
        case 'inactive': return matchSearch && s.status == 'inactive';
        default: return matchSearch;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Staff', subtitle: '${staffData.length} employees across all companies'),
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: staffData.length),
              TabItem(id: 'active', label: 'Active', count: staffData.where((s) => s.status == 'active').length),
              TabItem(id: 'inactive', label: 'Inactive', count: staffData.where((s) => s.status == 'inactive').length),
            ],
            active: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          AppSearchBar(hint: 'Search by name, company, or department...', onChanged: (v) => setState(() => _search = v)),
          AppDataTable(
            columns: const [
              DataCol('Employee'), DataCol('Company'), DataCol('Designation'),
              DataCol('Department'), DataCol('Status'), DataCol('Joined'),
            ],
            rows: filtered.map((s) => DataRow(cells: [
              DataCell(Row(children: [
                AvatarCircle(name: s.name, seed: s.id, round: true),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                    Text(s.employeeId, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                  ],
                ),
              ])),
              DataCell(Text(s.company)),
              DataCell(Text(s.designation)),
              DataCell(Text(s.department)),
              DataCell(StatusBadge(status: s.status)),
              DataCell(Text(s.joiningDate)),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
