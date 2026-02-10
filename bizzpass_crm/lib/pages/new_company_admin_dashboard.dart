import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../data/company_dashboard_repository.dart';

class NewCompanyAdminDashboard extends StatefulWidget {
  const NewCompanyAdminDashboard({super.key});

  @override
  State<NewCompanyAdminDashboard> createState() => _NewCompanyAdminDashboardState();
}

class _NewCompanyAdminDashboardState extends State<NewCompanyAdminDashboard> {
  final CompanyDashboardRepository _repo = CompanyDashboardRepository();
  
  // Data
  DashboardOverview? _overview;
  List<Birthday> _birthdays = [];
  List<Holiday> _holidays = [];
  List<Shift> _shifts = [];
  List<LeaveBalance> _leaves = [];
  List<ApprovalRequest> _approvalRequests = [];
  List<Announcement> _announcements = [];
  Map<String, dynamic> _expenses = {};
  
  bool _loading = true;
  String? _error;
  String _selectedApprovalTab = 'attendance';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repo.fetchOverview(),
        _repo.fetchBirthdays(),
        _repo.fetchUpcomingHolidays(),
        _repo.fetchShiftSchedule(),
        _repo.fetchMyLeaves(),
        _repo.fetchApprovalRequests(type: _selectedApprovalTab),
        _repo.fetchAnnouncements(),
        _repo.fetchTotalExpenses(),
      ]);

      if (mounted) {
        setState(() {
          _overview = results[0] as DashboardOverview;
          _birthdays = results[1] as List<Birthday>;
          _holidays = results[2] as List<Holiday>;
          _shifts = results[3] as List<Shift>;
          _leaves = results[4] as List<LeaveBalance>;
          _approvalRequests = results[5] as List<ApprovalRequest>;
          _announcements = results[6] as List<Announcement>;
          _expenses = results[7] as Map<String, dynamic>;
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

  Future<void> _loadApprovalRequests(String type) async {
    try {
      final requests = await _repo.fetchApprovalRequests(type: type);
      if (mounted) {
        setState(() {
          _selectedApprovalTab = type;
          _approvalRequests = requests;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _overview == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _overview == null) {
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
              TextButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final overview = _overview!;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(overview, now),
            const SizedBox(height: 24),

            // Main Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildEmployeeAnalytics(overview),
                      const SizedBox(height: 20),
                      _buildOverallEmployees(overview),
                      const SizedBox(height: 20),
                      _buildCelebrationCorner(),
                      const SizedBox(height: 20),
                      _buildTodayStats(overview),
                      const SizedBox(height: 20),
                      _buildUpcomingHolidays(),
                      const SizedBox(height: 20),
                      _buildShiftSchedule(),
                      const SizedBox(height: 20),
                      _buildTotalExpenses(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildMyLeaves(),
                      const SizedBox(height: 20),
                      _buildApprovalRequests(),
                      const SizedBox(height: 20),
                      _buildAnnouncements(),
                      const SizedBox(height: 20),
                      _buildPayslips(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallEmployees(DashboardOverview overview) {
    final analytics = overview.employeeAnalytics;
    final hired = analytics.active;
    final exits = analytics.exits;
    final total = analytics.total;

    return _dashboardCard(
      title: 'Overall Employees',
      child: Row(
        children: [
          // Circular Chart
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _CircularChartPainter(
                value: total,
                hired: hired,
                exits: exits,
                borderColor: context.borderColor,
                successColor: context.successColor,
                dangerColor: context.dangerColor,
              ),
              child: Center(
                child: Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('Hired', hired, context.successColor),
                const SizedBox(height: 8),
                _legendItem('Exits', exits, context.dangerColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
        ),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCelebrationCorner() {
    return _dashboardCard(
      title: 'Celebration Corner',
      action: Icon(Icons.cake_rounded, color: context.warningColor, size: 20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.celebration_rounded, color: context.warningColor, size: 16),
              const SizedBox(width: 8),
              const Text('Birthday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _birthdays.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No upcoming birthdays', style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                )
              : Column(
                  children: _birthdays.take(3).map((birthday) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: context.warningColor.withOpacity(0.1),
                            child: Text(
                              birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?',
                              style: TextStyle(color: context.warningColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(birthday.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(birthday.designation, style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                              ],
                            ),
                          ),
                          Text(
                            birthday.daysUntil == 0 ? 'Today!' : '${birthday.daysUntil}d',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: birthday.daysUntil == 0 ? context.warningColor : context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildTotalExpenses() {
    final totalExpenses = _expenses['totalExpenses'] as num? ?? 0;
    final currency = _expenses['currency'] as String? ?? 'INR';

    return _dashboardCard(
      title: 'Total Expenses',
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              progress: 0.0, // Can calculate based on budget if available
              color: context.infoColor,
              borderColor: context.borderColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currency,
                    style: TextStyle(fontSize: 12, color: context.textMutedColor),
                  ),
                  Text(
                    '${totalExpenses.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
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

  Widget _buildPayslips() {
    return _dashboardCard(
      title: 'Payslips',
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.insert_drive_file_rounded, size: 48, color: context.textMutedColor.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('No Payslips Found', style: TextStyle(color: context.textMutedColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(DashboardOverview overview, DateTime now) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Vasantha Kumar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have ${overview.pendingRequests} requests pending',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Let's Get To Work",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tuesday, ${DateFormat('MMM d, yyyy').format(now)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _actionButton('Check Out', Icons.logout_rounded, Colors.white, context.accentColor),
                  const SizedBox(width: 12),
                  _actionButton('Start Over Time', Icons.access_time_rounded, context.accentColor, Colors.white),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color bgColor, Color textColor) {
    return ElevatedButton.icon(
      onPressed: () {
        // Handle action
      },
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildEmployeeAnalytics(DashboardOverview overview) {
    final analytics = overview.employeeAnalytics;
    return _dashboardCard(
      title: 'Employee Analytics',
      subtitle: 'Feb - 2026',
      child: Row(
        children: [
          Expanded(
            child: _miniStatCard(
              label: 'Active',
              value: '${analytics.active}',
              icon: Icons.people_outline_rounded,
              color: context.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniStatCard(
              label: 'Hired',
              value: '${analytics.hired}',
              icon: Icons.person_add_outlined,
              color: context.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniStatCard(
              label: 'Exits',
              value: '${analytics.exits}',
              icon: Icons.person_remove_outlined,
              color: context.dangerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(DashboardOverview overview) {
    final attendance = overview.todayAttendance;
    return _dashboardCard(
      title: 'Today',
      child: Row(
        children: [
          Expanded(
            child: _miniStatCard(
              label: 'Present',
              value: '${attendance.present}',
              icon: Icons.check_circle_outline_rounded,
              color: context.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniStatCard(
              label: 'Absent',
              value: '${attendance.absent}',
              icon: Icons.cancel_outlined,
              color: context.dangerColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniStatCard(
              label: 'On Leave',
              value: '${attendance.onLeave}',
              icon: Icons.event_busy_outlined,
              color: context.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingHolidays() {
    return _dashboardCard(
      title: 'Upcoming Holidays',
      action: TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(fontSize: 12)),
      ),
      child: _holidays.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No upcoming holidays', style: TextStyle(color: context.textMutedColor)),
              ),
            )
          : Column(
              children: _holidays.map((holiday) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.event_rounded, color: context.accentColor, size: 20),
                  ),
                  title: Text(holiday.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(holiday.date, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  trailing: Text('${holiday.daysUntil} days', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildShiftSchedule() {
    return _dashboardCard(
      title: 'Shift Schedule',
      child: _shifts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No shifts scheduled', style: TextStyle(color: context.textMutedColor)),
              ),
            )
          : Column(
              children: _shifts.map((shift) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.schedule_rounded, color: context.infoColor, size: 20),
                  ),
                  title: Text(shift.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${shift.startTime} - ${shift.endTime}', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                  trailing: Text('${shift.staffCount} staff', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMyLeaves() {
    return _dashboardCard(
      title: 'My Leaves',
      child: _leaves.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No leave data available',
                  style: TextStyle(color: context.textMutedColor),
                ),
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _leaves.map((leave) {
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: context.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.event_available_rounded, color: context.accentColor, size: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${leave.available}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.successColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        leave.type,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${leave.available} Days',
                        style: TextStyle(fontSize: 11, color: context.textMutedColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildApprovalRequests() {
    return _dashboardCard(
      title: 'Approval Requests',
      child: Column(
        children: [
          // Tabs
          Row(
            children: [
              _approvalTab('Attendance', 'attendance'),
              _approvalTab('Overtime', 'overtime'),
              _approvalTab('Expenses', 'expenses'),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          _approvalRequests.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.search_rounded, size: 48, color: context.textMutedColor.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('No Approval Requests', style: TextStyle(color: context.textMutedColor)),
                    ],
                  ),
                )
              : Column(
                  children: _approvalRequests.map((request) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: context.accentColor.withOpacity(0.1),
                        child: Text(
                          request.staffName.isNotEmpty ? request.staffName[0].toUpperCase() : '?',
                          style: TextStyle(color: context.accentColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(request.staffName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('${request.date} • ${request.checkIn ?? ""} - ${request.checkOut ?? ""}', style: TextStyle(fontSize: 11, color: context.textMutedColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle_rounded, color: context.successColor, size: 20),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel_rounded, color: context.dangerColor, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _approvalTab(String label, String type) {
    final isSelected = _selectedApprovalTab == type;
    return GestureDetector(
      onTap: () => _loadApprovalRequests(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? context.accentColor : context.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return _dashboardCard(
      title: 'Announcements',
      child: _announcements.isEmpty
          ? Container(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.campaign_rounded, size: 48, color: context.textMutedColor.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text('No Announcements Found', style: TextStyle(color: context.textMutedColor)),
                ],
              ),
            )
          : Column(
              children: _announcements.map((announcement) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            announcement.date,
                            style: TextStyle(fontSize: 11, color: context.textMutedColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.message,
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _dashboardCard({
    required String title,
    String? subtitle,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: context.textMutedColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Circular Employee Chart
class _CircularChartPainter extends CustomPainter {
  final int value;
  final int hired;
  final int exits;
  final Color borderColor;
  final Color successColor;
  final Color dangerColor;

  _CircularChartPainter({
    required this.value,
    required this.hired,
    required this.exits,
    required this.borderColor,
    required this.successColor,
    required this.dangerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // Calculate percentages
    final total = hired + exits;
    if (total == 0) return;

    final hiredAngle = (hired / total) * 2 * math.pi;
    final exitsAngle = (exits / total) * 2 * math.pi;

    // Hired arc (green)
    final hiredPaint = Paint()
      ..color = successColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      hiredAngle,
      false,
      hiredPaint,
    );

    // Exits arc (red)
    final exitsPaint = Paint()
      ..color = dangerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + hiredAngle,
      exitsAngle,
      false,
      exitsPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for Circular Progress (Expenses)
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color borderColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

