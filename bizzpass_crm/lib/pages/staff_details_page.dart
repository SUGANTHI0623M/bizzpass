import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/staff_repository.dart';

/// Tab id for staff details. No Loan tab.
enum _StaffDetailsTab {
  profile,
  attendance,
  salary,
  leaves,
  documents,
  expenseClaim,
  payslipRequests,
}

/// Full-page staff details with switch tabs. Shown when user clicks view (eye) on a staff member.
class StaffDetailsPage extends StatefulWidget {
  final int staffId;
  final Staff? initialStaff;
  final VoidCallback? onBack;
  final void Function(Staff)? onEdit;
  final void Function()? onStaffUpdated;

  const StaffDetailsPage({
    super.key,
    required this.staffId,
    this.initialStaff,
    this.onBack,
    this.onEdit,
    this.onStaffUpdated,
  });

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> {
  final StaffRepository _repo = StaffRepository();
  Staff? _staff;
  bool _loading = true;
  String? _error;
  _StaffDetailsTab _selectedTab = _StaffDetailsTab.profile;

  @override
  void initState() {
    super.initState();
    _staff = widget.initialStaff;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _repo.getStaff(widget.staffId);
      if (mounted) {
        setState(() {
          _staff = s;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('StaffException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_loading && _staff == null)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: _buildError(),
            )
          else if (_staff != null)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTabMenu(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildTabContent(_staff!),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
              widget.onStaffUpdated?.call();
            },
            icon: Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SectionHeader(
              title: 'Staff Details',
              subtitle: _staff?.name ?? 'Employee',
            ),
          ),
          if (_staff != null && widget.onEdit != null)
            TextButton.icon(
              onPressed: () => widget.onEdit!(_staff!),
              icon: Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.dangerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dangerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
                Icon(Icons.error_outline_rounded,
                color: context.dangerColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
    final tabs = [
      (_StaffDetailsTab.profile, Icons.person_outline_rounded, 'Profile'),
      (_StaffDetailsTab.attendance, Icons.schedule_rounded, 'Attendance'),
      (_StaffDetailsTab.salary, Icons.attach_money_rounded, 'Salary'),
      (_StaffDetailsTab.leaves, Icons.calendar_today_rounded, 'Leaves'),
      (_StaffDetailsTab.documents, Icons.description_outlined, 'Documents'),
      (_StaffDetailsTab.expenseClaim, Icons.receipt_long_rounded, 'Expense Claim'),
      (_StaffDetailsTab.payslipRequests, Icons.request_page_rounded, 'Payslip Requests'),
    ];
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          right: BorderSide(color: context.borderColor),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: tabs
            .map(
              (t) => ListTile(
                leading: Icon(
                  t.$2,
                  size: 22,
                  color: _selectedTab == t.$1
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
                title: Text(
                  t.$3,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _selectedTab == t.$1 ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedTab == t.$1
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
                selected: _selectedTab == t.$1,
                onTap: () => setState(() => _selectedTab = t.$1),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabContent(Staff staff) {
    switch (_selectedTab) {
      case _StaffDetailsTab.profile:
        return _buildProfileContent(staff);
      case _StaffDetailsTab.attendance:
        return _buildPlaceholderContent(
          icon: Icons.schedule_rounded,
          title: 'Attendance',
          message: 'Attendance records will appear here.',
        );
      case _StaffDetailsTab.salary:
        return _buildSalaryContent(staff);
      case _StaffDetailsTab.leaves:
        return _buildPlaceholderContent(
          icon: Icons.calendar_today_rounded,
          title: 'Leaves',
          message: 'Leave balance and requests will appear here.',
        );
      case _StaffDetailsTab.documents:
        return _buildPlaceholderContent(
          icon: Icons.description_outlined,
          title: 'Documents',
          message: 'Staff documents will appear here.',
        );
      case _StaffDetailsTab.expenseClaim:
        return _buildPlaceholderContent(
          icon: Icons.receipt_long_rounded,
          title: 'Expense Claim',
          message: 'Expense claims will appear here.',
        );
      case _StaffDetailsTab.payslipRequests:
        return _buildPlaceholderContent(
          icon: Icons.request_page_rounded,
          title: 'Payslip Requests',
          message: 'Payslip requests will appear here.',
        );
    }
  }

  Widget _buildProfileContent(Staff staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarCircle(name: staff.name, seed: staff.id, round: true),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.designation,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    if (staff.department.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        staff.department,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textMutedColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    StatusBadge(status: staff.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 20),
          _DetailRow(label: 'Employee ID', value: staff.employeeId),
          _DetailRow(label: 'Email', value: staff.email),
          _DetailRow(label: 'Phone', value: staff.phone),
          _DetailRow(label: 'Designation', value: staff.designation),
          _DetailRow(label: 'Department', value: staff.department),
          _DetailRow(label: 'Branch', value: staff.branchName ?? '—'),
          _DetailRow(label: 'Role', value: staff.roleName ?? '—'),
          _DetailRow(label: 'Status', value: staff.status),
          _DetailRow(label: 'Joined', value: staff.joiningDate),
          if (staff.staffType != null && staff.staffType!.isNotEmpty)
            _DetailRow(label: 'Staff Type', value: staff.staffType!),
          if (staff.reportingManager != null && staff.reportingManager!.isNotEmpty)
            _DetailRow(label: 'Reporting Manager', value: staff.reportingManager!),
          if (staff.gender != null && staff.gender!.isNotEmpty)
            _DetailRow(label: 'Gender', value: staff.gender!),
          if (staff.dob != null && staff.dob!.isNotEmpty)
            _DetailRow(label: 'Date of Birth', value: staff.dob!),
          if (staff.maritalStatus != null && staff.maritalStatus!.isNotEmpty)
            _DetailRow(label: 'Marital Status', value: staff.maritalStatus!),
          if (staff.bloodGroup != null && staff.bloodGroup!.isNotEmpty)
            _DetailRow(label: 'Blood Group', value: staff.bloodGroup!),
          if (staff.addressLine1 != null && staff.addressLine1!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Current Address', style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor, fontSize: 13)),
            const SizedBox(height: 6),
            _DetailRow(label: 'Address', value: staff.addressLine1!),
            if (staff.addressCity != null && staff.addressCity!.isNotEmpty)
              _DetailRow(label: 'City', value: '${staff.addressCity}${staff.addressState != null && staff.addressState!.isNotEmpty ? ', ${staff.addressState}' : ''}${staff.addressPostalCode != null && staff.addressPostalCode!.isNotEmpty ? ' ${staff.addressPostalCode}' : ''}'),
            if (staff.addressCountry != null && staff.addressCountry!.isNotEmpty)
              _DetailRow(label: 'Country', value: staff.addressCountry!),
          ],
          if (staff.company.isNotEmpty)
            _DetailRow(label: 'Company', value: staff.company),
        ],
      ),
    );
  }

  Widget _buildSalaryContent(Staff staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
            'Salary Overview & Structure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Overview'),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Salary Cycle',
            value: staff.salaryCycle ?? '—',
          ),
          _DetailRow(
            label: 'Gross Salary',
            value: staff.grossSalary != null ? '₹ ${staff.grossSalary!.toStringAsFixed(2)}' : '—',
          ),
          _DetailRow(
            label: 'Net Salary',
            value: staff.netSalary != null ? '₹ ${staff.netSalary!.toStringAsFixed(2)}' : '—',
          ),
          const SizedBox(height: 24),
          _sectionLabel('Employment & Bank'),
          const SizedBox(height: 8),
          _DetailRow(label: 'UAN', value: staff.uan ?? '—'),
          _DetailRow(label: 'PAN', value: staff.panNumber ?? '—'),
          _DetailRow(label: 'PF Number', value: staff.pfNumber ?? '—'),
          _DetailRow(label: 'ESI Number', value: staff.esiNumber ?? '—'),
          _DetailRow(label: 'Bank Name', value: staff.bankName ?? '—'),
          _DetailRow(label: 'Account Number', value: staff.accountNumber ?? '—'),
          _DetailRow(label: 'IFSC', value: staff.ifscCode ?? '—'),
          _DetailRow(label: 'Verification Status', value: staff.bankVerificationStatus ?? '—'),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textMutedColor,
      ),
    );
  }

  Widget _buildPlaceholderContent({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.textMutedColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: context.textMutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: context.textDimColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
