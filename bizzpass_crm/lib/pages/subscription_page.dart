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
            backgroundColor: context.dangerColor,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: CircularProgressIndicator(color: context.accentColor),
              ),
            )
          else if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.dangerColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.dangerColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: TextStyle(color: context.textColor))),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? context.dangerColor.withOpacity(0.4) : context.borderColor,
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
                  color: context.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.credit_card_rounded, color: context.accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.hasSubscription && plan != null ? plan.planName : 'No active plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                    ),
                    if (sub.hasSubscription && plan != null)
                      Text(
                        plan.description.isNotEmpty ? plan.description : '${plan.maxUsers} staff · ${plan.maxBranches} branches',
                        style: TextStyle(fontSize: 13, color: context.textMutedColor),
                      ),
                  ],
                ),
              ),
              if (sub.hasSubscription) StatusBadge(status: status, large: true),
            ],
          ),
          if (sub.hasSubscription && (sub.validUntil != null || sub.daysRemaining != null)) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: context.borderColor),
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
                    color: isExpired ? context.dangerColor : (isExpiringSoon ? context.warningColor : context.textMutedColor),
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
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
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
          style: TextStyle(fontSize: 14, color: context.textMutedColor),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
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
                  color: p.status == 'captured' ? context.successColor : context.warningColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.planName.isNotEmpty ? p.planName : 'Payment #${p.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        p.paidAt.isNotEmpty ? p.paidAt : p.createdAt,
                        style: TextStyle(fontSize: 12, color: context.textMutedColor),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: p.status),
                const SizedBox(width: 12),
                Text(
                  '${fmtINR(p.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
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
        Icon(icon, size: 16, color: color ?? context.textMutedColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color ?? context.textMutedColor),
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
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? context.accentColor.withOpacity(0.5) : context.borderColor,
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
                  color: context.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.layers_rounded, color: context.accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  plan.planName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.accentColor,
                    ),
                  ),
                ),
            ],
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan.description,
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '${fmtINR(plan.price)} / ${plan.durationMonths} mo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.maxUsers} staff · ${plan.maxBranches} branches',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.features.take(3).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: context.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
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
                  backgroundColor: context.accentColor,
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
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Subscribe to ${plan.planName}', style: TextStyle(color: context.textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _months,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            dropdownColor: context.cardColor,
            items: [12, 6, 24].map((m) => DropdownMenuItem(value: m, child: Text('$m months'))).toList(),
            onChanged: (v) => setState(() => _months = v ?? 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(color: context.textMutedColor, fontSize: 13)),
                Text(
                  '${fmtINR(amount)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: context.accentColor, fontSize: 16),
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
          style: FilledButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white),
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
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(hasUrl ? Icons.payment_rounded : Icons.info_outline_rounded,
              color: hasUrl ? context.successColor : context.warningColor, size: 24),
          const SizedBox(width: 10),
          Text('Payment', style: TextStyle(color: context.textColor, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.planName} · ${result.durationMonths} months',
              style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtINR(result.amount)} ${result.currency}',
              style: TextStyle(fontSize: 15, color: context.accentColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (result.message != null && result.message!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.message!,
                        style: TextStyle(fontSize: 13, color: context.textColor),
                      ),
                    ),
                  ],
                ),
              )
            else if (hasUrl)
              Text(
                'You will be redirected to PaySharp to complete the payment.',
                style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
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
            style: FilledButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white),
          ),
      ],
    );
  }
}
