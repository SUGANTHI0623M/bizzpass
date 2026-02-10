import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/mock_data.dart';
import '../data/plans_repository.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<Plan> _plans = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  bool _activeOnly = true;
  final PlansRepository _repo = PlansRepository();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.fetchPlans(
        search: _search.isEmpty ? null : _search,
        activeOnly: _activeOnly,
      );
      setState(() {
        _plans = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _plans = [];
        _loading = false;
        _error = e.toString().replaceAll('PlansException: ', '');
      });
    }
  }

  List<Plan> get _filtered {
    if (_search.isEmpty) return _plans;
    final s = _search.toLowerCase();
    return _plans.where((p) {
      return (p.planName.toLowerCase().contains(s)) ||
          (p.planCode.toLowerCase().contains(s));
    }).toList();
  }

  void _showCreatePlanDialog() {
    final planCodeCtrl = TextEditingController();
    final planNameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '19999');
    final durationCtrl = TextEditingController(text: '12');
    final maxUsersCtrl = TextEditingController(text: '30');
    final maxBranchesCtrl = TextEditingController(text: '1');
    final trialCtrl = TextEditingController(text: '0');
    bool isActive = true;
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(
                      ctx, 'Create Plan', submitting, () => Navigator.pop(ctx)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (submitError != null) _errorBanner(submitError!),
                        FormFieldWrapper(
                          label: 'PLAN CODE',
                          child: TextFormField(
                            controller: planCodeCtrl,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            decoration:
                                const InputDecoration(hintText: 'e.g. starter'),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'PLAN NAME',
                          child: TextFormField(
                            controller: planNameCtrl,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            decoration:
                                const InputDecoration(hintText: 'e.g. Starter'),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'DESCRIPTION',
                          child: TextFormField(
                            controller: descCtrl,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                            decoration:
                                const InputDecoration(hintText: 'Optional'),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'PRICE (₹)',
                                child: TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'DURATION (months)',
                                child: TextFormField(
                                  controller: durationCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX USERS',
                                child: TextFormField(
                                  controller: maxUsersCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX BRANCHES',
                                child: TextFormField(
                                  controller: maxBranchesCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  decoration: const InputDecoration(
                                      hintText: 'Empty = Unlimited'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        FormFieldWrapper(
                          label: 'TRIAL DAYS',
                          child: TextFormField(
                            controller: trialCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'ACTIVE',
                          child: Row(
                            children: [
                              Checkbox(
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v ?? true),
                                activeColor: context.accentColor,
                              ),
                              Text('Plan is active',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecondaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final code = planCodeCtrl.text.trim();
                                      final name = planNameCtrl.text.trim();
                                      if (code.isEmpty || name.isEmpty) {
                                        setDialogState(() => submitError =
                                            'Plan code and name are required');
                                        return;
                                      }
                                      final price = double.tryParse(
                                          priceCtrl.text.trim());
                                      if (price == null || price < 0) {
                                        setDialogState(() => submitError =
                                            'Valid price required');
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        await _repo.createPlan(
                                          planCode: code,
                                          planName: name,
                                          description:
                                              descCtrl.text.trim().isEmpty
                                                  ? null
                                                  : descCtrl.text.trim(),
                                          price: price,
                                          durationMonths: int.tryParse(
                                                  durationCtrl.text.trim()) ??
                                              12,
                                          maxUsers: int.tryParse(
                                                  maxUsersCtrl.text.trim()) ??
                                              30,
                                          maxBranches: int.tryParse(
                                              maxBranchesCtrl.text.trim()),
                                          trialDays: int.tryParse(
                                                  trialCtrl.text.trim()) ??
                                              0,
                                          isActive: isActive,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadPlans();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Plan created'),
                                                backgroundColor:
                                                    context.successColor),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'PlansException: ', '');
                                        });
                                      }
                                    },
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text('Create Plan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPlanDialog(Plan plan) {
    final planNameCtrl = TextEditingController(text: plan.planName);
    final descCtrl = TextEditingController(text: plan.description);
    final priceCtrl = TextEditingController(text: '${plan.price}');
    final durationCtrl = TextEditingController(text: '${plan.durationMonths}');
    final maxUsersCtrl = TextEditingController(text: '${plan.maxUsers}');
    final maxBranchesCtrl = TextEditingController(
      text: plan.maxBranches == 'Unlimited' ? '' : plan.maxBranches,
    );
    final trialCtrl = TextEditingController(text: '${plan.trialDays}');
    bool isActive = plan.isActive;
    bool submitting = false;
    String? submitError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: context.bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogHeader(
                      ctx, 'Edit Plan', submitting, () => Navigator.pop(ctx)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (submitError != null) _errorBanner(submitError!),
                        FormFieldWrapper(
                          label: 'PLAN NAME',
                          child: TextFormField(
                            controller: planNameCtrl,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'DESCRIPTION',
                          child: TextFormField(
                            controller: descCtrl,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'PRICE (₹)',
                                child: TextFormField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'DURATION (months)',
                                child: TextFormField(
                                  controller: durationCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX USERS',
                                child: TextFormField(
                                  controller: maxUsersCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FormFieldWrapper(
                                label: 'MAX BRANCHES',
                                child: TextFormField(
                                  controller: maxBranchesCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textColor),
                                  decoration: const InputDecoration(
                                      hintText: 'Empty = Unlimited'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        FormFieldWrapper(
                          label: 'TRIAL DAYS',
                          child: TextFormField(
                            controller: trialCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                                fontSize: 13, color: context.textColor),
                          ),
                        ),
                        FormFieldWrapper(
                          label: 'ACTIVE',
                          child: Row(
                            children: [
                              Checkbox(
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v ?? true),
                                activeColor: context.accentColor,
                              ),
                              Text('Plan is active',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecondaryColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  submitting ? null : () => Navigator.pop(ctx),
                              child: Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      final price = double.tryParse(
                                          priceCtrl.text.trim());
                                      if (price == null || price < 0) {
                                        setDialogState(() => submitError =
                                            'Valid price required');
                                        return;
                                      }
                                      setDialogState(() {
                                        submitting = true;
                                        submitError = null;
                                      });
                                      try {
                                        await _repo.updatePlan(
                                          plan.id,
                                          planName: planNameCtrl.text.trim(),
                                          description:
                                              descCtrl.text.trim().isEmpty
                                                  ? null
                                                  : descCtrl.text.trim(),
                                          price: price,
                                          durationMonths: int.tryParse(
                                              durationCtrl.text.trim()),
                                          maxUsers: int.tryParse(
                                              maxUsersCtrl.text.trim()),
                                          maxBranches: maxBranchesCtrl.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : int.tryParse(
                                                  maxBranchesCtrl.text.trim()),
                                          trialDays: int.tryParse(
                                              trialCtrl.text.trim()),
                                          isActive: isActive,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _loadPlans();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Plan updated'),
                                                backgroundColor:
                                                    context.successColor),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() {
                                          submitting = false;
                                          submitError = e.toString().replaceAll(
                                              'PlansException: ', '');
                                        });
                                      }
                                    },
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showViewPlanDialog(Plan plan) {
    final color = _planColor(plan.planCode);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(plan.planName,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.textColor)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(Icons.close_rounded,
                            size: 20, color: context.textMutedColor),
                        style: IconButton.styleFrom(
                            backgroundColor: context.cardHoverColor),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(plan.description,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondaryColor)),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          DetailTile(
                              label: 'CODE', value: plan.planCode, mono: true),
                          DetailTile(
                              label: 'PRICE',
                              value: '₹${fmtNumber(plan.price)}/yr'),
                          DetailTile(
                              label: 'DURATION',
                              value: '${plan.durationMonths} months'),
                          DetailTile(
                              label: 'MAX USERS', value: '${plan.maxUsers}'),
                          DetailTile(
                              label: 'MAX BRANCHES', value: plan.maxBranches),
                          DetailTile(
                              label: 'TRIAL', value: '${plan.trialDays} days'),
                          DetailTile(
                              label: 'STATUS',
                              value: plan.isActive ? 'Active' : 'Inactive',
                              valueColor: plan.isActive
                                  ? context.successColor
                                  : context.dangerColor),
                        ],
                      ),
                      if (plan.features.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Features',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textMutedColor)),
                        const SizedBox(height: 8),
                        ...plan.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.check_rounded,
                                      size: 16, color: color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(f,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: context.textSecondaryColor))),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showEditPlanDialog(plan);
                            },
                            child: Text('Edit'),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: context.bgColor,
                                  title: Text('Deactivate plan?'),
                                  content: Text(
                                      'This will deactivate the plan. It can be reactivated by editing.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: Text('Cancel')),
                                    TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: Text('Deactivate',
                                            style: TextStyle(
                                                color: context.dangerColor))),
                                  ],
                                ),
                              );
                              if (confirm == true && ctx.mounted) {
                                try {
                                  await _repo.deletePlan(plan.id);
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    _loadPlans();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Plan deactivated'),
                                          backgroundColor: context.successColor),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e.toString().replaceAll(
                                              'PlansException: ', '')),
                                          backgroundColor: context.dangerColor),
                                    );
                                  }
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: context.dangerColor),
                            child: Text('Deactivate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader(
      BuildContext ctx, String title, bool submitting, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.textColor)),
          IconButton(
            onPressed: submitting ? null : onClose,
            icon: Icon(Icons.close_rounded,
                size: 20, color: context.textMutedColor),
            style: IconButton.styleFrom(backgroundColor: context.cardHoverColor),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.dangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: context.dangerColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style:
                      TextStyle(fontSize: 13, color: context.dangerColor))),
        ],
      ),
    );
  }

  Color _planColor(String code) {
    switch (code.toLowerCase()) {
      case 'starter':
        return context.textMutedColor;
      case 'professional':
      case 'pro':
        return context.infoColor;
      case 'enterprise':
        return context.accentColor;
      default:
        return context.accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Subscription Plans',
            subtitle: 'Manage pricing and plan features',
            actionLabel: 'Create Plan',
            actionIcon: Icons.add_rounded,
            onAction: _showCreatePlanDialog,
          ),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _loadPlans, child: Text('Retry')),
                ],
              ),
            ),
          ],
          Row(
            children: [
              SizedBox(
                width: 280,
                child: AppSearchBar(
                  hint: 'Search plans...',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text('Active only',
                      style:
                          TextStyle(fontSize: 12, color: context.textMutedColor)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _activeOnly,
                    onChanged: (v) => setState(() {
                      _activeOnly = v;
                      _loadPlans();
                    }),
                    activeColor: context.accentColor,
                  ),
                ],
              ),
            ],
          ),
          if (_loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator()))
          else
            LayoutBuilder(builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 550
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  mainAxisExtent: 460,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _buildPlanCard(filtered[i]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan p) {
    final color = _planColor(p.planCode);
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: p.isActive ? color : context.textDimColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showViewPlanDialog(p),
                          borderRadius: BorderRadius.circular(8),
                          child: Text(
                            p.planName,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.textColor),
                          ),
                        ),
                      ),
                      if (!p.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.dangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Inactive',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.dangerColor)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${p.maxBranches} branches',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹${fmtNumber(p.price)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: context.textColor,
                              letterSpacing: -1),
                        ),
                        TextSpan(
                            text: '/year',
                            style: TextStyle(
                                fontSize: 13, color: context.textDimColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _metricBox('${p.maxUsers}', 'Users')),
                      const SizedBox(width: 8),
                      Expanded(child: _metricBox(p.maxBranches, 'Branches')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...(p.features.isEmpty ? ['—'] : p.features)
                      .take(5)
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 16, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(f,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: context.textSecondaryColor))),
                              ],
                            ),
                          )),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showViewPlanDialog(p),
                        child: Text('View'),
                      ),
                      TextButton(
                        onPressed: () => _showEditPlanDialog(p),
                        child: Text('Edit'),
                      ),
                    ],
                  ),
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
        color: context.cardHoverColor,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textColor)),
          Text(label,
              style: TextStyle(fontSize: 11, color: context.textDimColor)),
        ],
      ),
    );
  }
}
