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
      id: 'staff',
      label: 'Staff',
      icon: Icons.people_rounded,
      permission: 'user.view'),
  CompanyNavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.calendar_today_rounded,
      permission: 'attendance.view'),
  CompanyNavItem(
      id: 'leave',
      label: 'Leave',
      icon: Icons.beach_access_rounded,
      permission: 'leave.view'),
  CompanyNavItem(
      id: 'tasks',
      label: 'Tasks',
      icon: Icons.task_alt_rounded,
      permission: 'task.view'),
  CompanyNavItem(
      id: 'visitors',
      label: 'Visitors',
      icon: Icons.person_pin_circle_rounded,
      permission: 'visitor.view'),
  CompanyNavItem(
      id: 'payroll',
      label: 'Payroll',
      icon: Icons.payments_rounded,
      permission: 'payroll.view'),
  CompanyNavItem(
      id: 'reports',
      label: 'Reports',
      icon: Icons.analytics_rounded,
      permission: 'report.view'),
  CompanyNavItem(
      id: 'subscription',
      label: 'Subscription & Billing',
      icon: Icons.credit_card_rounded,
      permission: 'subscription.view'),
  CompanyNavItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_rounded,
      permission: 'settings.view'),
  CompanyNavItem(
      id: 'audit-logs',
      label: 'Audit Logs',
      icon: Icons.history_rounded,
      permission:
          'settings.view'), // backend allows settings.view or audit.view
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

  static const Map<String, String> _settingsSubPageTitles = {
    'branches': 'Branches',
    'departments': 'Departments',
    'roles': 'Roles & Permissions',
    'user-management': 'User Management',
  };

  String _headerTitle(String activePage, List<dynamic>? permissions) {
    if (activePage == 'profile') return 'Company Profile';
    final subTitle = _settingsSubPageTitles[activePage];
    if (subTitle != null) return subTitle;
    final items = companyNavItemsForPermissions(permissions);
    return items
        .firstWhere(
          (n) => n.id == activePage,
          orElse: () => items.first,
        )
        .label;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.bgColor,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: context.sidebarColor,
              width: 260,
              child: _buildSidebarContent(collapsed: false, inDrawer: true),
            ),
      body: Row(
        children: [
          if (isWide)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _collapsed ? 72 : 250,
              decoration: BoxDecoration(
                color: context.sidebarColor,
                border: Border(right: BorderSide(color: context.borderColor)),
              ),
              child:
                  _buildSidebarContent(collapsed: _collapsed, inDrawer: false),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.bgColor,
                    border:
                        Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (isWide) {
                            setState(() => _collapsed = !_collapsed);
                          } else {
                            _scaffoldKey.currentState?.openDrawer();
                          }
                        },
                        icon: Icon(
                          isWide && _collapsed
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: context.textMutedColor,
                          size: 22,
                        ),
                        tooltip: isWide
                            ? (_collapsed ? 'Open sidebar' : 'Close sidebar')
                            : 'Open menu',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _headerTitle(widget.activePage, widget.permissions),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                      ),
                      if (widget.branches != null &&
                          widget.onBranchSelected != null)
                        _BranchDropdown(
                          branches: widget.branches!,
                          selectedBranchId: widget.selectedBranchId,
                          selectedBranchName: widget.selectedBranchName,
                          onSelected: widget.onBranchSelected!,
                          onManageBranches: () =>
                              widget.onPageChanged('branches'),
                        ),
                      if (widget.companyName.isNotEmpty)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onPageChanged('profile'),
                            borderRadius: BorderRadius.circular(8),
                            child: Tooltip(
                              message: 'Company profile',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.companyName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onLogout != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: widget.onLogout,
                          icon: Icon(Icons.logout_rounded,
                              color: context.textMutedColor, size: 20),
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
                    color: context.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.business_rounded,
                      color: context.accentColor, size: 20),
                ),
                if (!collapsed && !inDrawer) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.companyName.isNotEmpty
                          ? widget.companyName
                          : 'Company Portal',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    companyNavItemsForPermissions(widget.permissions).map((n) {
                  final isActive = widget.activePage == n.id;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onPageChanged(n.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed && !inDrawer ? 12 : 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? context.accentColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isActive
                              ? Border.all(
                                  color: context.accentColor.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              n.icon,
                              size: 20,
                              color: isActive
                                  ? context.accentColor
                                  : context.textMutedColor,
                            ),
                            if (!collapsed || inDrawer) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  n.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isActive
                                        ? context.accentColor
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
            color: context.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business_rounded,
                  size: 18, color: context.textMutedColor),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(fontSize: 13, color: context.textColor)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded,
                  color: context.textMutedColor),
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
