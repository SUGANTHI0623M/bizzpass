import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/mock_data.dart';
import '../utils/url_launcher_stub.dart' if (dart.library.html) '../utils/url_launcher_web.dart' as url_launcher;
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

  static bool _isConnectionError(String err) =>
      err.contains('connection') ||
      err.contains('XMLHttpRequest') ||
      err.contains('DioException') ||
      err.contains('onError');

  Future<void> _subscribe(Plan plan) async {
    final duration = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
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
        barrierDismissible: true,
        barrierColor: Colors.black54,
        useRootNavigator: true,
        builder: (ctx) => _PaymentDialog(result: result, repo: _repo),
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
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
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
                  Expanded(
                    child: Text(
                      _isConnectionError(_error!)
                          ? 'Connection error. The server may be restarting or unavailable. Ensure the backend is running and try again.'
                          : _error!,
                      style: TextStyle(color: context.textColor),
                    ),
                  ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sub.hasSubscription && plan != null ? plan.planName : 'No active plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.hasSubscription && plan != null)
                      Text(
                        plan.description.isNotEmpty ? plan.description : '${plan.maxUsers} staff · ${plan.maxBranches} branches',
                        style: TextStyle(fontSize: 13, color: context.textMutedColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (sub.hasSubscription)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StatusBadge(status: status, large: true),
                  ),
                ),
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
                  label: 'Branches ${sub.currentBranches}${sub.maxBranches != null ? '/${sub.maxBranches}' : (plan?.maxBranches != null ? '/${plan!.maxBranches}' : '')}',
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.planName.isNotEmpty ? p.planName : 'Payment #${p.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.paidAt.isNotEmpty ? p.paidAt : p.createdAt,
                        style: TextStyle(fontSize: 12, color: context.textMutedColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: p.status),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${fmtINR(p.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrentPlan)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month_rounded, color: context.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Subscribe to ${plan.planName}', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(plan.description.isNotEmpty ? plan.description : '${plan.maxUsers} staff · ${plan.maxBranches} branches',
                    style: TextStyle(color: context.textMutedColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textColor)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _months,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: context.bgColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            dropdownColor: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            items: [12, 6, 24].map((m) => DropdownMenuItem(value: m, child: Text('$m months'))).toList(),
            onChanged: (v) => setState(() => _months = v ?? 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total amount', style: TextStyle(color: context.textMutedColor, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  fmtINR(amount),
                  style: TextStyle(fontWeight: FontWeight.w800, color: context.accentColor, fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _months),
          style: FilledButton.styleFrom(
            backgroundColor: context.accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Continue to payment'),
        ),
      ],
    );
  }
}

class _TransactionDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _TransactionDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.textMutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final InitiateSubscriptionResult result;
  final SubscriptionRepository repo;

  const _PaymentDialog({required this.result, required this.repo});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PaymentDetail? _statusResult;
  bool _checkingStatus = false;
  String? _statusError;
  final _upiIdController = TextEditingController();
  bool _sendingUpiRequest = false;
  bool _upiRequestSent = false;
  bool _loadingCard = false;

  @override
  void dispose() {
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _sendUpiRequest() async {
    final vpa = _upiIdController.text.trim();
    if (vpa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your UPI ID (e.g. name@paytm)')),
      );
      return;
    }
    setState(() {
      _sendingUpiRequest = true;
      _statusError = null;
    });
    try {
      await widget.repo.sendUpiRequest(paymentId: widget.result.paymentId, customerVpa: vpa);
      if (mounted) {
        setState(() {
          _sendingUpiRequest = false;
          _upiRequestSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment request sent! Check your UPI app.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendingUpiRequest = false;
          _statusError = e.toString().replaceAll('SubscriptionException: ', '');
        });
      }
    }
  }

  Future<void> _openCardPayment() async {
    setState(() => _loadingCard = true);
    try {
      final rz = await widget.repo.initiateRazorpaySubscription(
        planId: widget.result.planId,
        durationMonths: widget.result.durationMonths,
      );
      if (mounted && rz.checkoutUrl != null) {
        url_launcher.openUrl(rz.checkoutUrl!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete payment in the new tab. Return here to check status.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('SubscriptionException: ', '')),
            backgroundColor: context.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCard = false);
    }
  }

  bool get _isUpiIntent {
    final url = widget.result.checkoutUrl ?? '';
    return url.startsWith('upi://') || url.startsWith('upibot://');
  }

  Future<void> _checkStatus() async {
    setState(() {
      _checkingStatus = true;
      _statusError = null;
    });
    try {
      final detail = await widget.repo.getPaymentStatus(widget.result.paymentId);
      if (mounted) {
        setState(() {
          _statusResult = detail;
          _checkingStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusError = e.toString().replaceAll('SubscriptionException: ', '');
          _checkingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final hasUrl = result.checkoutUrl != null && result.checkoutUrl!.isNotEmpty;
    final detail = _statusResult;

    return AlertDialog(
      backgroundColor: context.cardColor,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (detail != null
                      ? (detail!.isSuccess ? context.successColor : detail!.isFailed ? context.dangerColor : context.warningColor)
                      : (hasUrl ? context.successColor : context.warningColor))
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              detail != null
                  ? (detail!.isSuccess
                      ? Icons.check_circle_rounded
                      : detail!.isFailed
                          ? Icons.error_rounded
                          : Icons.schedule_rounded)
                  : (hasUrl ? Icons.payment_rounded : Icons.info_outline_rounded),
              color: detail != null
                  ? (detail!.isSuccess
                      ? context.successColor
                      : detail!.isFailed
                          ? context.dangerColor
                          : context.warningColor)
                  : (hasUrl ? context.successColor : context.warningColor),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail != null
                      ? (detail!.isSuccess
                          ? 'Payment successful'
                          : detail!.isFailed
                              ? 'Payment failed'
                              : 'Payment status')
                      : 'Payment',
                  style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (detail == null && hasUrl)
                  Text(
                    '${result.planName} · ${result.durationMonths} months',
                    style: TextStyle(color: context.textMutedColor, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: detail!.isSuccess
                      ? context.successColor.withOpacity(0.1)
                      : detail!.isFailed
                          ? context.dangerColor.withOpacity(0.1)
                          : context.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: detail!.isSuccess
                        ? context.successColor.withOpacity(0.3)
                        : detail!.isFailed
                            ? context.dangerColor.withOpacity(0.3)
                            : context.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail!.isSuccess
                          ? 'Your payment has been completed successfully.'
                          : detail!.isFailed
                              ? 'Payment could not be completed.'
                              : 'Your payment is still processing. Please complete the payment and check again.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TransactionDetailRow(label: 'Payment ID', value: '#${detail!.id}'),
                    _TransactionDetailRow(label: 'Plan', value: '${detail!.planName}${detail!.durationMonths != null ? ' · ${detail!.durationMonths} months' : ''}'),
                    _TransactionDetailRow(label: 'Amount', value: '${fmtINR(detail!.amount)} ${detail!.currency}'),
                    _TransactionDetailRow(label: 'Status', value: detail!.status.toUpperCase()),
                    _TransactionDetailRow(label: 'Created', value: detail!.createdAt),
                    if (detail!.paidAt.isNotEmpty)
                      _TransactionDetailRow(label: 'Paid at', value: detail!.paidAt),
                    if (detail!.transactionRef.isNotEmpty)
                      _TransactionDetailRow(label: 'Transaction ref', value: detail!.transactionRef),
                    if (detail!.gateway.isNotEmpty)
                      _TransactionDetailRow(label: 'Gateway', value: detail!.gateway),
                  ],
                ),
              ),
            ] else ...[
              Text(
                '${result.planName} · ${result.durationMonths} months',
                style: TextStyle(fontWeight: FontWeight.w600, color: context.textColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${fmtINR(result.displayAmount)} ${result.currency}',
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
              else if (hasUrl && _isUpiIntent) ...[
                Text(
                  'Pay ₹${result.displayAmount} via UPI: Scan QR or copy link and open in PhonePe, GPay, Paytm, etc.',
                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: result.checkoutUrl!,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        gapless: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amount: ${fmtINR(result.displayAmount)} — Pay via UPI (QR scan or link)',
                  style: TextStyle(fontSize: 12, color: context.textMutedColor, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 16),
                Text(
                  'Or enter your UPI ID',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: name@bank — e.g. name@paytm, 99xxxx@ybl (PhonePe), name@okaxis (GPay)',
                  style: TextStyle(fontSize: 11, color: context.textMutedColor),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _upiIdController,
                  decoration: InputDecoration(
                    hintText: 'e.g. name@paytm or 99xxxx@ybl',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onSubmitted: (_) => _sendUpiRequest(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sendingUpiRequest ? null : _sendUpiRequest,
                    icon: _sendingUpiRequest
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_upiRequestSent ? 'Request sent' : 'Send payment request to my UPI app'),
                  ),
                ),
                if (result.razorpayAvailable) ...[
                  const SizedBox(height: 20),
                  Divider(height: 1, color: context.borderColor),
                  const SizedBox(height: 16),
                  Text(
                    'Or pay with Card / Netbanking / Wallet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textColor),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadingCard ? null : _openCardPayment,
                      icon: _loadingCard
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                            )
                          : const Icon(Icons.credit_card_rounded, size: 18),
                      label: const Text('Pay with Card, Debit, Netbanking'),
                    ),
                  ),
                ],
                if (_statusError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: context.dangerColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusError!,
                            style: TextStyle(fontSize: 12, color: context.dangerColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else if (hasUrl)
                Text(
                  'You will be redirected to PaySharp to complete the payment.',
                  style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (detail != null)
          if (detail!.isSuccess || detail!.isFailed)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white),
              child: const Text('Done'),
            )
          else
            TextButton.icon(
              onPressed: _checkingStatus ? null : _checkStatus,
              icon: _checkingStatus
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_checkingStatus ? 'Checking…' : 'Check again'),
            )
        else if (hasUrl)
          if (_isUpiIntent) ...[
            TextButton.icon(
              onPressed: _checkingStatus ? null : _checkStatus,
              icon: _checkingStatus
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_checkingStatus ? 'Checking…' : "I've paid – Check status"),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result.checkoutUrl!));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI link copied. Paste in browser on your phone to pay.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy UPI link'),
              style: FilledButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white),
            ),
          ]
          else
            FilledButton.icon(
              onPressed: () {
                url_launcher.openUrl(result.checkoutUrl!);
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
