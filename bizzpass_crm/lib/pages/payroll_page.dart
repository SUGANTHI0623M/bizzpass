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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
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
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PayrollRunsTab(repository: _repo),
                _SalaryComponentsTab(repository: _repo),
                _PayrollSettingsTab(repository: _repo),
                _PayrollReportsTab(repository: _repo),
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
    showDialog(
      context: context,
      builder: (ctx) => _CreateSalaryComponentDialog(repository: _repo),
    ).then((_) => setState(() {}));
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
  
  const _SalaryComponentsTab({required this.repository});

  @override
  State<_SalaryComponentsTab> createState() => _SalaryComponentsTabState();
}

class _SalaryComponentsTabState extends State<_SalaryComponentsTab> {
  List<SalaryComponent> _components = [];
  bool _loading = true;
  String? _error;
  String _typeFilter = 'all';

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
            ],
            active: _typeFilter,
            onChanged: (v) {
              setState(() => _typeFilter = v);
              _load();
            },
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
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editComponent(comp),
                          tooltip: 'Edit',
                        ),
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

  void _editComponent(SalaryComponent comp) {
    // TODO: Show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit component (Coming soon)')),
    );
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
  
  const _CreateSalaryComponentDialog({required this.repository});

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
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Salary Component'),
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
              : const Text('Create'),
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salary component created')),
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
