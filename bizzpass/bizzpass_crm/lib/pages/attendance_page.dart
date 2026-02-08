import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final present = attendanceToday.where((a) => a.status == 'present').length;
    final late = attendanceToday.where((a) => a.status == 'late').length;
    final absent = attendanceToday.where((a) => a.status == 'absent').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Attendance', subtitle: "Today's attendance across all companies"),

          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14, crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(icon: Icons.check_circle_rounded, label: 'Present', value: '$present', accentColor: AppColors.success.withOpacity(0.12)),
                StatCard(icon: Icons.schedule_rounded, label: 'Late', value: '$late', accentColor: AppColors.warning.withOpacity(0.12)),
                StatCard(icon: Icons.cancel_rounded, label: 'Absent', value: '$absent', accentColor: AppColors.danger.withOpacity(0.12)),
              ],
            );
          }),

          const SizedBox(height: 24),
          AppDataTable(
            columns: const [
              DataCol('Employee'), DataCol('Company'), DataCol('Punch In'),
              DataCol('Punch Out'), DataCol('Status'), DataCol('Work Hrs'), DataCol('Late (min)'),
            ],
            rows: attendanceToday.map((a) => DataRow(cells: [
              DataCell(Text(a.employee, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text))),
              DataCell(Text(a.company)),
              DataCell(Text(a.punchIn ?? '—', style: TextStyle(
                fontFamily: 'monospace', color: a.punchIn != null ? AppColors.textSecondary : AppColors.textDim,
              ))),
              DataCell(Text(a.punchOut ?? '—', style: TextStyle(
                fontFamily: 'monospace', color: a.punchOut != null ? AppColors.textSecondary : AppColors.textDim,
              ))),
              DataCell(StatusBadge(status: a.status)),
              DataCell(Text(
                a.workHours > 0 ? a.workHours.toStringAsFixed(1) : '—',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
              DataCell(Text(
                '${a.lateMinutes}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: a.lateMinutes > 0 ? AppColors.warning : AppColors.textDim,
                ),
              )),
            ])).toList(),
          ),
        ],
      ),
    );
  }
}
