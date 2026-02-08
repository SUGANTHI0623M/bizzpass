import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      _Plan('Starter', 19999, 12, 30, '1', [
        'Attendance', 'VMS', 'Leave Management',
      ], AppColors.textMuted, 2),
      _Plan('Professional', 59999, 12, 100, '5', [
        'Everything in Starter', 'Payroll', 'Expenses', 'Loans', 'Recruitment',
      ], AppColors.info, 3),
      _Plan('Enterprise', 149999, 12, 300, 'Unlimited', [
        'Everything in Professional', 'Custom Roles', 'API Access', 'Priority Support', 'White-label',
      ], AppColors.accent, 3),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Subscription Plans',
            subtitle: 'Manage pricing and plan features',
            actionLabel: 'Create Plan',
            actionIcon: Icons.add_rounded,
            onAction: () {},
          ),
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 550 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 420,
              ),
              itemCount: plans.length,
              itemBuilder: (ctx, i) => _buildPlanCard(plans[i]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlanCard(_Plan p) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: p.color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text,
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${p.companies} companies', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: p.color,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '₹${fmtNumber(p.price)}', style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -1,
                    )),
                    const TextSpan(text: '/year', style: TextStyle(
                      fontSize: 13, color: AppColors.textDim,
                    )),
                  ])),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _metricBox('${p.maxUsers}', 'Users')),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox(p.maxBranches, 'Branches')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...p.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: p.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary,
                        ))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardHover,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
        ],
      ),
    );
  }
}

class _Plan {
  final String name, maxBranches;
  final int price, duration, maxUsers, companies;
  final List<String> features;
  final Color color;
  const _Plan(this.name, this.price, this.duration, this.maxUsers, this.maxBranches, this.features, this.color, this.companies);
}
