import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/subscription_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Subscription & Billing: current plan, usage, available plans, subscribe (PaySharp placeholder).
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionRepository _repo = SubscriptionRepository();
  CurrentSubscription? _current;
  List<Plan> _plans = [];
  List<PaymentHistoryItem> _payments = [];
  bool _loading = true;
  String? _error;
  bool _initiating = false;

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
      final results = await Future.wait([
        _repo.getCurrentSubscription(),
        _repo.getPlansForSubscription(),
        _repo.getPaymentHistory(),
      ]);
      if (mounted) {
        setState(() {
          _current = results[0] as CurrentSubscription;
          _plans = results[1] as List<Plan>;
          _payments = results[2] as List<PaymentHistoryItem>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('SubscriptionException: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _subscribe(Plan plan) async {
    final duration = await showDialog<int>(
      context: context,
      builder: (ctx) => _DurationDialog(plan: plan),
    );
    if (duration == null || !mounted) return;

    setState(() => _initiating = true);
    try {
      final result = await _repo.initiateSubscription(
        planId: plan.id,
        durationMonths: duration,
      );
      if (!mounted) return;
      setState(() => _initiating = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => _PaymentDialog(result: result),
      );
      _load();
    } catch (e) {
      if (mounted) {
        setState(() => _initiating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('SubscriptionException: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Subscription & Billing',
            subtitle: 'View your plan, usage, and subscribe or renew here',
          ),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.text))),
                  TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (_current != null) _buildCurrentPlanCard(_current!),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Available plans',
              subtitle: 'Choose a plan to subscribe or upgrade',
              bottomPadding: 16,
            ),
            _buildPlansGrid(),
            if (_payments.isNotEmpty) ...[
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Payment history',
                subtitle: 'Recent subscription payments',
                bottomPadding: 16,
              ),
              _buildPaymentHistory(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(CurrentSubscription sub) {
    final plan = sub.plan;
    final status = sub.licenseStatus ?? 'unknown';
    final isExpired = status == 'expired';
    final isExpiringSoon = sub.daysRemaining != null && sub.daysRemaining! <= 30 && sub.daysRemaining! > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? AppColors.danger.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.credit_card_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.hasSubscription && plan != null ? plan.planName : 'No active plan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (sub.hasSubscription && plan != null)
                      Text(
                        plan.description.isNotEmpty ? plan.description : '${plan.maxUsers} staff · ${plan.maxBranches} branches',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (sub.hasSubscription) StatusBadge(status: status, large: true),
            ],
          ),
          if (sub.hasSubscription && (sub.validUntil != null || sub.daysRemaining != null)) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (sub.validUntil != null)
                  _DetailChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Valid until ${sub.validUntil}',
                  ),
                if (sub.daysRemaining != null)
                  _DetailChip(
                    icon: Icons.schedule_rounded,
                    label: sub.daysRemaining! > 0 ? '${sub.daysRemaining} days left' : 'Expired',
                    color: isExpired ? AppColors.danger : (isExpiringSoon ? AppColors.warning : AppColors.textMuted),
                  ),
                _DetailChip(
                  icon: Icons.people_rounded,
                  label: 'Staff ${sub.currentStaff}${sub.maxStaff != null ? '/${sub.maxStaff}' : ''}',
                ),
                _DetailChip(
                  icon: Icons.business_rounded,
                  label: 'Branches ${sub.currentBranches}${sub.maxBranches != null ? '/$sub.maxBranches' : ''}',
                ),
              ],
            ),
          ],
          if (isExpired || !sub.hasSubscription) ...[
            const SizedBox(height: 20),
            Text(
              isExpired ? 'Your plan has ended. Subscribe below to continue using the portal.' : 'Subscribe to a plan to get started.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlansGrid() {
    if (_plans.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Text(
          'No plans available. Contact support.',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }

    final currentPlanId = _current?.plan?.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _plans.length,
          itemBuilder: (_, i) {
            final plan = _plans[i];
            final isCurrent = plan.id == currentPlanId;
            return _PlanCard(
              plan: plan,
              isCurrentPlan: isCurrent,
              onSubscribe: isCurrent ? null : () => _subscribe(plan),
              initiating: _initiating,
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _payments.take(10).map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(
                  p.status == 'captured' ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 20,
                  color: p.status == 'captured' ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.planName.isNotEmpty ? p.planName : 'Payment #${p.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        p.paidAt.isNotEmpty ? p.paidAt : p.createdAt,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: p.status),
                const SizedBox(width: 12),
                Text(
                  '${fmtINR(p.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color ?? AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;
  final bool initiating;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    this.onSubscribe,
    required this.initiating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: isCurrentPlan ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.layers_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  plan.planName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan.description,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${fmtINR(plan.price)} / ${plan.durationMonths} mo',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.maxUsers} staff · ${plan.maxBranches} branches',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.features.take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                )),
          ],
          const Spacer(),
          if (onSubscribe != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: initiating ? null : onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: initiating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Subscribe'),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DurationDialog extends StatefulWidget {
  final Plan plan;

  const _DurationDialog({required this.plan});

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  int _months = 12;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final amount = (plan.price * _months / plan.durationMonths).round();
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Subscribe to ${plan.planName}', style: const TextStyle(color: AppColors.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Duration', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _months,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            dropdownColor: AppColors.card,
            items: [12, 6, 24].map((m) => DropdownMenuItem(value: m, child: Text('$m months'))).toList(),
            onChanged: (v) => setState(() => _months = v ?? 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(
                  '${fmtINR(amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _months),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          child: const Text('Continue to payment'),
        ),
      ],
    );
  }
}

class _PaymentDialog extends StatelessWidget {
  final InitiateSubscriptionResult result;

  const _PaymentDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final hasUrl = result.checkoutUrl != null && result.checkoutUrl!.isNotEmpty;
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(hasUrl ? Icons.payment_rounded : Icons.info_outline_rounded,
              color: hasUrl ? AppColors.success : AppColors.warning, size: 24),
          const SizedBox(width: 10),
          const Text('Payment', style: TextStyle(color: AppColors.text, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.planName} · ${result.durationMonths} months',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtINR(result.amount)} ${result.currency}',
              style: const TextStyle(fontSize: 15, color: AppColors.accent, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (result.message != null && result.message!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.message!,
                        style: const TextStyle(fontSize: 13, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              )
            else if (hasUrl)
              const Text(
                'You will be redirected to PaySharp to complete the payment.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (hasUrl)
          FilledButton.icon(
            onPressed: () {
              // When PaySharp key is added, open result.checkoutUrl in browser
              Navigator.pop(context);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Open payment page'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
          ),
      ],
    );
  }
}
