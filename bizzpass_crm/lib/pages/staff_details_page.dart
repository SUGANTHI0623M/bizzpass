import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/staff_repository.dart';

/// Full-page staff details. Shown when user clicks view (eye) on a staff member.
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
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  icon: const Icon(Icons.arrow_back_rounded),
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
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading && _staff == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_staff != null)
              _buildDetailsCard(_staff!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(Staff staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.designation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (staff.department.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        staff.department,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
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
          const Divider(height: 1, color: AppColors.border),
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
          if (staff.company.isNotEmpty)
            _DetailRow(label: 'Company', value: staff.company),
        ],
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
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
