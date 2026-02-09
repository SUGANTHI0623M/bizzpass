import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/branches_repository.dart';

class CompanyNavItem {
  final String id, label;
  final IconData icon;
  /// Required permission to show this item. Null = always show.
  final String? permission;
  const CompanyNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.permission,
  });
}

const companyNavItems = [
  CompanyNavItem(
      id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
  CompanyNavItem(
      id: 'staff', label: 'Staff', icon: Icons.people_rounded,
      permission: 'user.view'),
  CompanyNavItem(
      id: 'branches', label: 'Branches', icon: Icons.business_rounded,
      permission: 'branch.view'),
  CompanyNavItem(
      id: 'departments', label: 'Departments', icon: Icons.category_rounded,
      permission: 'department.view'),
  CompanyNavItem(
      id: 'roles',
      label: 'Roles & Permissions',
      icon: Icons.admin_panel_settings_rounded,
      permission: 'role.view'),
  CompanyNavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.calendar_today_rounded,
      permission: 'attendance.view'),
  CompanyNavItem(
      id: 'leave', label: 'Leave', icon: Icons.beach_access_rounded,
      permission: 'leave.view'),
  CompanyNavItem(
      id: 'tasks', label: 'Tasks', icon: Icons.task_alt_rounded,
      permission: 'task.view'),
  CompanyNavItem(
      id: 'visitors',
      label: 'Visitors',
      icon: Icons.person_pin_circle_rounded,
      permission: 'visitor.view'),
  CompanyNavItem(
      id: 'payroll', label: 'Payroll', icon: Icons.payments_rounded,
      permission: 'payroll.view'),
  CompanyNavItem(
      id: 'reports', label: 'Reports', icon: Icons.analytics_rounded,
      permission: 'report.view'),
  CompanyNavItem(
      id: 'subscription',
      label: 'Subscription & Billing',
      icon: Icons.credit_card_rounded,
      permission: 'subscription.view'),
  CompanyNavItem(
      id: 'settings', label: 'Settings', icon: Icons.settings_rounded,
      permission: 'settings.view'),
  CompanyNavItem(
      id: 'audit-logs',
      label: 'Audit Logs',
      icon: Icons.history_rounded,
      permission: 'settings.view'), // backend allows settings.view or audit.view
];

/// Returns nav items the user is allowed to see (permission-based).
List<CompanyNavItem> companyNavItemsForPermissions(List<dynamic>? permissions) {
  if (permissions == null || permissions.isEmpty) return companyNavItems;
  final set = permissions.map((e) => e.toString()).toSet();
  return companyNavItems
      .where((n) => n.permission == null || set.contains(n.permission))
      .toList();
}

class CompanyAdminShell extends StatefulWidget {
  final String activePage;
  final ValueChanged<String> onPageChanged;
  final Widget child;
  final VoidCallback? onLogout;
  final String companyName;
  final List<dynamic>? permissions;
  /// If provided, show branch selector in app bar (manage branches + filter staff by branch).
  final List<Branch>? branches;
  final int? selectedBranchId;
  final String? selectedBranchName;
  final void Function(int? branchId, String? branchName)? onBranchSelected;

  const CompanyAdminShell({
    super.key,
    required this.activePage,
    required this.onPageChanged,
    required this.child,
    this.onLogout,
    this.companyName = '',
    this.permissions,
    this.branches,
    this.selectedBranchId,
    this.selectedBranchName,
    this.onBranchSelected,
  });

  @override
  State<CompanyAdminShell> createState() => _CompanyAdminShellState();
}

class _CompanyAdminShellState extends State<CompanyAdminShell> {
  bool _collapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AppColors.sidebar,
              width: 260,
              child: _buildSidebarContent(collapsed: false, inDrawer: true),
            ),
      body: Row(
        children: [
          if (isWide)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _collapsed ? 72 : 250,
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child:
                  _buildSidebarContent(collapsed: _collapsed, inDrawer: false),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      if (!isWide)
                        IconButton(
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                          icon: const Icon(Icons.menu_rounded,
                              color: AppColors.textMuted, size: 22),
                        ),
                      Expanded(
                        child: Text(
                          companyNavItemsForPermissions(widget.permissions)
                              .firstWhere(
                                  (n) => n.id == widget.activePage,
                                  orElse: () =>
                                      companyNavItemsForPermissions(
                                          widget.permissions).first)
                              .label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      if (widget.branches != null && widget.onBranchSelected != null)
                        _BranchDropdown(
                          branches: widget.branches!,
                          selectedBranchId: widget.selectedBranchId,
                          selectedBranchName: widget.selectedBranchName,
                          onSelected: widget.onBranchSelected!,
                          onManageBranches: () => widget.onPageChanged('branches'),
                        ),
                      if (widget.companyName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.companyName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      if (widget.onLogout != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout_rounded,
                              color: AppColors.textMuted, size: 20),
                          tooltip: 'Logout',
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
      {required bool collapsed, required bool inDrawer}) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded,
                      color: AppColors.accent, size: 20),
                ),
                if (!collapsed && !inDrawer) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Company Portal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...companyNavItemsForPermissions(widget.permissions).map((n) {
            final isActive = widget.activePage == n.id;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onPageChanged(n.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed && !inDrawer ? 12 : 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accent.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isActive
                        ? Border.all(color: AppColors.accent.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        n.icon,
                        size: 20,
                        color:
                            isActive ? AppColors.accent : AppColors.textMuted,
                      ),
                      if (!collapsed || inDrawer) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            n.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BranchDropdown extends StatelessWidget {
  final List<Branch> branches;
  final int? selectedBranchId;
  final String? selectedBranchName;
  final void Function(int? branchId, String? branchName) onSelected;
  final VoidCallback onManageBranches;

  const _BranchDropdown({
    required this.branches,
    required this.selectedBranchId,
    required this.selectedBranchName,
    required this.onSelected,
    required this.onManageBranches,
  });

  @override
  Widget build(BuildContext context) {
    final label = selectedBranchId != null
        ? (selectedBranchName ?? 'Branch')
        : 'Branch: All';
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.business_rounded, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: 'all', child: Text('All')),
          ...branches.map((b) => PopupMenuItem(
            value: 'branch_${b.id}',
            child: Text(b.branchName),
          )),
          const PopupMenuItem(value: 'manage', child: Text('Manage branches')),
        ],
        onSelected: (value) {
          if (value == 'all') {
            onSelected(null, null);
          } else if (value == 'manage') {
            onManageBranches();
          } else if (value.startsWith('branch_')) {
            final id = int.tryParse(value.replaceFirst('branch_', ''));
            if (id != null) {
              try {
                final b = branches.firstWhere((x) => x.id == id);
                onSelected(b.id, b.branchName);
              } catch (_) {}
            }
          }
        },
      ),
    );
  }
}
