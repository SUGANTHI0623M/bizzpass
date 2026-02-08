import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCompanies = companies.where((c) => c.isActive).length;
    final totalRevenue = payments
        .where((p) => p.status == 'captured')
        .fold(0, (s, p) => s + p.amount);
    final totalStaff = companies.fold(0, (s, c) => s + c.staffCount);
    final activeLicenses = licenses.where((l) => l.status == 'active').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
              title: 'Dashboard',
              subtitle: 'Overview of your BizzPass platform'),

          // ─── Stat Cards ────────────────────────────
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 2
                    : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.9,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  icon: Icons.business_rounded,
                  label: 'Active Companies',
                  value: '$activeCompanies',
                  sub: '${companies.length} total registered',
                  trend: '+12%',
                  trendUp: true,
                  accentColor: AppColors.accent.withOpacity(0.12),
                ),
                StatCard(
                  icon: Icons.vpn_key_rounded,
                  label: 'Active Licenses',
                  value: '$activeLicenses',
                  sub:
                      '${licenses.where((l) => l.status == "expired").length} expired',
                  trend: '+3',
                  trendUp: true,
                  accentColor: AppColors.success.withOpacity(0.12),
                ),
                StatCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Total Revenue',
                  value: fmtINR(totalRevenue),
                  sub: '${payments.length} transactions',
                  trend: '+18%',
                  trendUp: true,
                  accentColor: AppColors.info.withOpacity(0.12),
                ),
                StatCard(
                  icon: Icons.people_rounded,
                  label: 'Total Staff',
                  value: fmtNumber(totalStaff),
                  sub: 'Across all companies',
                  trend: '+8%',
                  trendUp: true,
                  accentColor: AppColors.warning.withOpacity(0.12),
                ),
              ],
            );
          }),

          const SizedBox(height: 28),

          // ─── Revenue + Activity Row ────────────────
          LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth > 700;
            final children = [
              _buildRevenueCard(),
              _buildActivityCard(),
            ];
            if (wide) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children.map((c) => Expanded(child: c)).toList());
            }
            return Column(
                children: children
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: c,
                        ))
                    .toList());
          }),

          const SizedBox(height: 20),

          // ─── License Health ────────────────────────
          _buildLicenseHealth(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final revenueData = [
      _RevItem('Enterprise', 399998, 68, AppColors.accent),
      _RevItem('Professional', 179997, 26, AppColors.info),
      _RevItem('Starter', 19999, 6, AppColors.warning),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue by Plan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 18),
          ...revenueData.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.plan,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            )),
                        Text(fmtINR(r.amount),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: r.pct / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: r.color,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final activities = [
      _Activity(Icons.credit_card_rounded, 'TechNova Solutions paid ₹1,49,999',
          '2 hours ago', AppColors.success),
      _Activity(
          Icons.person_pin_circle_rounded,
          'Rajesh Khanna checked in at TechNova',
          '3 hours ago',
          AppColors.info),
      _Activity(
          Icons.warning_amber_rounded,
          'Meridian Logistics license expiring',
          '1 day ago',
          AppColors.warning),
      _Activity(Icons.shield_rounded, 'Nexus Finserv license suspended',
          '2 days ago', AppColors.danger),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 18),
          ...activities.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardHover,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(a.icon, size: 14, color: a.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.text,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis),
                          Text(a.time,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLicenseHealth() {
    final items = [
      _HealthItem('Active', licenses.where((l) => l.status == 'active').length,
          AppColors.success),
      _HealthItem(
          'Expired',
          licenses.where((l) => l.status == 'expired').length,
          AppColors.danger),
      _HealthItem(
          'Suspended',
          licenses.where((l) => l.status == 'suspended').length,
          const Color(0xFFF97316)),
      _HealthItem(
          'Unassigned',
          licenses.where((l) => l.status == 'unassigned').length,
          AppColors.textMuted),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('License Health Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              )),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items
                  .map((s) => Container(
                        decoration: BoxDecoration(
                          color: s.color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: s.color.withOpacity(0.15)),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${s.count}',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: s.color,
                                )),
                            const SizedBox(height: 4),
                            Text(s.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                )),
                          ],
                        ),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _RevItem {
  final String plan;
  final int amount;
  final double pct;
  final Color color;
  const _RevItem(this.plan, this.amount, this.pct, this.color);
}

class _Activity {
  final IconData icon;
  final String text, time;
  final Color color;
  const _Activity(this.icon, this.text, this.time, this.color);
}

class _HealthItem {
  final String label;
  final int count;
  final Color color;
  const _HealthItem(this.label, this.count, this.color);
}
