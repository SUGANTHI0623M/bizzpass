import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/staff_repository.dart';
import '../data/attendance_repository.dart';
import '../data/visitors_repository.dart';

class CompanyAdminDashboardPage extends StatefulWidget {
  const CompanyAdminDashboardPage({super.key});

  @override
  State<CompanyAdminDashboardPage> createState() =>
      _CompanyAdminDashboardPageState();
}

class _CompanyAdminDashboardPageState extends State<CompanyAdminDashboardPage> {
  final StaffRepository _staffRepo = StaffRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final VisitorsRepository _visitorsRepo = VisitorsRepository();
  int _staffCount = 0;
  int _presentCount = 0;
  int _visitorsCheckedIn = 0;
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
      final staff = await _staffRepo.fetchStaff();
      final attendance = await _attendanceRepo.fetchTodayAttendance();
      final visitors = await _visitorsRepo.fetchVisitors();
      if (mounted) {
        setState(() {
          _staffCount = staff.length;
          _presentCount = attendance
              .where((a) => a.status == 'present' || a.status == 'late')
              .length;
          _visitorsCheckedIn =
              visitors.where((v) => v.status == 'checked_in').length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      final isBackendUnreachable =
          _error!.toLowerCase().contains('cannot reach the backend');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textSecondaryColor)),
              if (isBackendUnreachable) ...[
                const SizedBox(height: 12),
                Text(
                  ApiConstants.backendUnreachableHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Dashboard',
            subtitle: 'Overview of your company',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 700 ? 3 : 1;
              return GridView.count(
                crossAxisCount: crossCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.45,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    icon: Icons.people_rounded,
                    label: 'Total Staff',
                    value: '$_staffCount',
                    sub: 'Employees',
                    accentColor: context.accentColor.withOpacity(0.12),
                  ),
                  StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Present Today',
                    value: '$_presentCount',
                    sub: 'Checked in',
                    accentColor: context.successColor.withOpacity(0.12),
                  ),
                  StatCard(
                    icon: Icons.person_pin_circle_rounded,
                    label: 'Visitors Now',
                    value: '$_visitorsCheckedIn',
                    sub: 'Checked in',
                    accentColor: context.infoColor.withOpacity(0.12),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
