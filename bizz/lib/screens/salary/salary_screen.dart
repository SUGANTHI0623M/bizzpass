import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../utils/salary_structure_calculator.dart';
import '../../widgets/bottom_navigation_bar.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final AuthService _authService = AuthService();
  final AttendanceService _attendanceService = AttendanceService();

  bool _isLoading = true;
  String _error = '';

  // Salary data
  double _grossSalary = 0;
  double _netSalary = 0;
  double _thisMonthSalary = 0;
  double _attendancePercentage = 0;

  // Components
  List<Map<String, dynamic>> _components = [];

  @override
  void initState() {
    super.initState();
    _fetchSalaryData();
  }

  Future<void> _fetchSalaryData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Fetch profile to get salary structure
      final profileResult = await _authService.getProfile();
      if (profileResult['success'] != true) {
        throw Exception('Failed to fetch profile');
      }

      final staffData = profileResult['data']?['staffData'];
      if (staffData == null || staffData['salary'] == null) {
        throw Exception('No salary structure found');
      }

      final salaryData = staffData['salary'] as Map<String, dynamic>;

      // Calculate salary structure
      final salaryInputs = SalaryStructureInputs.fromMap(salaryData);
      final calculatedSalary = calculateSalaryStructure(salaryInputs);

      // Fetch attendance for current month
      final now = DateTime.now();
      final attendanceResult = await _attendanceService.getMonthAttendance(
        now.year,
        now.month,
      );

      double presentDays = 0;
      if (attendanceResult['success'] == true) {
        final attendanceData = attendanceResult['data'];
        final records = attendanceData['attendance'] as List? ?? [];
        for (final record in records) {
          final status = (record['status'] as String? ?? '').toLowerCase();
          if (status == 'present' || status == 'approved') {
            presentDays += 1;
          } else if (status == 'half day') {
            presentDays += 0.5;
          }
        }
      }

      // Calculate working days for current month
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      int workingDays = 0;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(now.year, now.month, day);
        if (date.weekday != DateTime.sunday) {
          workingDays++;
        }
      }

      // Calculate attendance percentage
      final attendancePercent =
          workingDays > 0 ? (presentDays / workingDays) * 100 : 0.0;

      // Calculate prorated salary for this month
      final thisMonthGross = workingDays > 0
          ? (calculatedSalary.monthly.grossSalary * presentDays / workingDays)
          : 0.0;

      // Build components list
      final List<Map<String, dynamic>> components = [];

      if (calculatedSalary.monthly.basicSalary > 0) {
        components.add({
          'title': 'Basic Salary',
          'subtitle': 'Salary structure',
          'amount': calculatedSalary.monthly.basicSalary,
          'isDeduction': false,
        });
      }

      if (calculatedSalary.monthly.dearnessAllowance > 0) {
        components.add({
          'title': 'Dearness Allowance',
          'subtitle': 'Monthly allowance',
          'amount': calculatedSalary.monthly.dearnessAllowance,
          'isDeduction': false,
        });
      }

      if (calculatedSalary.monthly.houseRentAllowance > 0) {
        components.add({
          'title': 'House Rent Allowance',
          'subtitle': 'Monthly allowance',
          'amount': calculatedSalary.monthly.houseRentAllowance,
          'isDeduction': false,
        });
      }

      if (calculatedSalary.monthly.specialAllowance > 0) {
        components.add({
          'title': 'Special Allowance',
          'subtitle': 'Monthly allowance',
          'amount': calculatedSalary.monthly.specialAllowance,
          'isDeduction': false,
        });
      }

      if (calculatedSalary.monthly.employeePF > 0) {
        components.add({
          'title': 'Employee PF',
          'subtitle': 'Provident fund',
          'amount': calculatedSalary.monthly.employeePF,
          'isDeduction': true,
        });
      }

      if (calculatedSalary.monthly.employeeESI > 0) {
        components.add({
          'title': 'Employee ESI',
          'subtitle': 'Social security',
          'amount': calculatedSalary.monthly.employeeESI,
          'isDeduction': true,
        });
      }

      setState(() {
        _grossSalary = calculatedSalary.monthly.grossSalary;
        _netSalary = calculatedSalary.monthly.netMonthlySalary;
        _thisMonthSalary = thisMonthGross;
        _attendancePercentage = attendancePercent;
        _components = components;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? _buildErrorState(colors)
                : RefreshIndicator(
                    onRefresh: _fetchSalaryData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Salary',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.cardSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.bar_chart,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Salary Overview Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'SALARY OVERVIEW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Overview Cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _OverviewCard(
                                    label: 'GROSS',
                                    value: _formatCurrency(_grossSalary),
                                    valueColor: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _OverviewCard(
                                    label: 'NET',
                                    value: _formatCurrency(_netSalary),
                                    valueColor: colors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _OverviewCard(
                                    label: 'THIS MONTH',
                                    value: _formatCurrency(_thisMonthSalary),
                                    valueColor: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _OverviewCard(
                                    label: 'ATTEND',
                                    value:
                                        '${_attendancePercentage.toStringAsFixed(0)}%',
                                    valueColor: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Components Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'COMPONENTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Components List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: _components.map((component) {
                                return _ComponentCard(
                                  title: component['title'],
                                  subtitle: component['subtitle'],
                                  amount: component['amount'],
                                  isDeduction: component['isDeduction'],
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildErrorState(AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchSalaryData,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _OverviewCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isDeduction;

  const _ComponentCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDeduction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    String formattedAmount = currencyFormat.format(amount);
    // Shorten if too long
    if (amount >= 1000) {
      formattedAmount = '₹${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDeduction
                  ? const Color(0xFF2D1F3D)
                  : const Color(0xFF1F2D3D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDeduction ? Icons.remove : Icons.add,
              color: isDeduction
                  ? const Color(0xFF9C27B0)
                  : colors.primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDeduction
                  ? const Color(0xFF9C27B0)
                  : colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
