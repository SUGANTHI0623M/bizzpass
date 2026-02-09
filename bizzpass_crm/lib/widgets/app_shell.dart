import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavItem {
  final String id, label;
  final IconData icon;
  final int badgeCount;
  const NavItem(
      {required this.id,
      required this.label,
      required this.icon,
      this.badgeCount = 0});
}

const navItems = [
  NavItem(id: 'companies', label: 'Companies', icon: Icons.business_rounded),
  NavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
  NavItem(id: 'licenses', label: 'Licenses', icon: Icons.vpn_key_rounded),
  NavItem(id: 'payments', label: 'Payments', icon: Icons.credit_card_rounded),
  NavItem(id: 'staff', label: 'Staff', icon: Icons.people_rounded),
  NavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.calendar_today_rounded),
  NavItem(
      id: 'visitors', label: 'Visitors', icon: Icons.person_pin_circle_rounded),
  NavItem(
      id: 'notifications',
      label: 'Notifications',
      icon: Icons.notifications_rounded,
      badgeCount: 3),
  NavItem(id: 'plans', label: 'Plans', icon: Icons.layers_rounded),
  NavItem(id: 'settings', label: 'Settings', icon: Icons.settings_rounded),
];

class AppShell extends StatefulWidget {
  final String activePage;
  final ValueChanged<String> onPageChanged;
  final Widget child;

  /// When set, a logout control is shown in the top bar.
  final VoidCallback? onLogout;

  const AppShell({
    super.key,
    required this.activePage,
    required this.onPageChanged,
    required this.child,
    this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
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
              shape: const RoundedRectangleBorder(),
              child: _buildSidebarContent(collapsed: false, inDrawer: true),
            ),
      body: Row(
        children: [
          // ─── Desktop Sidebar ─────────────────────
          if (isWide)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: _collapsed ? 72 : 250,
              decoration: const BoxDecoration(
                color: AppColors.sidebar,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child:
                  _buildSidebarContent(collapsed: _collapsed, inDrawer: false),
            ),

          // ─── Main Content ────────────────────────
          Expanded(
            child: Column(
              children: [
                // ─── Top Bar ─────────────────────────
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
                      Text(
                        widget.activePage == 'dashboard'
                            ? 'Welcome back'
                            : navItems
                                .firstWhere((n) => n.id == widget.activePage)
                                .label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const Spacer(),
                      // Notification bell
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () =>
                                widget.onPageChanged('notifications'),
                            icon: const Icon(Icons.notifications_outlined,
                                size: 20, color: AppColors.textMuted),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.danger,
                                border:
                                    Border.all(color: AppColors.bg, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      if (widget.onLogout != null)
                        IconButton(
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout_rounded,
                              size: 20, color: AppColors.textMuted),
                          tooltip: 'Log out',
                        ),
                      const SizedBox(width: 4),
                      // User avatar
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, Color(0xFF6D28D9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text('SA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ),
                          if (isWide) ...[
                            const SizedBox(width: 10),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Super Admin',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    )),
                                Text('admin@bizzpass.in',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDim,
                                    )),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Page Content ────────────────────
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
        children: [
          // ─── Logo ────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 12 : 20,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('BP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      )),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BizzPass',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                            letterSpacing: -0.3,
                          )),
                      Text('ADMIN CRM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDim,
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── Nav Items ───────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
              children: navItems.map((item) {
                final isActive = widget.activePage == item.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        widget.onPageChanged(item.id);
                        if (inDrawer) Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      hoverColor: AppColors.cardHover,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 0 : 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              size: 18,
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isActive
                                          ? AppColors.accent
                                          : AppColors.textMuted,
                                    )),
                              ),
                              if (item.badgeCount > 0)
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.danger.withOpacity(0.15),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${item.badgeCount}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger,
                                      )),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Collapse Button (desktop only) ──────
          if (!inDrawer)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  borderRadius: BorderRadius.circular(10),
                  hoverColor: AppColors.cardHover,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.cardHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          collapsed
                              ? Icons.chevron_right_rounded
                              : Icons.chevron_left_rounded,
                          size: 16,
                          color: AppColors.textDim,
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 10),
                          const Text('Collapse',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDim,
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
