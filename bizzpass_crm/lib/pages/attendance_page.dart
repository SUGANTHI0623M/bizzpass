import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/attendance_repository.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AttendanceRepository _repo = AttendanceRepository();
  List<AttendanceRecord> _attendance = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchTodayAttendance();
      if (mounted) {
        setState(() {
          _attendance = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('AttendanceException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _attendance.where((a) => a.status == 'present').length;
    final late = _attendance.where((a) => a.status == 'late').length;
    final absent = _attendance.where((a) => a.status == 'absent').length;

    if (_loading && _attendance.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Attendance',
              subtitle: "Today's attendance across all companies"),
          LayoutBuilder(builder: (ctx, c) {
            final crossCount = c.maxWidth > 700 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Present',
                    value: '$present',
                    accentColor: AppColors.success.withOpacity(0.12)),
                StatCard(
                    icon: Icons.schedule_rounded,
                    label: 'Late',
                    value: '$late',
                    accentColor: AppColors.warning.withOpacity(0.12)),
                StatCard(
                    icon: Icons.cancel_rounded,
                    label: 'Absent',
                    value: '$absent',
                    accentColor: AppColors.danger.withOpacity(0.12)),
              ],
            );
          }),
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
                              fontSize: 13, color: AppColors.textSecondary))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          AppDataTable(
            columns: const [
              DataCol('Employee'),
              DataCol('Company'),
              DataCol('Punch In'),
              DataCol('Punch Out'),
              DataCol('Status'),
              DataCol('Work Hrs'),
              DataCol('Late (min)'),
            ],
            rows: _attendance
                .map((a) => DataRow(cells: [
                      DataCell(Text(a.employee,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.text))),
                      DataCell(Text(a.company)),
                      DataCell(Text(a.punchIn ?? '—',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: a.punchIn != null
                                ? AppColors.textSecondary
                                : AppColors.textDim,
                          ))),
                      DataCell(Text(a.punchOut ?? '—',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: a.punchOut != null
                                ? AppColors.textSecondary
                                : AppColors.textDim,
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
                          color: a.lateMinutes > 0
                              ? AppColors.warning
                              : AppColors.textDim,
                        ),
                      )),
                    ]))
                .toList(),
          ),
        ],
      ),
    );
  }
}
