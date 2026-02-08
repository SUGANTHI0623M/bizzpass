import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Notifications', subtitle: 'Delivery tracking for all notifications'),
          AppDataTable(
            columns: const [
              DataCol(''), DataCol('Title'), DataCol('Company'),
              DataCol('Type'), DataCol('Channel'), DataCol('Status'), DataCol('Date'),
            ],
            rows: notifications.map((n) => DataRow(cells: [
              DataCell(PriorityDot(priority: n.priority)),
              DataCell(Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text))),
              DataCell(Text(n.company)),
              DataCell(Text(
                n.type.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5),
              )),
              DataCell(Text(_capitalize(n.channel.replaceAll('_', ' ')))),
              DataCell(StatusBadge(status: n.status)),
              DataCell(Text(n.createdAt)),
            ])).toList(),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
