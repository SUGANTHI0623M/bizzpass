import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/dashboard_repository.dart';
import '../data/mock_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardRepository _repo = DashboardRepository();
  DashboardStats? _stats;
  List<Company> _companies = [];
  List<Payment> _payments = [];
  List<License> _licenses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _repo.fetchStats();
      final companies = await _repo.fetchCompanies();
      final payments = await _repo.fetchPayments();
      final licenses = await _repo.fetchLicenses();
      if (mounted) {
        setState(() {
          _stats = stats;
          _companies = companies;
          _payments = payments;
          _licenses = licenses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('DashboardException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final s = _stats!;
    final activeCompanies = s.activeCompanies;
    final totalCompanies = s.totalCompanies;
    final totalRevenue = s.totalRevenue;
    final totalStaff = s.totalStaff;
    final activeLicenses = s.activeLicenses;
    final expiredLicenses = s.expiredLicenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
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
              childAspectRatio: 1.45,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  icon: Icons.business_rounded,
                  label: 'Active Companies',
                  value: '$activeCompanies',
                  sub: '$totalCompanies total registered',
                  trend: '+12%',
                  trendUp: true,
                  accentColor: AppColors.accent.withOpacity(0.12),
                ),
                StatCard(
                  icon: Icons.vpn_key_rounded,
                  label: 'Active Licenses',
                  value: '$activeLicenses',
                  sub: '$expiredLicenses expired',
                  trend: '+3',
                  trendUp: true,
                  accentColor: AppColors.success.withOpacity(0.12),
                ),
                StatCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Total Revenue',
                  value: fmtINR(totalRevenue),
                  sub: '${s.paymentCount} transactions',
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

          // ─── Companies overview ────────────────────
          _buildCompaniesSection(),

          const SizedBox(height: 20),

          // ─── License Health ────────────────────────
          _buildLicenseHealth(),
        ],
      ),
    );
  }

  Widget _buildCompaniesSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Companies',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  )),
              Text('${_companies.length} total',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          if (_companies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No companies yet.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            )
          else
            ..._companies.take(10).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                                overflow: TextOverflow.ellipsis),
                            Text(
                                '${c.staffCount} staff · ${c.subscriptionPlan}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                )),
                          ],
                        ),
                      ),
                      Text(c.subscriptionStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.subscriptionStatus == 'active'
                                ? AppColors.success
                                : AppColors.textMuted,
                          )),
                    ],
                  ),
                )),
          if (_companies.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('+ ${_companies.length - 10} more',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  )),
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    final byPlan = <String, int>{};
    for (final p in _payments) {
      if (p.status == 'captured' && p.plan.isNotEmpty) {
        byPlan[p.plan] = (byPlan[p.plan] ?? 0) + p.amount;
      }
    }
    final total = byPlan.values.fold<int>(0, (a, b) => a + b);
    Color planColor(String name) {
      final n = name.toLowerCase();
      if (n.contains('enterprise')) return AppColors.accent;
      if (n.contains('professional') || n.contains('pro'))
        return AppColors.info;
      if (n.contains('starter')) return AppColors.warning;
      return AppColors.textMuted;
    }

    final revenueData = byPlan.entries.map((e) {
      final pct = total > 0 ? (e.value / total * 100) : 0.0;
      return _RevItem(e.key, e.value, pct, planColor(e.key));
    }).toList();
    if (revenueData.isEmpty) {
      revenueData.add(const _RevItem('—', 0, 0, AppColors.textMuted));
    }

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
    final activities = <_Activity>[];
    for (final p in _payments.take(5)) {
      if (p.status == 'captured') {
        activities.add(_Activity(
          Icons.credit_card_rounded,
          '${p.company} paid ${fmtINR(p.amount)}',
          _timeAgo(p.paidAt),
          AppColors.success,
        ));
      }
    }
    for (final l in _licenses) {
      if (l.status == 'suspended' && activities.length < 8) {
        activities.add(_Activity(
          Icons.shield_rounded,
          '${l.company ?? "License"} license suspended',
          '—',
          AppColors.danger,
        ));
      }
    }
    if (activities.isEmpty) {
      activities.add(const _Activity(
        Icons.inbox_rounded,
        'No recent activity',
        '—',
        AppColors.textMuted,
      ));
    }

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
    final s = _stats!;
    final items = [
      _HealthItem('Active', s.activeLicenses, AppColors.success),
      _HealthItem('Expired', s.expiredLicenses, AppColors.danger),
      _HealthItem('Suspended', s.suspendedLicenses, const Color(0xFFF97316)),
      _HealthItem('Unassigned', s.unassignedLicenses, AppColors.textMuted),
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

String _timeAgo(String dateStr) {
  if (dateStr.isEmpty) return '—';
  try {
    DateTime dt;
    if (dateStr.length >= 16) {
      dt = DateTime.parse(dateStr.substring(0, 16).replaceAll(' ', 'T'));
    } else {
      dt = DateTime.parse(dateStr);
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dateStr.substring(0, dateStr.length >= 10 ? 10 : dateStr.length);
  } catch (_) {
    return dateStr;
  }
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
