import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/companies_page.dart';
import 'pages/licenses_page.dart';
import 'pages/payments_page.dart';
import 'pages/staff_page.dart';
import 'pages/attendance_page.dart';
import 'pages/visitors_page.dart';
import 'pages/notifications_page.dart';
import 'pages/plans_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const BizzPassApp());
}

class BizzPassApp extends StatelessWidget {
  const BizzPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizzPass Admin CRM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _currentPage = 'dashboard';

  Widget _buildPage() {
    switch (_currentPage) {
      case 'dashboard': return const DashboardPage();
      case 'companies': return const CompaniesPage();
      case 'licenses': return const LicensesPage();
      case 'payments': return const PaymentsPage();
      case 'staff': return const StaffPage();
      case 'attendance': return const AttendancePage();
      case 'visitors': return const VisitorsPage();
      case 'notifications': return const NotificationsPage();
      case 'plans': return const PlansPage();
      case 'settings': return const SettingsPage();
      default: return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      activePage: _currentPage,
      onPageChanged: (page) => setState(() => _currentPage = page),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentPage),
          child: _buildPage(),
        ),
      ),
    );
  }
}
