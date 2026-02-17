import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/staff_repository.dart';
import '../data/staff_extended_repository.dart';
import '../utils/image_picker_stub.dart' if (dart.library.html) '../utils/image_picker_web.dart' as image_picker;
import '../utils/url_launcher_stub.dart' if (dart.library.html) '../utils/url_launcher_web.dart' as url_launcher;

/// Tab id for staff details. Experience & Education are inside Profile. No Loan, no Salary Overview.
enum _StaffDetailsTab {
  profile,
  attendance,
  salary,
  leaves,
  onboarding,
  documents,
  expenses,
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
  final StaffExtendedRepository _extRepo = StaffExtendedRepository();
  Staff? _staff;
  List<StaffExperience> _experience = [];
  List<StaffEducation> _education = [];
  List<StaffOnboardingDocument> _onboardingDocs = [];
  bool _loading = true;
  String? _error;
  _StaffDetailsTab _selectedTab = _StaffDetailsTab.profile;
  bool _updatingStatus = false;

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
      if (!mounted) return;
      setState(() => _staff = s);
      await _loadExtended();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('StaffException: ', '');
        });
      }
    }
  }

  Future<void> _loadExtended() async {
    if (_staff == null) return;
    try {
      final exp = await _extRepo.getExperience(widget.staffId);
      final edu = await _extRepo.getEducation(widget.staffId);
      final docs = await _extRepo.getOnboardingDocuments(widget.staffId);
      if (mounted) {
        setState(() {
          _experience = exp;
          _education = edu;
          _onboardingDocs = docs;
        });
      }
    } catch (_) {}
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTabBar(),
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

  Future<void> _toggleStatus() async {
    if (_staff == null || _updatingStatus) return;
    final newStatus = _staff!.status == 'active' ? 'inactive' : 'active';
    setState(() => _updatingStatus = true);
    try {
      await _repo.updateStaff(widget.staffId, status: newStatus);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _updatingStatus = false);
      widget.onStaffUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(newStatus == 'active' ? 'Staff activated' : 'Staff deactivated')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _updatingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('StaffException: ', ''))),
        );
      }
    }
  }

  Widget _buildHeader() {
    final isActive = _staff?.status == 'active';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
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
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: context.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SectionHeader(
              title: 'Staff Details',
              subtitle: _staff?.name ?? 'Employee',
            ),
          ),
          if (_staff != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_updatingStatus)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                    )
                  else
                    Switch(
                      value: isActive,
                      onChanged: (_) => _toggleStatus(),
                      activeTrackColor: context.accentColor.withOpacity(0.5),
                      activeThumbColor: context.accentColor,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? context.accentColor : context.textMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onEdit != null) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => widget.onEdit!(_staff!),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ],
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

  Widget _buildTabBar() {
    const tabs = [
      (_StaffDetailsTab.profile, 'Profile', Icons.person_outline_rounded),
      (_StaffDetailsTab.attendance, 'Attendance', Icons.schedule_rounded),
      (_StaffDetailsTab.salary, 'Salary', Icons.attach_money_rounded),
      (_StaffDetailsTab.leaves, 'Leaves', Icons.calendar_today_rounded),
      (_StaffDetailsTab.onboarding, 'Onboarding Details', Icons.assignment_rounded),
      (_StaffDetailsTab.documents, 'Documents', Icons.description_outlined),
      (_StaffDetailsTab.expenses, 'Expenses', Icons.receipt_long_rounded),
      (_StaffDetailsTab.payslipRequests, 'Payslip Requests', Icons.request_page_rounded),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.map((t) {
            final selected = _selectedTab == t.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedTab = t.$1),
                style: TextButton.styleFrom(
                  foregroundColor: selected ? context.accentColor : context.textSecondaryColor,
                  backgroundColor: selected ? context.accentColor.withOpacity(0.12) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: Icon(t.$3, size: 18, color: selected ? context.accentColor : context.textSecondaryColor),
                label: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
      case _StaffDetailsTab.onboarding:
        return _buildOnboardingContent(staff);
      case _StaffDetailsTab.documents:
        return _buildPlaceholderContent(
          icon: Icons.description_outlined,
          title: 'Documents',
          message: 'Staff documents will appear here.',
        );
      case _StaffDetailsTab.expenses:
        return _buildPlaceholderContent(
          icon: Icons.receipt_long_rounded,
          title: 'Expenses',
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
    final profileCard = Container(
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
          if (staff.createdAt != null && staff.createdAt!.isNotEmpty)
            _DetailRow(label: 'Created at', value: _formatCreatedAt(staff.createdAt!)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profileCard,
        const SizedBox(height: 24),
        _buildExperienceContent(staff),
        const SizedBox(height: 24),
        _buildEducationContent(staff),
      ],
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
            'Salary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('Salary & Bank'),
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

  static String _formatCreatedAt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildExperienceContent(Staff staff) {
    return _StaffExperienceSection(
      staffId: widget.staffId,
      experience: _experience,
      extRepo: _extRepo,
      onUpdated: _loadExtended,
    );
  }

  Widget _buildEducationContent(Staff staff) {
    return _StaffEducationSection(
      staffId: widget.staffId,
      education: _education,
      extRepo: _extRepo,
      onUpdated: _loadExtended,
    );
  }

  Widget _buildOnboardingContent(Staff staff) {
    return _StaffOnboardingSection(
      staffId: widget.staffId,
      documents: _onboardingDocs,
      extRepo: _extRepo,
      onUpdated: _loadExtended,
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

// --- Experience Details section ---
class _StaffExperienceSection extends StatefulWidget {
  final int staffId;
  final List<StaffExperience> experience;
  final StaffExtendedRepository extRepo;
  final VoidCallback onUpdated;

  const _StaffExperienceSection({
    required this.staffId,
    required this.experience,
    required this.extRepo,
    required this.onUpdated,
  });

  @override
  State<_StaffExperienceSection> createState() => _StaffExperienceSectionState();
}

class _StaffExperienceSectionState extends State<_StaffExperienceSection> {
  Future<void> _addOrEdit([StaffExperience? exp]) async {
    final companyName = TextEditingController(text: exp?.companyName ?? '');
    final jobTitle = TextEditingController(text: exp?.jobTitle ?? '');
    final fromDate = TextEditingController(text: exp?.fromDate ?? '');
    final toDate = TextEditingController(text: exp?.toDate ?? '');
    var isCurrent = exp?.isCurrent ?? false;
    final description = TextEditingController(text: exp?.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(exp == null ? 'Add Experience' : 'Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyName, decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: jobTitle, decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: fromDate, decoration: const InputDecoration(labelText: 'From (YYYY-MM-DD)', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: toDate, decoration: const InputDecoration(labelText: 'To (YYYY-MM-DD)', border: OutlineInputBorder()), enabled: !isCurrent)),
                ]),
                const SizedBox(height: 8),
                CheckboxListTile(value: isCurrent, onChanged: (v) => setDialogState(() => isCurrent = v ?? false), title: const Text('Currently working here'), contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading),
                const SizedBox(height: 8),
                TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true || !mounted) return;
    try {
      if (exp == null) {
        await widget.extRepo.createExperience(widget.staffId, {
          'companyName': companyName.text.trim(),
          'jobTitle': jobTitle.text.trim(),
          'fromDate': fromDate.text.trim().isEmpty ? null : fromDate.text.trim(),
          'toDate': isCurrent ? null : (toDate.text.trim().isEmpty ? null : toDate.text.trim()),
          'isCurrent': isCurrent,
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
        });
      } else {
        await widget.extRepo.updateExperience(widget.staffId, exp.id, {
          'companyName': companyName.text.trim(),
          'jobTitle': jobTitle.text.trim(),
          'fromDate': fromDate.text.trim().isEmpty ? null : fromDate.text.trim(),
          'toDate': isCurrent ? null : (toDate.text.trim().isEmpty ? null : toDate.text.trim()),
          'isCurrent': isCurrent,
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
        });
      }
      widget.onUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteExperience(StaffExperience exp) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete experience?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))]));
    if (ok != true || !mounted) return;
    try {
      await widget.extRepo.deleteExperience(widget.staffId, exp.id);
      widget.onUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experience;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Experience Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textColor)),
              const Spacer(),
              TextButton.icon(onPressed: () => _addOrEdit(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Experience')),
            ],
          ),
          const SizedBox(height: 16),
          ...(exp.isEmpty
              ? [Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No experience added yet.', style: TextStyle(color: context.textMutedColor))))]
              : exp.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(e.jobTitle.isNotEmpty ? e.jobTitle : '—', style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor)),
                    subtitle: Text([if (e.companyName.isNotEmpty) e.companyName, if (e.fromDate.isNotEmpty || e.toDate.isNotEmpty) '${e.fromDate} - ${e.isCurrent ? "Present" : e.toDate}'].join(' • '), style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _addOrEdit(e), tooltip: 'Edit'),
                      IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor), onPressed: () => _deleteExperience(e), tooltip: 'Delete'),
                    ]),
                  ),
                )).toList()),
        ],
      ),
    );
  }
}

// --- Education Details section ---
class _StaffEducationSection extends StatefulWidget {
  final int staffId;
  final List<StaffEducation> education;
  final StaffExtendedRepository extRepo;
  final VoidCallback onUpdated;

  const _StaffEducationSection({required this.staffId, required this.education, required this.extRepo, required this.onUpdated});

  @override
  State<_StaffEducationSection> createState() => _StaffEducationSectionState();
}

class _StaffEducationSectionState extends State<_StaffEducationSection> {
  Future<void> _addOrEdit([StaffEducation? edu]) async {
    final institution = TextEditingController(text: edu?.institution ?? '');
    final degreeOrCourse = TextEditingController(text: edu?.degreeOrCourse ?? '');
    final fromDate = TextEditingController(text: edu?.fromDate ?? '');
    final toDate = TextEditingController(text: edu?.toDate ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edu == null ? 'Add Education' : 'Edit Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: institution, decoration: const InputDecoration(labelText: 'Institution', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: degreeOrCourse, decoration: const InputDecoration(labelText: 'Degree / Course', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: fromDate, decoration: const InputDecoration(labelText: 'From (YYYY-MM-DD)', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: toDate, decoration: const InputDecoration(labelText: 'To (YYYY-MM-DD)', border: OutlineInputBorder()))),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      if (edu == null) {
        await widget.extRepo.createEducation(widget.staffId, {
          'institution': institution.text.trim(),
          'degreeOrCourse': degreeOrCourse.text.trim(),
          'fromDate': fromDate.text.trim().isEmpty ? null : fromDate.text.trim(),
          'toDate': toDate.text.trim().isEmpty ? null : toDate.text.trim(),
        });
      } else {
        await widget.extRepo.updateEducation(widget.staffId, edu.id, {
          'institution': institution.text.trim(),
          'degreeOrCourse': degreeOrCourse.text.trim(),
          'fromDate': fromDate.text.trim().isEmpty ? null : fromDate.text.trim(),
          'toDate': toDate.text.trim().isEmpty ? null : toDate.text.trim(),
        });
      }
      widget.onUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteEducation(StaffEducation edu) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete education?'), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))]));
    if (ok != true || !mounted) return;
    try {
      await widget.extRepo.deleteEducation(widget.staffId, edu.id);
      widget.onUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final edu = widget.education;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Education Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textColor)),
              const Spacer(),
              TextButton.icon(onPressed: () => _addOrEdit(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Education')),
            ],
          ),
          const SizedBox(height: 16),
          ...(edu.isEmpty
              ? [Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No education added yet.', style: TextStyle(color: context.textMutedColor))))]
              : edu.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(e.degreeOrCourse.isNotEmpty ? e.degreeOrCourse : '—', style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor)),
                    subtitle: Text([if (e.institution.isNotEmpty) e.institution, if (e.fromDate.isNotEmpty || e.toDate.isNotEmpty) '${e.fromDate} - ${e.toDate}'].join(' • '), style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _addOrEdit(e), tooltip: 'Edit'),
                      IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor), onPressed: () => _deleteEducation(e), tooltip: 'Delete'),
                    ]),
                  ),
                )).toList()),
        ],
      ),
    );
  }
}

// --- Onboarding Details section ---
class _StaffOnboardingSection extends StatefulWidget {
  final int staffId;
  final List<StaffOnboardingDocument> documents;
  final StaffExtendedRepository extRepo;
  final VoidCallback onUpdated;

  const _StaffOnboardingSection({required this.staffId, required this.documents, required this.extRepo, required this.onUpdated});

  @override
  State<_StaffOnboardingSection> createState() => _StaffOnboardingSectionState();
}

class _StaffOnboardingSectionState extends State<_StaffOnboardingSection> {
  /// Which upload is in progress: 'offer_letter' or 'joining_document'. Null = none.
  String? _uploadingType;

  static const List<MapEntry<String, String>> _requiredDetails = [
    MapEntry('Personal details', 'Name, DOB, contact, address'),
    MapEntry('ID proof', 'Aadhaar / PAN / Passport'),
    MapEntry('Bank account', 'Bank name, IFSC, account number'),
    MapEntry('Previous employment', 'Experience letters if any'),
    MapEntry('Education certificates', 'Degree / course certificates'),
    MapEntry('Offer letter', 'Signed offer letter'),
  ];

  Future<void> _uploadDocument({String type = 'joining_document'}) async {
    try {
      final bytes = await image_picker.pickImageBytes();
      if (bytes == null || bytes.isEmpty || !mounted) return;
      setState(() => _uploadingType = type);
      final fileName = type == 'offer_letter' ? 'offer_letter.pdf' : 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await widget.extRepo.uploadOnboardingDocument(widget.staffId, fileBytes: bytes, fileName: fileName, documentType: type);
      widget.onUpdated();
      if (mounted) {
        setState(() => _uploadingType = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingType = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteDoc(StaffOnboardingDocument doc) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Remove document?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Remove'))]));
    if (ok != true || !mounted) return;
    try {
      await widget.extRepo.deleteOnboardingDocument(widget.staffId, doc.id);
      widget.onUpdated();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _openUrl(String url) {
    url_launcher.openUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.documents;
    final offerLetters = docs.where((d) => d.isOfferLetter).toList();
    final otherDocs = docs.where((d) => !d.isOfferLetter).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Onboarding Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.textColor)),
          const SizedBox(height: 20),
          Text('Required details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMutedColor)),
          const SizedBox(height: 8),
          ..._requiredDetails.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: context.textMutedColor),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key, style: TextStyle(fontWeight: FontWeight.w500, color: context.textColor))),
                Text(e.value, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
              ],
            ),
          )),
          const SizedBox(height: 24),
          Text('Offer letter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMutedColor)),
          const SizedBox(height: 8),
          if (offerLetters.isEmpty)
            OutlinedButton.icon(
              onPressed: _uploadingType != null ? null : () => _uploadDocument(type: 'offer_letter'),
              icon: _uploadingType == 'offer_letter' ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload offer letter'),
            )
          else
            ...offerLetters.map((d) => Card(
              child: ListTile(
                leading: Icon(Icons.description_rounded, color: context.accentColor),
                title: Text(d.fileName.isNotEmpty ? d.fileName : 'Offer letter', style: TextStyle(color: context.textColor)),
                subtitle: Text('Uploaded', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.open_in_new_rounded, size: 20), onPressed: () => _openUrl(d.fileUrl), tooltip: 'View'),
                  IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor), onPressed: () => _deleteDoc(d), tooltip: 'Remove'),
                ]),
              ),
            )),
          const SizedBox(height: 24),
          Text('Uploaded documents (joining)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMutedColor)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploadingType != null ? null : () => _uploadDocument(type: 'joining_document'),
            icon: _uploadingType == 'joining_document' ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload document'),
          ),
          if (otherDocs.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 12), child: Text('No documents uploaded yet. Click to upload documents provided at joining.', style: TextStyle(fontSize: 13, color: context.textMutedColor)))
          else
            ...otherDocs.map((d) => Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: Icon(Icons.description_rounded, color: context.accentColor),
                title: Text(d.fileName.isNotEmpty ? d.fileName : 'Document', style: TextStyle(color: context.textColor)),
                subtitle: Text(d.uploadedAt.isNotEmpty ? d.uploadedAt : 'Uploaded', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.open_in_new_rounded, size: 20), onPressed: () => _openUrl(d.fileUrl), tooltip: 'View'),
                  IconButton(icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor), onPressed: () => _deleteDoc(d), tooltip: 'Remove'),
                ]),
              ),
            )),
        ],
      ),
    );
  }
}
