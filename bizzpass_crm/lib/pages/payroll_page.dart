import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../data/payroll_repository.dart';
import '../data/mock_data.dart';
import 'payroll_settings_config_page.dart';

/// Main Payroll Management Page with tabs for Runs, Components, Settings
class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PayrollRepository _repo = PayrollRepository();
  final GlobalKey<_SalaryComponentsTabState> _componentsTabKey = GlobalKey<_SalaryComponentsTabState>();
  final GlobalKey<_SalaryModalsTabState> _salaryModalsTabKey = GlobalKey<_SalaryModalsTabState>();
  final GlobalKey<_OvertimeTemplatesTabState> _overtimeTemplatesTabKey = GlobalKey<_OvertimeTemplatesTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: Row(
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'Payroll Management',
                    subtitle: 'Manage salary structures, payroll runs, and reports',
                  ),
                ),
                if (_tabController.index == 0)
                  TextButton.icon(
                    onPressed: () => _showCreatePayrollRunDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Payroll Run'),
                  ),
                if (_tabController.index == 1)
                  TextButton.icon(
                    onPressed: () => _showCreateComponentDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Component'),
                  ),
                if (_tabController.index == 4)
                  TextButton.icon(
                    onPressed: () => _showCreateSalaryModalDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Salary Modal'),
                  ),
                if (_tabController.index == 5)
                  TextButton.icon(
                    onPressed: () => _showCreateOvertimeTemplateDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Template'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: context.accentColor,
                unselectedLabelColor: context.textMutedColor,
                indicatorColor: context.accentColor,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                onTap: (index) => setState(() {}),
                tabs: const [
                  Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'Payroll Runs'),
                  Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: 'Components'),
                  Tab(icon: Icon(Icons.settings_rounded, size: 20), text: 'Settings'),
                  Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Reports'),
                  Tab(icon: Icon(Icons.view_module_rounded, size: 20), text: 'Salary Modals'),
                  Tab(icon: Icon(Icons.schedule_rounded, size: 20), text: 'Overtime Templates'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PayrollRunsTab(repository: _repo),
                _SalaryComponentsTab(key: _componentsTabKey, repository: _repo),
                _PayrollSettingsTab(repository: _repo),
                _PayrollReportsTab(repository: _repo),
                _SalaryModalsTab(key: _salaryModalsTabKey, repository: _repo),
                _OvertimeTemplatesTab(key: _overtimeTemplatesTabKey, repository: _repo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePayrollRunDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _CreatePayrollRunDialog(repository: _repo),
    ).then((_) => setState(() {}));
  }

  void _showCreateComponentDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateSalaryComponentDialog(repository: _repo),
    ).then((created) {
      if (created == true) {
        _componentsTabKey.currentState?.refresh();
      }
      setState(() {});
    });
  }

  void _showCreateSalaryModalDialog() {
    _salaryModalsTabKey.currentState?.showCreateForm();
    setState(() {});
  }

  void _showCreateOvertimeTemplateDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _OvertimeTemplateFormDialog(repository: _repo),
    ).then((created) {
      if (created == true) _overtimeTemplatesTabKey.currentState?.refresh();
      setState(() {});
    });
  }
}

// ============================================================================
// TAB 1: PAYROLL RUNS
// ============================================================================

class _PayrollRunsTab extends StatefulWidget {
  final PayrollRepository repository;
  
  const _PayrollRunsTab({required this.repository});

  @override
  State<_PayrollRunsTab> createState() => _PayrollRunsTabState();
}

class _PayrollRunsTabState extends State<_PayrollRunsTab> {
  List<PayrollRun> _runs = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';

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
      final runs = await widget.repository.fetchPayrollRuns(
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      if (mounted) {
        setState(() {
          _runs = runs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTabBar(
                  tabs: [
                    TabItem(id: 'all', label: 'All Runs', count: _runs.length),
                    TabItem(
                      id: 'draft',
                      label: 'Draft',
                      count: _runs.where((r) => r.status == 'draft').length,
                    ),
                    TabItem(
                      id: 'calculated',
                      label: 'Calculated',
                      count: _runs.where((r) => r.status == 'calculated').length,
                    ),
                    TabItem(
                      id: 'approved',
                      label: 'Approved',
                      count: _runs.where((r) => r.status == 'approved').length,
                    ),
                    TabItem(
                      id: 'paid',
                      label: 'Paid',
                      count: _runs.where((r) => r.status == 'paid').length,
                    ),
                  ],
                  active: _statusFilter,
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textSecondaryColor)),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_runs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 64, color: context.textMutedColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No payroll runs yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first payroll run to process salaries',
                      style: TextStyle(fontSize: 13, color: context.textMutedColor),
                    ),
                  ],
                ),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Period'),
                DataCol('Status'),
                DataCol('Employees'),
                DataCol('Gross Salary'),
                DataCol('Deductions'),
                DataCol('Net Pay'),
                DataCol('Actions'),
              ],
              rows: _runs.map((run) {
                final monthName = DateFormat('MMMM yyyy').format(DateTime(run.year, run.month));
                return DataRow(
                  cells: [
                    DataCell(Text(monthName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(_buildStatusBadge(run.status)),
                    DataCell(Text(run.totalEmployees.toString())),
                    DataCell(Text('₹ ${_formatCurrency(run.totalGross)}')),
                    DataCell(Text('₹ ${_formatCurrency(run.totalDeductions)}')),
                    DataCell(Text(
                      '₹ ${_formatCurrency(run.totalNetPay)}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.successColor),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 20),
                          onPressed: () => _viewPayrollRun(run),
                          tooltip: 'View Details',
                        ),
                        if (run.status == 'draft' || run.status == 'calculated')
                          IconButton(
                            icon: Icon(Icons.play_arrow_rounded, size: 20, color: context.accentColor),
                            onPressed: () => _processPayrollRun(run),
                            tooltip: run.status == 'draft' ? 'Calculate' : 'Approve',
                          ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'draft':
        color = context.textMutedColor;
        label = 'Draft';
        break;
      case 'processing':
        color = context.infoColor;
        label = 'Processing';
        break;
      case 'calculated':
        color = context.warningColor;
        label = 'Calculated';
        break;
      case 'approved':
        color = context.accentColor;
        label = 'Approved';
        break;
      case 'paid':
        color = context.successColor;
        label = 'Paid';
        break;
      case 'cancelled':
        color = context.dangerColor;
        label = 'Cancelled';
        break;
      default:
        color = context.textMutedColor;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return formatter.format(amount);
  }

  void _viewPayrollRun(PayrollRun run) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PayrollRunDetailsPage(
          runId: run.id,
          repository: widget.repository,
        ),
      ),
    ).then((_) => _load());
  }

  void _processPayrollRun(PayrollRun run) async {
    if (run.status == 'draft') {
      // Calculate payroll
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        await widget.repository.calculatePayrollRun(run.id);
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payroll calculated successfully')),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    } else if (run.status == 'calculated') {
      // Approve payroll
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approve Payroll?'),
          content: Text(
            'Are you sure you want to approve payroll for ${DateFormat('MMMM yyyy').format(DateTime(run.year, run.month))}?\n\n'
            'Total: ₹ ${_formatCurrency(run.totalNetPay)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        try {
          await widget.repository.approvePayrollRun(run.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payroll approved successfully')),
            );
            _load();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        }
      }
    }
  }
}

// ============================================================================
// TAB 2: SALARY COMPONENTS
// ============================================================================

class _SalaryComponentsTab extends StatefulWidget {
  final PayrollRepository repository;

  const _SalaryComponentsTab({super.key, required this.repository});

  @override
  State<_SalaryComponentsTab> createState() => _SalaryComponentsTabState();
}

class _SalaryComponentsTabState extends State<_SalaryComponentsTab> {
  List<SalaryComponent> _components = [];
  bool _loading = true;
  String? _error;
  String _typeFilter = 'all';

  /// Set to true to show delete icon (hidden for now).
  static const bool _showDeleteComponent = false;

  // Overtime tab state
  String _overtimeMethod = 'fixed_amount';
  final _overtimeFixedAmountController = TextEditingController(text: '0');
  final _overtimeGrossMultiplierController = TextEditingController(text: '1.5');
  final _overtimeBasicMultiplierController = TextEditingController(text: '1.5');
  bool _overtimeLoading = false;
  bool _overtimeSaving = false;

  @override
  void dispose() {
    _overtimeFixedAmountController.dispose();
    _overtimeGrossMultiplierController.dispose();
    _overtimeBasicMultiplierController.dispose();
    super.dispose();
  }

  /// Call this after adding/editing/deleting a component to refresh the list.
  void refresh() => _load();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_typeFilter == 'overtime') {
      _loadOvertimeSettings();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final components = await widget.repository.fetchSalaryComponents(
        type: _typeFilter == 'all' ? null : _typeFilter,
      );
      if (mounted) {
        setState(() {
          _components = components;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  Future<void> _loadOvertimeSettings() async {
    setState(() => _overtimeLoading = true);
    try {
      final res = await widget.repository.fetchPayrollSettings();
      final settings = res['settings'] as Map<String, dynamic>? ?? res;
      if (mounted) {
        final method = (settings['overtime_calculation_method'] ?? settings['overtimeCalculationMethod'] ?? 'fixed_amount') as String;
        setState(() {
          _overtimeMethod = method;
          _overtimeFixedAmountController.text = _numberFrom(settings['overtime_fixed_amount_per_hour'] ?? settings['overtimeFixedAmountPerHour']).toStringAsFixed(2);
          _overtimeGrossMultiplierController.text = _numberFrom(settings['overtime_gross_pay_multiplier'] ?? settings['overtimeGrossPayMultiplier'], 1.5).toStringAsFixed(2);
          _overtimeBasicMultiplierController.text = _numberFrom(settings['overtime_basic_pay_multiplier'] ?? settings['overtimeBasicPayMultiplier'], 1.5).toStringAsFixed(2);
          _overtimeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _overtimeLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  double _numberFrom(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  Future<void> _saveOvertimeSettings() async {
    setState(() => _overtimeSaving = true);
    try {
      final fixed = double.tryParse(_overtimeFixedAmountController.text.trim()) ?? 0;
      final grossMult = double.tryParse(_overtimeGrossMultiplierController.text.trim()) ?? 1.5;
      final basicMult = double.tryParse(_overtimeBasicMultiplierController.text.trim()) ?? 1.5;
      await widget.repository.saveOvertimeSettings(
        overtimeCalculationMethod: _overtimeMethod,
        overtimeFixedAmountPerHour: _overtimeMethod == 'fixed_amount' ? fixed : null,
        overtimeGrossPayMultiplier: _overtimeMethod == 'gross_pay_multiplier' ? grossMult : null,
        overtimeBasicPayMultiplier: _overtimeMethod == 'basic_pay_multiplier' ? basicMult : null,
      );
      if (mounted) {
        setState(() => _overtimeSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Overtime settings saved'), backgroundColor: context.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _overtimeSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _components.where((c) => c.type == 'earning').toList();
    final deductions = _components.where((c) => c.type == 'deduction').toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTabBar(
            tabs: [
              TabItem(id: 'all', label: 'All', count: _components.length),
              TabItem(id: 'earning', label: 'Earnings', count: earnings.length),
              TabItem(id: 'deduction', label: 'Deductions', count: deductions.length),
              const TabItem(id: 'overtime', label: 'Overtime'),
            ],
            active: _typeFilter,
            onChanged: (v) {
              setState(() => _typeFilter = v);
              _load();
            },
          ),
          const SizedBox(height: 16),
          if (_typeFilter == 'overtime') _buildOvertimeForm(),
          if (_typeFilter != 'overtime') ...[
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
                  Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textSecondaryColor)),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ],
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_components.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 64, color: context.textMutedColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No salary components defined',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add earnings and deductions to build salary structures',
                      style: TextStyle(fontSize: 13, color: context.textMutedColor),
                    ),
                  ],
                ),
              ),
            )
          else
            AppDataTable(
              columns: const [
                DataCol('Component Name'),
                DataCol('Type'),
                DataCol('Category'),
                DataCol('Calculation Type'),
                DataCol('Value'),
                DataCol('Statutory'),
                DataCol('Status'),
                DataCol('Actions'),
              ],
              rows: _components.map((comp) {
                return DataRow(
                  cells: [
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comp.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(comp.name, style: TextStyle(fontSize: 11, color: context.textDimColor)),
                      ],
                    )),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: comp.type == 'earning' 
                            ? context.successColor.withOpacity(0.15)
                            : context.dangerColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        comp.type == 'earning' ? 'Earning' : 'Deduction',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: comp.type == 'earning' ? context.successColor : context.dangerColor,
                        ),
                      ),
                    )),
                    DataCell(Text(comp.category ?? '—')),
                    DataCell(Text(_formatCalculationType(comp.calculationType))),
                    DataCell(Text(_formatValue(comp.calculationType, comp.calculationValue))),
                    DataCell(comp.isStatutory 
                        ? Icon(Icons.check_circle_rounded, size: 18, color: context.accentColor)
                        : Icon(Icons.circle_outlined, size: 18, color: context.textMutedColor)),
                    DataCell(StatusBadge(status: comp.isActive ? 'active' : 'inactive')),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: comp.isActive ? 'Deactivate' : 'Activate',
                          child: Switch(
                            value: comp.isActive,
                            onChanged: (v) => _toggleComponentActive(comp),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editComponent(comp),
                          tooltip: 'Edit',
                        ),
                        if (_showDeleteComponent)
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor),
                            onPressed: () => _deleteComponent(comp),
                            tooltip: 'Delete',
                          ),
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOvertimeForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: _overtimeLoading
          ? const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Calculation for overtime',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
                ),
                const SizedBox(height: 20),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      const Text('Fixed amount of ₹ '),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _overtimeFixedAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Text(' is paid per overtime hour'),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Enter a specific amount to be paid for each overtime hour',
                      style: TextStyle(fontSize: 12, color: context.textMutedColor),
                    ),
                  ),
                  value: 'fixed_amount',
                  groupValue: _overtimeMethod,
                  onChanged: (v) => setState(() => _overtimeMethod = v!),
                ),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _overtimeGrossMultiplierController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Text(' Times of hourly gross pay is paid per overtime hour'),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Set the multiplier to calculate overtime pay based on the employee\'s gross pay. Formula: [((Gross Salary / Total Shift Hours) × Approved Overtime Hours) × Multiplier]',
                      style: TextStyle(fontSize: 12, color: context.textMutedColor),
                    ),
                  ),
                  value: 'gross_pay_multiplier',
                  groupValue: _overtimeMethod,
                  onChanged: (v) => setState(() => _overtimeMethod = v!),
                ),
                RadioListTile<String>(
                  title: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _overtimeBasicMultiplierController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Text(' Times of hourly basic pay is paid per overtime hour'),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Set the multiplier to calculate overtime pay based on Basic Pay + DA. Formula: [{(Basic Pay + DA) / Total shift hours} × Approved Overtime Hours] × Multiplier',
                      style: TextStyle(fontSize: 12, color: context.textMutedColor),
                    ),
                  ),
                  value: 'basic_pay_multiplier',
                  groupValue: _overtimeMethod,
                  onChanged: (v) => setState(() => _overtimeMethod = v!),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _overtimeSaving ? null : _saveOvertimeSettings,
                    child: _overtimeSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatCalculationType(String type) {
    switch (type) {
      case 'fixed_amount':
        return 'Fixed Amount';
      case 'percentage_of_basic':
        return '% of Basic';
      case 'percentage_of_gross':
        return '% of Gross';
      case 'formula':
        return 'Formula';
      case 'attendance_based':
        return 'Attendance Based';
      default:
        return type;
    }
  }

  String _formatValue(String calcType, double? value) {
    if (value == null) return '—';
    if (calcType.contains('percentage')) {
      return '${value.toStringAsFixed(2)}%';
    }
    return '₹ ${value.toStringAsFixed(2)}';
  }

  void _toggleComponentActive(SalaryComponent comp) async {
    try {
      await widget.repository.updateSalaryComponent(
        comp.id,
        name: comp.name,
        displayName: comp.displayName,
        type: comp.type,
        category: comp.category,
        calculationType: comp.calculationType,
        calculationValue: comp.calculationValue ?? 0,
        formula: comp.formula,
        isStatutory: comp.isStatutory,
        isTaxable: comp.isTaxable,
        affectsGross: comp.affectsGross,
        affectsNet: comp.affectsNet,
        minValue: comp.minValue,
        maxValue: comp.maxValue,
        appliesToCategories: comp.appliesToCategories,
        priorityOrder: comp.priorityOrder,
        isActive: !comp.isActive,
        remarks: comp.remarks,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(comp.isActive ? 'Component deactivated' : 'Component activated')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  void _editComponent(SalaryComponent comp) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _CreateSalaryComponentDialog(repository: widget.repository, component: comp),
    ).then((updated) {
      if (updated == true) refresh();
    });
  }

  void _deleteComponent(SalaryComponent comp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Component?'),
        content: Text('Are you sure you want to delete "${comp.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await widget.repository.deleteSalaryComponent(comp.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Component deleted')),
          );
          _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
}

// ============================================================================
// TAB 3: PAYROLL SETTINGS
// ============================================================================

class _PayrollSettingsTab extends StatefulWidget {
  final PayrollRepository repository;
  
  const _PayrollSettingsTab({required this.repository});

  @override
  State<_PayrollSettingsTab> createState() => _PayrollSettingsTabState();
}

class _PayrollSettingsTabState extends State<_PayrollSettingsTab> {
  bool _loading = true;
  bool _configured = false;
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
      final settings = await widget.repository.fetchPayrollSettings();
      if (mounted) {
        setState(() {
          _configured = settings['configured'] as bool? ?? false;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
        ),
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payroll Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _configured
                        ? 'Your payroll settings are configured. Click below to modify.'
                        : 'Configure your company payroll policies and rules.',
                    style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => PayrollSettingsConfigPage(repository: widget.repository),
                        ),
                      ).then((_) => _load());
                    },
                    icon: Icon(_configured ? Icons.edit_rounded : Icons.settings_rounded, size: 18),
                    label: Text(_configured ? 'Edit Settings' : 'Configure Settings'),
                  ),
                  if (!_configured) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.infoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.infoColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: context.infoColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please configure payroll settings before processing salaries. This includes working days, leave policies, statutory deductions, and more.',
                              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ============================================================================
// TAB 4: REPORTS
// ============================================================================

class _PayrollReportsTab extends StatelessWidget {
  final PayrollRepository repository;
  
  const _PayrollReportsTab({required this.repository});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payroll Reports',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate and export payroll reports for analysis',
                  style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
                ),
                const SizedBox(height: 24),
                Text('Coming Soon', style: TextStyle(fontSize: 16, color: context.textMutedColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB: SALARY MODALS (Templates: name, description, set of salary components)
// ============================================================================

class _SalaryModalsTab extends StatefulWidget {
  final PayrollRepository repository;

  const _SalaryModalsTab({super.key, required this.repository});

  @override
  State<_SalaryModalsTab> createState() => _SalaryModalsTabState();
}

class _SalaryModalsTabState extends State<_SalaryModalsTab> {
  List<SalaryModal> _modals = [];
  bool _loading = true;
  String? _error;
  bool _showForm = false;
  SalaryModal? _editingModal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  void showCreateForm() => setState(() { _showForm = true; _editingModal = null; });
  void showEditForm(SalaryModal modal) => setState(() { _showForm = true; _editingModal = modal; });

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repository.fetchSalaryModals(activeOnly: false);
      if (mounted) {
        setState(() {
          _modals = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  void _editModal(SalaryModal modal) => showEditForm(modal);

  Future<void> _deleteModal(SalaryModal modal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Salary Modal?'),
        content: Text('Are you sure you want to delete "${modal.name}"? This template can be assigned to departments or staff.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.repository.deleteSalaryModal(modal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary modal deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return _SalaryModalFormDialog(
        repository: widget.repository,
        modal: _editingModal,
        asPage: true,
        onBack: () => setState(() { _showForm = false; _editingModal = null; }),
        onSaved: () => setState(() { _showForm = false; _editingModal = null; _load(); }),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: context.warningColor),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.textColor)),
          ],
        ),
      );
    }
    if (_modals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.view_module_rounded, size: 64, color: context.textMutedColor.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No salary modals yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a template with name, description and salary components.\nAssign it to a department or to staff.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMutedColor),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      itemCount: _modals.length,
      itemBuilder: (context, index) {
        final m = _modals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: context.accentColor.withOpacity(0.2),
              child: Icon(Icons.view_module_rounded, color: context.accentColor),
            ),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              m.description?.isNotEmpty == true ? m.description! : '${m.components.length} component(s)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editModal(m),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: context.dangerColor),
                  onPressed: () => _deleteModal(m),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Dialog: Create / Edit Salary Modal (name, description, add many components)
// ============================================================================

class _SalaryModalFormDialog extends StatefulWidget {
  final PayrollRepository repository;
  final SalaryModal? modal;
  /// When true, render as full page (Scaffold + AppBar + back) instead of dialog; sidebar stays visible.
  final bool asPage;
  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  const _SalaryModalFormDialog({
    required this.repository,
    this.modal,
    this.asPage = false,
    this.onBack,
    this.onSaved,
  });

  @override
  State<_SalaryModalFormDialog> createState() => _SalaryModalFormDialogState();
}

class _SalaryModalFormDialogState extends State<_SalaryModalFormDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  List<SalaryComponent> _allComponents = [];
  List<int> _selectedComponentIds = [];
  /// Overrides per component (for this template). Key = componentId.
  final Map<int, String?> _typeOverride = {};
  final Map<int, String?> _calculationTypeOverride = {};
  final Map<int, double?> _valueOverride = {};
  final Map<int, bool?> _taxableOverride = {};
  final Map<int, bool?> _statutoryOverride = {};
  /// Controllers for value override per component (created when component is in selection).
  final Map<int, TextEditingController> _valueControllers = {};
  static const List<String> _typeOptions = ['earning', 'deduction'];
  static const List<String> _calculationTypeOptions = ['fixed_amount', 'percentage_of_basic', 'percentage_of_gross', 'formula', 'attendance_based'];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.modal != null) {
      _nameController.text = widget.modal!.name;
      _descController.text = widget.modal!.description ?? '';
      _selectedComponentIds = widget.modal!.components.map((c) => c.componentId).toList();
      for (final c in widget.modal!.components) {
        if (c.typeOverride != null) _typeOverride[c.componentId] = c.typeOverride;
        if (c.calculationTypeOverride != null) _calculationTypeOverride[c.componentId] = c.calculationTypeOverride;
        if (c.calculationValueOverride != null) _valueOverride[c.componentId] = c.calculationValueOverride;
        if (c.isTaxableOverride != null) _taxableOverride[c.componentId] = c.isTaxableOverride;
        if (c.isStatutoryOverride != null) _statutoryOverride[c.componentId] = c.isStatutoryOverride;
      }
    }
    _loadComponents();
  }

  void _ensureValueControllers() {
    // One controller per component (all shown in row 1); clean up ids no longer in list
    final ids = Set<int>.from(_allComponents.map((e) => e.id));
    for (final id in _valueControllers.keys.toList()) {
      if (!ids.contains(id)) {
        _valueControllers[id]?.dispose();
        _valueControllers.remove(id);
      }
    }
    for (final id in ids) {
      if (!_valueControllers.containsKey(id)) {
        final comp = _allComponents.where((c) => c.id == id).firstOrNull;
        final initial = _valueOverride[id]?.toString() ?? comp?.calculationValue?.toString() ?? '';
        _valueControllers[id] = TextEditingController(text: initial);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _valueControllers.values) c.dispose();
    _valueControllers.clear();
    super.dispose();
  }

  Future<void> _loadComponents() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await widget.repository.fetchSalaryComponents();
      if (mounted) {
        setState(() {
          _allComponents = list;
          _loading = false;
          _ensureValueControllers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Modal name is required');
      return;
    }
    // Order selected components as they appear in the list
    final orderedIds = _allComponents.where((c) => _selectedComponentIds.contains(c.id)).map((c) => c.id).toList();
    final components = orderedIds.asMap().entries.map((e) {
      final compId = e.value;
      final order = e.key;
      final valueText = _valueControllers[compId]?.text.trim() ?? '';
      final parsed = valueText.isEmpty ? null : double.tryParse(valueText);
      return PayrollRepository.salaryModalComponent(
        componentId: compId,
        displayOrder: order,
        typeOverride: _typeOverride[compId],
        calculationTypeOverride: _calculationTypeOverride[compId],
        calculationValueOverride: parsed,
        isTaxableOverride: _taxableOverride[compId],
        isStatutoryOverride: _statutoryOverride[compId],
      );
    }).toList();
    setState(() { _saving = true; _error = null; });
    try {
      if (widget.modal != null) {
        await widget.repository.updateSalaryModal(
          widget.modal!.id,
          name: name,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          components: components,
        );
      } else {
        await widget.repository.createSalaryModal(
          name: name,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          components: components,
        );
      }
      if (mounted) {
        if (widget.asPage && widget.onSaved != null) {
          widget.onSaved!();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.modal != null ? 'Salary modal updated' : 'Salary modal created')),
          );
        } else if (!widget.asPage) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.modal != null ? 'Salary modal updated' : 'Salary modal created')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  void _toggleComponent(int componentId) {
    setState(() {
      if (_selectedComponentIds.contains(componentId)) {
        _selectedComponentIds.remove(componentId);
      } else {
        _selectedComponentIds.add(componentId);
      }
      _ensureValueControllers();
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedComponentIds = _allComponents.map((e) => e.id).toList();
      } else {
        _selectedComponentIds = [];
      }
      _ensureValueControllers();
    });
  }

  bool _effectiveTaxable(int compId, SalaryComponent? comp) {
    if (_taxableOverride.containsKey(compId) && _taxableOverride[compId] != null) return _taxableOverride[compId]!;
    return comp?.isTaxable ?? true;
  }

  bool _effectiveStatutory(int compId, SalaryComponent? comp) {
    if (_statutoryOverride.containsKey(compId) && _statutoryOverride[compId] != null) return _statutoryOverride[compId]!;
    return comp?.isStatutory ?? false;
  }

  String _effectiveCalculationType(int compId, SalaryComponent? comp) => _calculationTypeOverride[compId] ?? comp?.calculationType ?? 'fixed_amount';

  String _calculationTypeLabel(String v) {
    switch (v) {
      case 'fixed_amount': return 'Fixed amount';
      case 'percentage_of_basic': return '% of Basic';
      case 'percentage_of_gross': return '% of Gross';
      case 'formula': return 'Formula';
      case 'attendance_based': return 'Attendance based';
      default: return v;
    }
  }

  String _safeTypeValue(int compId, SalaryComponent? c) {
    final v = (_typeOverride[compId] ?? c?.type ?? 'earning').toString().toLowerCase();
    return _typeOptions.contains(v) ? v : _typeOptions.first;
  }

  String _safeCalculationTypeValue(int compId, SalaryComponent? c) {
    final v = (_calculationTypeOverride[compId] ?? c?.calculationType ?? 'fixed_amount').toString().toLowerCase();
    return _calculationTypeOptions.contains(v) ? v : _calculationTypeOptions.first;
  }

  Widget _buildFormContent(BuildContext context, Color textColor, Color textMutedColor, Color warningColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: warningColor, fontSize: 13)),
          ),
        ],
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Modal name',
            hintText: 'e.g. IT Department Structure',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'Describe this salary template',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Text('Salary components', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
        const SizedBox(height: 6),
        Text(
          'First row: component name, type, calculation type, value. Second row: include in template, taxable, statutory.',
          style: TextStyle(fontSize: 11, color: textMutedColor),
        ),
        const SizedBox(height: 8),
        if (_allComponents.isNotEmpty)
          CheckboxListTile(
            value: _selectedComponentIds.isEmpty
                ? false
                : (_selectedComponentIds.length == _allComponents.length ? true : null),
            tristate: true,
            onChanged: (v) => _toggleSelectAll(v == true),
            title: Text('Select all', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        const SizedBox(height: 4),
        if (_allComponents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No salary components found. Add components in the Salary Components tab first.',
              style: TextStyle(fontSize: 12, color: textMutedColor),
            ),
          ),
        ..._allComponents.map((c) {
          final compId = c.id;
          final selected = _selectedComponentIds.contains(compId);
          final isPercent = _effectiveCalculationType(compId, c).contains('percentage');
          final valueHint = isPercent ? 'e.g. 40' : 'Amt';
          final valueController = _valueControllers[compId];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: DropdownButtonFormField<String>(
                            value: _safeTypeValue(compId, c),
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            isExpanded: true,
                            items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t == 'earning' ? 'Earning' : 'Deduction', overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _typeOverride[compId] = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: DropdownButtonFormField<String>(
                            value: _safeCalculationTypeValue(compId, c),
                            decoration: const InputDecoration(
                              labelText: 'Calc type',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            isExpanded: true,
                            items: _calculationTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(_calculationTypeLabel(t), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _calculationTypeOverride[compId] = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: valueController != null
                            ? TextField(
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: isPercent ? '%' : 'Val',
                                  hintText: valueHint,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                ),
                                controller: valueController,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CheckboxListTile(
                        value: selected,
                        onChanged: (_) => _toggleComponent(compId),
                        title: const Text('Include in template', style: TextStyle(fontSize: 12)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(width: 16),
                      CheckboxListTile(
                        value: _effectiveTaxable(compId, c),
                        onChanged: (v) => setState(() => _taxableOverride[compId] = v),
                        title: const Text('Taxable', style: TextStyle(fontSize: 12)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      CheckboxListTile(
                        value: _effectiveStatutory(compId, c),
                        onChanged: (v) => setState(() => _statutoryOverride[compId] = v),
                        title: const Text('Statutory', style: TextStyle(fontSize: 12)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const minContentHeight = 360.0;
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final textMutedColor = theme.colorScheme.onSurfaceVariant;
    final warningColor = theme.colorScheme.error;

    if (widget.asPage) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _saving ? null : () {
              if (widget.onBack != null) widget.onBack!();
            },
          ),
          title: Text(widget.modal != null ? 'Edit Salary Modal' : 'Create Salary Modal'),
          actions: [
            TextButton(
              onPressed: _saving ? null : () { if (widget.onBack != null) widget.onBack!(); },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: minContentHeight),
                  child: _buildFormContent(context, textColor, textMutedColor, warningColor),
                ),
              ),
      );
    }

    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    return AlertDialog(
      title: Text(widget.modal != null ? 'Edit Salary Modal' : 'Create Salary Modal'),
      content: SizedBox(
        width: 500,
        height: _loading ? minContentHeight : null,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500, minHeight: minContentHeight, maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: _buildFormContent(context, textColor, textMutedColor, warningColor),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 6: OVERTIME TEMPLATES (Customizable templates for all companies)
// ============================================================================

class _OvertimeTemplatesTab extends StatefulWidget {
  final PayrollRepository repository;

  const _OvertimeTemplatesTab({super.key, required this.repository});

  @override
  State<_OvertimeTemplatesTab> createState() => _OvertimeTemplatesTabState();
}

class _OvertimeTemplatesTabState extends State<_OvertimeTemplatesTab> {
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Expose for parent to refresh list after add.
  void refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repository.fetchOvertimeTemplates();
      if (mounted) {
        setState(() {
          _templates = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('PayrollException: ', '');
        });
      }
    }
  }

  void _editTemplate(Map<String, dynamic> template) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => _OvertimeTemplateFormDialog(
        repository: widget.repository,
        template: template,
      ),
    ).then((updated) {
      if (updated == true) _load();
    });
  }

  Future<void> _setDefault(int id) async {
    try {
      await widget.repository.setDefaultOvertimeTemplate(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default template updated')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteTemplate(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: context.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.repository.deleteOvertimeTemplate(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: context.warningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textSecondaryColor))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
          else if (_templates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 64, color: context.textMutedColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No overtime templates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor)),
                    const SizedBox(height: 8),
                    Text('Create customizable templates (calculation method, multipliers, caps, approval).', style: TextStyle(fontSize: 13, color: context.textMutedColor)),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: _templates.map((t) {
                  final id = t['id'] as int?;
                  final name = t['name'] as String? ?? '';
                  final companyType = (t['companyType'] as String? ?? 'custom').toString();
                  final isDefault = t['isDefault'] == true;
                  final config = t['config'] as Map<String, dynamic>? ?? {};
                  final rules = config['overtimeRules'] as Map<String, dynamic>? ?? {};
                  final base = rules['calculationBase'] as String? ?? 'gross_salary';
                  final caps = rules['caps'] as Map<String, dynamic>? ?? {};
                  final monthlyCap = caps['monthly'] ?? 60;
                  return ListTile(
                    title: Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.accentColor)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('$companyType • $base • max ${monthlyCap}h/month'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDefault && id != null)
                          TextButton(
                            onPressed: () => _setDefault(id),
                            child: const Text('Set default'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editTemplate(t),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 20, color: context.dangerColor),
                          onPressed: id != null ? () => _deleteTemplate(id, name) : null,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOG: CREATE / EDIT OVERTIME TEMPLATE (Level 1–3 customizable)
// ============================================================================

class _OvertimeTemplateFormDialog extends StatefulWidget {
  final PayrollRepository repository;
  final Map<String, dynamic>? template;

  const _OvertimeTemplateFormDialog({required this.repository, this.template});

  bool get isEditMode => template != null;

  @override
  State<_OvertimeTemplateFormDialog> createState() => _OvertimeTemplateFormDialogState();
}

class _OvertimeTemplateFormDialogState extends State<_OvertimeTemplateFormDialog> {
  final _nameController = TextEditingController();
  String _companyType = 'custom';
  String _calculationBase = 'gross_salary';
  final _fixedAmountController = TextEditingController(text: '0');
  final _grossPctController = TextEditingController(text: '100');
  final _basicDaPctController = TextEditingController(text: '100');
  // Combination: higher of fixed OR percentage
  final _combinationFixedController = TextEditingController(text: '0');
  String _combinationPercentageOf = 'gross_salary';
  final _combinationPctController = TextEditingController(text: '100');
  final _weekdayController = TextEditingController(text: '1.5');
  final _saturdayController = TextEditingController(text: '1.75');
  final _sundayController = TextEditingController(text: '2');
  final _holidayController = TextEditingController(text: '2.5');
  final _nightShiftController = TextEditingController(text: '1.75');
  final _doubleShiftController = TextEditingController(text: '2');
  final _capDailyController = TextEditingController(text: '4');
  final _capWeeklyController = TextEditingController(text: '20');
  final _capMonthlyController = TextEditingController(text: '60');
  final _minServiceDaysController = TextEditingController(text: '30');
  final _minHoursForOTController = TextEditingController(text: '1');
  bool _approvalRequired = true;
  final _approvalLevelsController = TextEditingController(text: '2');
  final _autoApproveUpToController = TextEditingController(text: '10');
  bool _payInSalary = true;
  bool _compensatoryOff = false;
  final _carryForwardController = TextEditingController(text: '5');
  final _lapseAfterController = TextEditingController(text: '90');
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _nameController.text = (t['name'] as String? ?? '').toString();
      _companyType = (t['companyType'] as String? ?? 'custom').toString();
      _isDefault = t['isDefault'] == true;
      final config = t['config'] as Map<String, dynamic>? ?? {};
      final rules = config['overtimeRules'] as Map<String, dynamic>? ?? {};
      _calculationBase = (rules['calculationBase'] as String? ?? 'gross_salary').toString();
      _fixedAmountController.text = _numStr(rules['fixedAmountPerHour']);
      _grossPctController.text = _numStr(rules['grossPercentage'], 100);
      _basicDaPctController.text = _numStr(rules['basicDaPercentage'], 100);
      _combinationFixedController.text = _numStr(rules['combinationFixedAmount'], 0);
      _combinationPercentageOf = (rules['combinationPercentageOf'] as String? ?? 'gross_salary').toString();
      _combinationPctController.text = _numStr(rules['combinationPercentage'], 100);
      final tr = rules['tieredRates'] as Map<String, dynamic>? ?? {};
      _weekdayController.text = _numStr(tr['weekday'], 1.5);
      _saturdayController.text = _numStr(tr['saturday'], 1.75);
      _sundayController.text = _numStr(tr['sunday'], 2);
      _holidayController.text = _numStr(tr['holiday'], 2.5);
      _nightShiftController.text = _numStr(tr['nightShift'], 1.75);
      _doubleShiftController.text = _numStr(tr['doubleShift'], 2);
      final caps = rules['caps'] as Map<String, dynamic>? ?? {};
      _capDailyController.text = _numStr(caps['daily'], 4);
      _capWeeklyController.text = _numStr(caps['weekly'], 20);
      _capMonthlyController.text = _numStr(caps['monthly'], 60);
      final elig = rules['eligibility'] as Map<String, dynamic>? ?? {};
      _minServiceDaysController.text = _numStr(elig['minServiceDays'], 30);
      _minHoursForOTController.text = _numStr(elig['minHoursForOT'], 1);
      final appr = rules['approvalWorkflow'] as Map<String, dynamic>? ?? {};
      _approvalRequired = appr['required'] != false;
      _approvalLevelsController.text = _numStr(appr['levels'], 2);
      _autoApproveUpToController.text = _numStr(appr['autoApproveUpTo'], 10);
      final pay = rules['paymentOptions'] as Map<String, dynamic>? ?? {};
      _payInSalary = pay['payInSalary'] != false;
      _compensatoryOff = pay['compensatoryOff'] == true;
      _carryForwardController.text = _numStr(pay['carryForward'], 5);
      _lapseAfterController.text = _numStr(pay['lapseAfter'], 90);
    }
  }

  String _numStr(dynamic v, [num def = 0]) {
    if (v == null) return def.toString();
    if (v is num) return v.toString();
    return v.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fixedAmountController.dispose();
    _grossPctController.dispose();
    _basicDaPctController.dispose();
    _combinationFixedController.dispose();
    _combinationPctController.dispose();
    _weekdayController.dispose();
    _saturdayController.dispose();
    _sundayController.dispose();
    _holidayController.dispose();
    _nightShiftController.dispose();
    _doubleShiftController.dispose();
    _capDailyController.dispose();
    _capWeeklyController.dispose();
    _capMonthlyController.dispose();
    _minServiceDaysController.dispose();
    _minHoursForOTController.dispose();
    _approvalLevelsController.dispose();
    _autoApproveUpToController.dispose();
    _carryForwardController.dispose();
    _lapseAfterController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildConfig() {
    return {
      'companyType': _companyType,
      'overtimeRules': {
        'calculationBase': _calculationBase,
        'defaultMultiplier': double.tryParse(_weekdayController.text) ?? 1.5,
        'fixedAmountPerHour': _calculationBase == 'fixed_amount' ? (double.tryParse(_fixedAmountController.text) ?? 0) : null,
        'grossPercentage': _calculationBase == 'gross_salary' ? (double.tryParse(_grossPctController.text) ?? 100) : null,
        'basicDaPercentage': _calculationBase == 'basic_da' ? (double.tryParse(_basicDaPctController.text) ?? 100) : null,
        'combinationRule': _calculationBase == 'combination' ? 'higher_of' : null,
        'combinationFixedAmount': _calculationBase == 'combination' ? (double.tryParse(_combinationFixedController.text) ?? 0) : null,
        'combinationPercentageOf': _calculationBase == 'combination' ? _combinationPercentageOf : null,
        'combinationPercentage': _calculationBase == 'combination' ? (double.tryParse(_combinationPctController.text) ?? 100) : null,
        'tieredRates': {
          'weekday': double.tryParse(_weekdayController.text) ?? 1.5,
          'saturday': double.tryParse(_saturdayController.text) ?? 1.75,
          'sunday': double.tryParse(_sundayController.text) ?? 2,
          'holiday': double.tryParse(_holidayController.text) ?? 2.5,
          'nightShift': double.tryParse(_nightShiftController.text) ?? 1.75,
          'doubleShift': double.tryParse(_doubleShiftController.text) ?? 2,
        },
        'caps': {
          'daily': int.tryParse(_capDailyController.text) ?? 4,
          'weekly': int.tryParse(_capWeeklyController.text) ?? 20,
          'monthly': int.tryParse(_capMonthlyController.text) ?? 60,
        },
        'eligibility': {
          'minServiceDays': int.tryParse(_minServiceDaysController.text) ?? 30,
          'excludeEmployees': [],
          'excludeRoles': ['trainees', 'interns'],
          'minHoursForOT': double.tryParse(_minHoursForOTController.text) ?? 1,
        },
        'approvalWorkflow': {
          'required': _approvalRequired,
          'levels': int.tryParse(_approvalLevelsController.text) ?? 2,
          'autoApproveUpTo': double.tryParse(_autoApproveUpToController.text) ?? 10,
        },
        'paymentOptions': {
          'payInSalary': _payInSalary,
          'compensatoryOff': _compensatoryOff,
          'carryForward': int.tryParse(_carryForwardController.text) ?? 5,
          'lapseAfter': int.tryParse(_lapseAfterController.text) ?? 90,
        },
      },
    };
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final config = _buildConfig();
      if (widget.isEditMode && widget.template != null) {
        await widget.repository.updateOvertimeTemplate(
          widget.template!['id'] as int,
          name: name,
          companyType: _companyType,
          isDefault: _isDefault,
          config: config,
        );
      } else {
        await widget.repository.createOvertimeTemplate(
          name: name,
          companyType: _companyType,
          isDefault: _isDefault,
          config: config,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditMode ? 'Template updated' : 'Template created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditMode ? 'Edit Overtime Template' : 'Add Overtime Template'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _companyType,
                decoration: const InputDecoration(
                  labelText: 'Company Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  DropdownMenuItem(value: 'manufacturing', child: Text('Manufacturing')),
                  DropdownMenuItem(value: 'it', child: Text('IT')),
                  DropdownMenuItem(value: 'healthcare', child: Text('Healthcare')),
                  DropdownMenuItem(value: 'retail', child: Text('Retail')),
                  DropdownMenuItem(value: 'corporate', child: Text('Corporate')),
                ],
                onChanged: (v) => setState(() => _companyType = v!),
              ),
              const SizedBox(height: 16),
              Text('Level 1: Calculation Base', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 8),
              ...['fixed_amount', 'gross_salary', 'basic_da', 'combination', 'tiered_rates'].map((v) {
                final labels = {
                  'fixed_amount': 'Fixed Amount (Per Hour)',
                  'gross_salary': 'Percentage of Gross Salary',
                  'basic_da': 'Percentage of Basic + DA',
                  'combination': 'Combination (Higher of Fixed OR Percentage)',
                  'tiered_rates': 'Tiered Rates (Weekdays/Weekends/Holidays)',
                };
                return RadioListTile<String>(
                  title: Text(labels[v] ?? v, style: const TextStyle(fontSize: 13)),
                  value: v,
                  groupValue: _calculationBase,
                  onChanged: (val) => setState(() => _calculationBase = val!),
                  dense: true,
                );
              }),
              if (_calculationBase == 'fixed_amount') ...[
                const SizedBox(height: 4),
                TextField(
                  controller: _fixedAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fixed amount per hour (₹)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
              if (_calculationBase == 'gross_salary')
                TextField(
                  controller: _grossPctController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Percentage of gross',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              if (_calculationBase == 'basic_da')
                TextField(
                  controller: _basicDaPctController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Percentage of Basic + DA',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              if (_calculationBase == 'combination') ...[
                const SizedBox(height: 8),
                Text('Higher of: Fixed amount per hour OR percentage of chosen base.', style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                const SizedBox(height: 6),
                TextField(
                  controller: _combinationFixedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Fixed amount per hour (₹)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _combinationPercentageOf,
                        decoration: const InputDecoration(
                          labelText: 'Percentage of',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'gross_salary', child: Text('Gross Salary')),
                          DropdownMenuItem(value: 'basic_da', child: Text('Basic + DA')),
                        ],
                        onChanged: (v) => setState(() => _combinationPercentageOf = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _combinationPctController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Percentage (%)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text('Level 2: Multipliers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 8),
              _multRow('Weekday', _weekdayController, '1.25× - 2.00×'),
              _multRow('Saturday', _saturdayController, '1.50× - 2.50×'),
              _multRow('Sunday', _sundayController, '1.50× - 2.50×'),
              _multRow('Holiday', _holidayController, '2.00× - 3.00×'),
              _multRow('Night Shift', _nightShiftController, '1.50× - 2.25×'),
              _multRow('Double Shift', _doubleShiftController, '1.75× - 2.50×'),
              const SizedBox(height: 16),
              Text('Level 3: Caps & Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _capDailyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max hours/day', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _capWeeklyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max hours/week', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _capMonthlyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max hours/month', isDense: true, border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _minServiceDaysController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min service days', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _minHoursForOTController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min hours for OT', isDense: true, border: OutlineInputBorder()))),
                ],
              ),
              CheckboxListTile(
                title: const Text('Approval required'),
                value: _approvalRequired,
                onChanged: (v) => setState(() => _approvalRequired = v!),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_approvalRequired)
                Row(
                  children: [
                  Expanded(child: TextField(controller: _approvalLevelsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Approval levels', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _autoApproveUpToController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Auto-approve up to (hours)', isDense: true, border: OutlineInputBorder()))),
                ],
                ),
              CheckboxListTile(title: const Text('Pay in salary'), value: _payInSalary, onChanged: (v) => setState(() => _payInSalary = v!), dense: true, controlAffinity: ListTileControlAffinity.leading),
              CheckboxListTile(title: const Text('Compensatory off option'), value: _compensatoryOff, onChanged: (v) => setState(() => _compensatoryOff = v!), dense: true, controlAffinity: ListTileControlAffinity.leading),
              Row(
                children: [
                  Expanded(child: TextField(controller: _carryForwardController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carry forward (hours)', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _lapseAfterController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lapse after (days)', isDense: true, border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Set as company default template'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v!),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.isEditMode ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _multRow(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: context.textColor))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOG: CREATE PAYROLL RUN
// ============================================================================

class _CreatePayrollRunDialog extends StatefulWidget {
  final PayrollRepository repository;
  
  const _CreatePayrollRunDialog({required this.repository});

  @override
  State<_CreatePayrollRunDialog> createState() => _CreatePayrollRunDialogState();
}

class _CreatePayrollRunDialogState extends State<_CreatePayrollRunDialog> {
  final _monthController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _remarksController = TextEditingController();
  bool _saving = false;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _monthController.text = DateFormat('MMMM').format(DateTime(2025, _selectedMonth));
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Payroll Run'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: List.generate(12, (i) => i + 1).map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat('MMMM').format(DateTime(2025, month))),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMonth = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final year = int.tryParse(_yearController.text.trim());
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid year')),
      );
      return;
    }

    setState(() => _saving = true);
    
    try {
      final startDate = DateTime(year, _selectedMonth, 1);
      final endDate = DateTime(year, _selectedMonth + 1, 0);
      
      await widget.repository.createPayrollRun(
        month: _selectedMonth,
        year: year,
        payPeriodStart: DateFormat('yyyy-MM-dd').format(startDate),
        payPeriodEnd: DateFormat('yyyy-MM-dd').format(endDate),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll run created')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }
}

// ============================================================================
// DIALOG: CREATE SALARY COMPONENT
// ============================================================================

class _CreateSalaryComponentDialog extends StatefulWidget {
  final PayrollRepository repository;
  final SalaryComponent? component;

  const _CreateSalaryComponentDialog({required this.repository, this.component});

  bool get isEditMode => component != null;

  @override
  State<_CreateSalaryComponentDialog> createState() => _CreateSalaryComponentDialogState();
}

class _CreateSalaryComponentDialogState extends State<_CreateSalaryComponentDialog> {
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _valueController = TextEditingController();

  String _type = 'earning';
  String _calculationType = 'fixed_amount';
  bool _isStatutory = false;
  bool _isTaxable = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    if (c != null) {
      _nameController.text = c.name;
      _displayNameController.text = c.displayName;
      _valueController.text = (c.calculationValue ?? 0).toStringAsFixed(2);
      _type = c.type;
      _calculationType = c.calculationType;
      _isStatutory = c.isStatutory;
      _isTaxable = c.isTaxable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditMode ? 'Edit Salary Component' : 'Add Salary Component'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Component Name *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'earning', child: Text('Earning')),
                        DropdownMenuItem(value: 'deduction', child: Text('Deduction')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _calculationType,
                      decoration: const InputDecoration(
                        labelText: 'Calculation Type *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'fixed_amount', child: Text('Fixed Amount')),
                        DropdownMenuItem(value: 'percentage_of_basic', child: Text('% of Basic')),
                        DropdownMenuItem(value: 'percentage_of_gross', child: Text('% of Gross')),
                      ],
                      onChanged: (v) => setState(() => _calculationType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _calculationType.contains('percentage') ? 'Percentage (%) *' : 'Amount (₹) *',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Statutory Component'),
                value: _isStatutory,
                onChanged: (v) => setState(() => _isStatutory = v!),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Taxable'),
                value: _isTaxable,
                onChanged: (v) => setState(() => _isTaxable = v!),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.isEditMode ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _displayNameController.text.trim().isEmpty ||
        _valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid value')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.isEditMode && widget.component != null) {
        final comp = widget.component!;
        await widget.repository.updateSalaryComponent(
          comp.id,
          name: _nameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          type: _type,
          category: comp.category,
          calculationType: _calculationType,
          calculationValue: value,
          formula: comp.formula,
          isStatutory: _isStatutory,
          isTaxable: _isTaxable,
          affectsGross: comp.affectsGross,
          affectsNet: comp.affectsNet,
          minValue: comp.minValue,
          maxValue: comp.maxValue,
          appliesToCategories: comp.appliesToCategories,
          priorityOrder: comp.priorityOrder,
          isActive: comp.isActive,
          remarks: comp.remarks,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salary component updated')),
          );
        }
      } else {
        await widget.repository.createSalaryComponent(
          name: _nameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          type: _type,
          calculationType: _calculationType,
          calculationValue: value,
          isStatutory: _isStatutory,
          isTaxable: _isTaxable,
        );
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salary component created')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('PayrollException: ', ''))),
        );
      }
    }
  }
}

// ============================================================================
// PLACEHOLDER PAGES (To be implemented)
// ============================================================================

class PayrollRunDetailsPage extends StatelessWidget {
  final int runId;
  final PayrollRepository repository;
  
  const PayrollRunDetailsPage({
    super.key,
    required this.runId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Run Details')),
      body: const Center(child: Text('Details page (Coming soon)')),
    );
  }
}

// PayrollSettingsConfigPage is now imported from payroll_settings_config_page.dart
