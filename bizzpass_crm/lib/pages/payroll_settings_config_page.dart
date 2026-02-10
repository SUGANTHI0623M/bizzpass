import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../data/payroll_repository.dart';

/// Comprehensive Payroll Settings Configuration Page
/// 
/// Allows company admins to configure all payroll-related settings including:
/// - Working days, pay cycles
/// - Leave policies
/// - Attendance rules (LOP, grace, late penalties)
/// - Overtime rules
/// - Statutory compliance (PF, ESI, PT, TDS)
/// - Pro-rata calculations
/// - Arrears management
class PayrollSettingsConfigPage extends StatefulWidget {
  final PayrollRepository repository;

  const PayrollSettingsConfigPage({super.key, required this.repository});

  @override
  State<PayrollSettingsConfigPage> createState() => _PayrollSettingsConfigPageState();
}

class _PayrollSettingsConfigPageState extends State<PayrollSettingsConfigPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Loading states
  bool _loading = true;
  bool _saving = false;
  String? _error;
  
  // Working Days & Pay Cycle
  final _payCycleController = TextEditingController(text: 'monthly');
  final _payDayController = TextEditingController(text: '1');
  final _attendanceCutoffController = TextEditingController(text: '25');
  final _workingDaysPerMonthController = TextEditingController(text: '26');
  final _workingHoursPerDayController = TextEditingController(text: '8.0');
  bool _includeWeeklyOffsInWorkingDays = false;
  
  // Leave Policies
  bool _deductLopForUnpaidLeaves = true;
  bool _allowHalfDayLop = true;
  bool _considerSandwichLeaves = false;
  bool _includeHolidaysInLeave = false;
  bool _allowLeaveEncashment = false;
  final _maxLeaveEncashmentDaysController = TextEditingController(text: '0');
  
  // Attendance Rules
  final _gracePeriodMinutesController = TextEditingController(text: '15');
  bool _enableLatePenalty = false;
  final _latePenaltyAfterMinutesController = TextEditingController(text: '30');
  final _latePenaltyAmountController = TextEditingController(text: '0');
  bool _allowAttendanceRegularization = true;
  final _maxRegularizationDaysController = TextEditingController(text: '7');
  bool _halfDayAfterHoursController = true;
  final _halfDayThresholdHoursController = TextEditingController(text: '4.0');
  
  // Overtime Rules
  bool _enableOvertime = false;
  final _overtimeMultiplierWeekdayController = TextEditingController(text: '1.5');
  final _overtimeMultiplierWeekendController = TextEditingController(text: '2.0');
  final _overtimeMultiplierHolidayController = TextEditingController(text: '2.5');
  final _maxOvertimeHoursPerDayController = TextEditingController(text: '4');
  final _maxOvertimeHoursPerMonthController = TextEditingController(text: '50');
  bool _autoApproveOvertime = false;
  
  // Statutory Compliance
  bool _enablePf = true;
  final _pfEmployeePercentController = TextEditingController(text: '12');
  final _pfEmployerPercentController = TextEditingController(text: '12');
  final _pfWageCeilingController = TextEditingController(text: '15000');
  
  bool _enableEsi = false;
  final _esiEmployeePercentController = TextEditingController(text: '0.75');
  final _esiEmployerPercentController = TextEditingController(text: '3.25');
  final _esiWageCeilingController = TextEditingController(text: '21000');
  
  bool _enableProfessionalTax = false;
  final _professionalTaxAmountController = TextEditingController(text: '200');
  final _ptStateName = 'Maharashtra'; // Dropdown in full implementation
  
  bool _enableTds = true;
  bool _autoCalculateTds = true;
  
  // Pro-rata Calculations
  bool _prorateForNewJoiners = true;
  bool _prorateForExits = true;
  bool _prorateSalaryRevisions = true;
  bool _prorateOnWorkingDays = true;
  
  // Arrears Management
  bool _allowArrears = true;
  bool _autoApproveArrears = false;
  
  // Gratuity
  bool _enableGratuity = true;
  final _gratuityMinYearsController = TextEditingController(text: '5');
  final _gratuityFormulaController = TextEditingController(text: '(last_drawn_salary * years_of_service * 15) / 26');
  
  // Payroll Processing
  bool _autoLockPayrollAfterApproval = true;
  bool _allowEditAfterApproval = false;
  bool _sendPayslipEmail = true;
  bool _requirePayslipPassword = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    // Dispose all controllers
    _payCycleController.dispose();
    _payDayController.dispose();
    _attendanceCutoffController.dispose();
    _workingDaysPerMonthController.dispose();
    _workingHoursPerDayController.dispose();
    _maxLeaveEncashmentDaysController.dispose();
    _gracePeriodMinutesController.dispose();
    _latePenaltyAfterMinutesController.dispose();
    _latePenaltyAmountController.dispose();
    _maxRegularizationDaysController.dispose();
    _halfDayThresholdHoursController.dispose();
    _overtimeMultiplierWeekdayController.dispose();
    _overtimeMultiplierWeekendController.dispose();
    _overtimeMultiplierHolidayController.dispose();
    _maxOvertimeHoursPerDayController.dispose();
    _maxOvertimeHoursPerMonthController.dispose();
    _pfEmployeePercentController.dispose();
    _pfEmployerPercentController.dispose();
    _pfWageCeilingController.dispose();
    _esiEmployeePercentController.dispose();
    _esiEmployerPercentController.dispose();
    _esiWageCeilingController.dispose();
    _professionalTaxAmountController.dispose();
    _gratuityMinYearsController.dispose();
    _gratuityFormulaController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final settings = await widget.repository.fetchPayrollSettings();
      
      if (mounted) {
        // Populate controllers with loaded settings
        _payCycleController.text = settings['payCycleType'] ?? 'monthly';
        _payDayController.text = (settings['payDay'] ?? 1).toString();
        _attendanceCutoffController.text = (settings['attendanceCutoffDay'] ?? 25).toString();
        _workingDaysPerMonthController.text = (settings['workingDaysPerMonth'] ?? 26).toString();
        _workingHoursPerDayController.text = (settings['workingHoursPerDay'] ?? 8.0).toString();
        _includeWeeklyOffsInWorkingDays = settings['includeWeeklyOffsInWorkingDays'] ?? false;
        
        _deductLopForUnpaidLeaves = settings['deductLopForUnpaidLeaves'] ?? true;
        _allowHalfDayLop = settings['allowHalfDayLop'] ?? true;
        _considerSandwichLeaves = settings['considerSandwichLeaves'] ?? false;
        _includeHolidaysInLeave = settings['includeHolidaysInLeave'] ?? false;
        _allowLeaveEncashment = settings['allowLeaveEncashment'] ?? false;
        _maxLeaveEncashmentDaysController.text = (settings['maxLeaveEncashmentDays'] ?? 0).toString();
        
        _gracePeriodMinutesController.text = (settings['gracePeriodMinutes'] ?? 15).toString();
        _enableLatePenalty = settings['enableLatePenalty'] ?? false;
        _latePenaltyAfterMinutesController.text = (settings['latePenaltyAfterMinutes'] ?? 30).toString();
        _latePenaltyAmountController.text = (settings['latePenaltyAmount'] ?? 0).toString();
        _allowAttendanceRegularization = settings['allowAttendanceRegularization'] ?? true;
        _maxRegularizationDaysController.text = (settings['maxRegularizationDays'] ?? 7).toString();
        
        _enableOvertime = settings['enableOvertime'] ?? false;
        _overtimeMultiplierWeekdayController.text = (settings['overtimeMultiplierWeekday'] ?? 1.5).toString();
        _overtimeMultiplierWeekendController.text = (settings['overtimeMultiplierWeekend'] ?? 2.0).toString();
        _overtimeMultiplierHolidayController.text = (settings['overtimeMultiplierHoliday'] ?? 2.5).toString();
        _maxOvertimeHoursPerDayController.text = (settings['maxOvertimeHoursPerDay'] ?? 4).toString();
        _maxOvertimeHoursPerMonthController.text = (settings['maxOvertimeHoursPerMonth'] ?? 50).toString();
        _autoApproveOvertime = settings['autoApproveOvertime'] ?? false;
        
        _enablePf = settings['enablePf'] ?? true;
        _pfEmployeePercentController.text = (settings['pfEmployeePercent'] ?? 12).toString();
        _pfEmployerPercentController.text = (settings['pfEmployerPercent'] ?? 12).toString();
        _pfWageCeilingController.text = (settings['pfWageCeiling'] ?? 15000).toString();
        
        _enableEsi = settings['enableEsi'] ?? false;
        _esiEmployeePercentController.text = (settings['esiEmployeePercent'] ?? 0.75).toString();
        _esiEmployerPercentController.text = (settings['esiEmployerPercent'] ?? 3.25).toString();
        _esiWageCeilingController.text = (settings['esiWageCeiling'] ?? 21000).toString();
        
        _enableProfessionalTax = settings['enableProfessionalTax'] ?? false;
        _professionalTaxAmountController.text = (settings['professionalTaxAmount'] ?? 200).toString();
        
        _enableTds = settings['enableTds'] ?? true;
        _autoCalculateTds = settings['autoCalculateTds'] ?? true;
        
        _prorateForNewJoiners = settings['prorateForNewJoiners'] ?? true;
        _prorateForExits = settings['prorateForExits'] ?? true;
        _prorateSalaryRevisions = settings['prorateSalaryRevisions'] ?? true;
        _prorateOnWorkingDays = settings['prorateOnWorkingDays'] ?? true;
        
        _allowArrears = settings['allowArrears'] ?? true;
        _autoApproveArrears = settings['autoApproveArrears'] ?? false;
        
        _enableGratuity = settings['enableGratuity'] ?? true;
        _gratuityMinYearsController.text = (settings['gratuityMinYears'] ?? 5).toString();
        _gratuityFormulaController.text = settings['gratuityFormula'] ?? '(last_drawn_salary * years_of_service * 15) / 26';
        
        _autoLockPayrollAfterApproval = settings['autoLockPayrollAfterApproval'] ?? true;
        _allowEditAfterApproval = settings['allowEditAfterApproval'] ?? false;
        _sendPayslipEmail = settings['sendPayslipEmail'] ?? true;
        _requirePayslipPassword = settings['requirePayslipPassword'] ?? false;
        
        setState(() {
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
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _saving = true);
    
    try {
      // Build settings map
      final settings = {
        'payCycleType': _payCycleController.text,
        'payDay': int.parse(_payDayController.text),
        'attendanceCutoffDay': int.parse(_attendanceCutoffController.text),
        'workingDaysPerMonth': int.parse(_workingDaysPerMonthController.text),
        'workingHoursPerDay': double.parse(_workingHoursPerDayController.text),
        'includeWeeklyOffsInWorkingDays': _includeWeeklyOffsInWorkingDays,
        
        'deductLopForUnpaidLeaves': _deductLopForUnpaidLeaves,
        'allowHalfDayLop': _allowHalfDayLop,
        'considerSandwichLeaves': _considerSandwichLeaves,
        'includeHolidaysInLeave': _includeHolidaysInLeave,
        'allowLeaveEncashment': _allowLeaveEncashment,
        'maxLeaveEncashmentDays': int.parse(_maxLeaveEncashmentDaysController.text),
        
        'gracePeriodMinutes': int.parse(_gracePeriodMinutesController.text),
        'enableLatePenalty': _enableLatePenalty,
        'latePenaltyAfterMinutes': int.parse(_latePenaltyAfterMinutesController.text),
        'latePenaltyAmount': double.parse(_latePenaltyAmountController.text),
        'allowAttendanceRegularization': _allowAttendanceRegularization,
        'maxRegularizationDays': int.parse(_maxRegularizationDaysController.text),
        
        'enableOvertime': _enableOvertime,
        'overtimeMultiplierWeekday': double.parse(_overtimeMultiplierWeekdayController.text),
        'overtimeMultiplierWeekend': double.parse(_overtimeMultiplierWeekendController.text),
        'overtimeMultiplierHoliday': double.parse(_overtimeMultiplierHolidayController.text),
        'maxOvertimeHoursPerDay': int.parse(_maxOvertimeHoursPerDayController.text),
        'maxOvertimeHoursPerMonth': int.parse(_maxOvertimeHoursPerMonthController.text),
        'autoApproveOvertime': _autoApproveOvertime,
        
        'enablePf': _enablePf,
        'pfEmployeePercent': double.parse(_pfEmployeePercentController.text),
        'pfEmployerPercent': double.parse(_pfEmployerPercentController.text),
        'pfWageCeiling': double.parse(_pfWageCeilingController.text),
        
        'enableEsi': _enableEsi,
        'esiEmployeePercent': double.parse(_esiEmployeePercentController.text),
        'esiEmployerPercent': double.parse(_esiEmployerPercentController.text),
        'esiWageCeiling': double.parse(_esiWageCeilingController.text),
        
        'enableProfessionalTax': _enableProfessionalTax,
        'professionalTaxAmount': double.parse(_professionalTaxAmountController.text),
        'ptState': _ptStateName,
        
        'enableTds': _enableTds,
        'autoCalculateTds': _autoCalculateTds,
        
        'prorateForNewJoiners': _prorateForNewJoiners,
        'prorateForExits': _prorateForExits,
        'prorateSalaryRevisions': _prorateSalaryRevisions,
        'prorateOnWorkingDays': _prorateOnWorkingDays,
        
        'allowArrears': _allowArrears,
        'autoApproveArrears': _autoApproveArrears,
        
        'enableGratuity': _enableGratuity,
        'gratuityMinYears': int.parse(_gratuityMinYearsController.text),
        'gratuityFormula': _gratuityFormulaController.text,
        
        'autoLockPayrollAfterApproval': _autoLockPayrollAfterApproval,
        'allowEditAfterApproval': _allowEditAfterApproval,
        'sendPayslipEmail': _sendPayslipEmail,
        'requirePayslipPassword': _requirePayslipPassword,
      };
      
      await widget.repository.savePayrollSettings(settings);
      
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Payroll settings saved successfully!'), backgroundColor: context.successColor),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: ${e.toString()}'), backgroundColor: context.dangerColor),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Payroll Settings Configuration', style: TextStyle(color: context.textColor, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.borderColor),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: context.warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.warningColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: context.warningColor, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: context.textColor))),
                                ],
                              ),
                            ),
                          
                          _buildSection(
                            'Working Days & Pay Cycle',
                            Icons.calendar_month_rounded,
                            [
                              _buildDropdown('Pay Cycle', _payCycleController, ['monthly', 'bi-weekly', 'weekly'], 'How often employees are paid'),
                              _buildNumberField('Pay Day', _payDayController, 'Day of month for salary payment (1-31)', min: 1, max: 31),
                              _buildNumberField('Attendance Cutoff Day', _attendanceCutoffController, 'Last day to consider attendance for current cycle', min: 1, max: 31),
                              _buildNumberField('Working Days per Month', _workingDaysPerMonthController, 'Standard working days (for LOP calculation)', min: 20, max: 31),
                              _buildDecimalField('Working Hours per Day', _workingHoursPerDayController, 'Standard hours per day', min: 4, max: 12),
                              _buildSwitch('Include Weekly Offs in Working Days', _includeWeeklyOffsInWorkingDays, 
                                  'If enabled, weekly offs count towards total working days'),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Leave Policies',
                            Icons.beach_access_rounded,
                            [
                              _buildSwitch('Deduct LOP for Unpaid Leaves', _deductLopForUnpaidLeaves,
                                  'Automatically deduct Loss of Pay for unpaid leave days'),
                              _buildSwitch('Allow Half Day LOP', _allowHalfDayLop,
                                  'Enable half-day LOP deduction'),
                              _buildSwitch('Consider Sandwich Leaves', _considerSandwichLeaves,
                                  'Count days between leave and holidays as leave'),
                              _buildSwitch('Include Holidays in Leave Period', _includeHolidaysInLeave,
                                  'Holidays within leave period count as leave days'),
                              _buildSwitch('Allow Leave Encashment', _allowLeaveEncashment,
                                  'Employees can encash unused leaves'),
                              if (_allowLeaveEncashment)
                                _buildNumberField('Max Encashment Days', _maxLeaveEncashmentDaysController, 
                                    'Maximum leave days that can be encashed per year', min: 0, max: 30),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Attendance Rules',
                            Icons.schedule_rounded,
                            [
                              _buildNumberField('Grace Period (minutes)', _gracePeriodMinutesController, 
                                  'Late grace period before marking late', min: 0, max: 60),
                              _buildSwitch('Enable Late Penalty', _enableLatePenalty,
                                  'Deduct penalty amount for late coming'),
                              if (_enableLatePenalty) ...[
                                _buildNumberField('Late Penalty After (minutes)', _latePenaltyAfterMinutesController,
                                    'Minutes after which penalty applies', min: 0, max: 120),
                                _buildDecimalField('Penalty Amount (₹)', _latePenaltyAmountController,
                                    'Amount to deduct for each late instance', min: 0, max: 1000),
                              ],
                              _buildSwitch('Allow Attendance Regularization', _allowAttendanceRegularization,
                                  'Employees can request attendance corrections'),
                              if (_allowAttendanceRegularization)
                                _buildNumberField('Max Regularization Days', _maxRegularizationDaysController,
                                    'Max days employee can request regularization', min: 1, max: 30),
                              _buildDecimalField('Half Day Threshold (hours)', _halfDayThresholdHoursController,
                                    'Hours below which day is marked as half-day', min: 2, max: 6),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Overtime Rules',
                            Icons.timer_rounded,
                            [
                              _buildSwitch('Enable Overtime', _enableOvertime,
                                  'Allow employees to work overtime'),
                              if (_enableOvertime) ...[
                                _buildDecimalField('Weekday Multiplier', _overtimeMultiplierWeekdayController,
                                    'OT rate multiplier for weekdays', min: 1.0, max: 3.0),
                                _buildDecimalField('Weekend Multiplier', _overtimeMultiplierWeekendController,
                                    'OT rate multiplier for weekends', min: 1.5, max: 3.0),
                                _buildDecimalField('Holiday Multiplier', _overtimeMultiplierHolidayController,
                                    'OT rate multiplier for holidays', min: 2.0, max: 4.0),
                                _buildNumberField('Max OT Hours per Day', _maxOvertimeHoursPerDayController,
                                    'Maximum overtime hours per day', min: 2, max: 8),
                                _buildNumberField('Max OT Hours per Month', _maxOvertimeHoursPerMonthController,
                                    'Maximum overtime hours per month', min: 20, max: 100),
                                _buildSwitch('Auto Approve Overtime', _autoApproveOvertime,
                                    'Automatically approve overtime hours'),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Statutory Compliance - PF (Provident Fund)',
                            Icons.account_balance_rounded,
                            [
                              _buildSwitch('Enable PF', _enablePf,
                                  'Deduct Provident Fund contributions'),
                              if (_enablePf) ...[
                                _buildDecimalField('Employee Contribution (%)', _pfEmployeePercentController,
                                    'Employee PF percentage (usually 12%)', min: 0, max: 20),
                                _buildDecimalField('Employer Contribution (%)', _pfEmployerPercentController,
                                    'Employer PF percentage (usually 12%)', min: 0, max: 20),
                                _buildDecimalField('Wage Ceiling (₹)', _pfWageCeilingController,
                                    'Max basic salary for PF calculation (₹15,000)', min: 10000, max: 30000),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Statutory Compliance - ESI (Employee State Insurance)',
                            Icons.local_hospital_rounded,
                            [
                              _buildSwitch('Enable ESI', _enableEsi,
                                  'Deduct ESI contributions'),
                              if (_enableEsi) ...[
                                _buildDecimalField('Employee Contribution (%)', _esiEmployeePercentController,
                                    'Employee ESI percentage (0.75%)', min: 0, max: 5),
                                _buildDecimalField('Employer Contribution (%)', _esiEmployerPercentController,
                                    'Employer ESI percentage (3.25%)', min: 0, max: 10),
                                _buildDecimalField('Wage Ceiling (₹)', _esiWageCeilingController,
                                    'Max gross salary for ESI (₹21,000)', min: 15000, max: 30000),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Statutory Compliance - Professional Tax & TDS',
                            Icons.receipt_long_rounded,
                            [
                              _buildSwitch('Enable Professional Tax', _enableProfessionalTax,
                                  'Deduct state professional tax'),
                              if (_enableProfessionalTax)
                                _buildDecimalField('PT Amount (₹)', _professionalTaxAmountController,
                                    'Monthly professional tax amount (varies by state)', min: 0, max: 300),
                              _buildSwitch('Enable TDS', _enableTds,
                                  'Deduct Tax Deducted at Source'),
                              if (_enableTds)
                                _buildSwitch('Auto Calculate TDS', _autoCalculateTds,
                                    'Automatically calculate TDS based on salary and declarations'),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Pro-rata Calculations',
                            Icons.calculate_rounded,
                            [
                              _buildSwitch('Pro-rate for New Joiners', _prorateForNewJoiners,
                                  'Calculate salary proportionally for mid-month joiners'),
                              _buildSwitch('Pro-rate for Exits', _prorateForExits,
                                  'Calculate salary proportionally for mid-month exits'),
                              _buildSwitch('Pro-rate Salary Revisions', _prorateSalaryRevisions,
                                  'Apply new salary only for remaining days of month'),
                              _buildSwitch('Pro-rate on Working Days', _prorateOnWorkingDays,
                                  'Use working days instead of calendar days for pro-rata'),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Arrears & Gratuity',
                            Icons.money_rounded,
                            [
                              _buildSwitch('Allow Arrears', _allowArrears,
                                  'Enable backdated salary adjustments'),
                              if (_allowArrears)
                                _buildSwitch('Auto Approve Arrears', _autoApproveArrears,
                                    'Automatically approve arrears without manual approval'),
                              _buildSwitch('Enable Gratuity', _enableGratuity,
                                  'Calculate gratuity for eligible employees'),
                              if (_enableGratuity) ...[
                                _buildNumberField('Minimum Years for Gratuity', _gratuityMinYearsController,
                                    'Minimum service years to be eligible', min: 1, max: 10),
                                _buildTextField('Gratuity Formula', _gratuityFormulaController,
                                    'Formula for gratuity calculation'),
                              ],
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSection(
                            'Payroll Processing',
                            Icons.settings_rounded,
                            [
                              _buildSwitch('Auto Lock After Approval', _autoLockPayrollAfterApproval,
                                  'Lock payroll run automatically after approval'),
                              _buildSwitch('Allow Edit After Approval', _allowEditAfterApproval,
                                  'Allow editing payroll even after approval (not recommended)'),
                              _buildSwitch('Send Payslip via Email', _sendPayslipEmail,
                                  'Automatically email payslips to employees'),
                              _buildSwitch('Require Payslip Password', _requirePayslipPassword,
                                  'Password protect payslip PDFs'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom save bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      border: Border(top: BorderSide(color: context.borderColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Configure all payroll rules and policies for your company',
                            style: TextStyle(fontSize: 13, color: context.textMutedColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _saveSettings,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(_saving ? 'Saving...' : 'Save Settings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: context.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: context.bgColor,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildNumberField(String label, TextEditingController controller, String hint, {int? min, int? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: context.bgColor,
          suffixText: hint.contains('minutes') ? 'min' : (hint.contains('hours') ? 'hrs' : ''),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          final num = int.tryParse(value);
          if (num == null) {
            return 'Invalid number';
          }
          if (min != null && num < min) {
            return 'Min: $min';
          }
          if (max != null && num > max) {
            return 'Max: $max';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildDecimalField(String label, TextEditingController controller, String hint, {double? min, double? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: context.bgColor,
          suffixText: label.contains('%') ? '%' : (label.contains('₹') ? '₹' : ''),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          final num = double.tryParse(value);
          if (num == null) {
            return 'Invalid number';
          }
          if (min != null && num < min) {
            return 'Min: $min';
          }
          if (max != null && num > max) {
            return 'Max: $max';
          }
          return null;
        },
      ),
    );
  }
  
  Widget _buildDropdown(String label, TextEditingController controller, List<String> options, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: options.contains(controller.text) ? controller.text : options.first,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: context.bgColor,
        ),
        items: options.map((opt) {
          return DropdownMenuItem(
            value: opt,
            child: Text(opt[0].toUpperCase() + opt.substring(1)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
          }
        },
      ),
    );
  }
  
  Widget _buildSwitch(String label, bool value, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? context.accentColor.withOpacity(0.3) : context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 12, color: context.textMutedColor)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                setState(() {
                  // Update the corresponding boolean variable
                  if (label == 'Include Weekly Offs in Working Days') _includeWeeklyOffsInWorkingDays = newValue;
                  else if (label == 'Deduct LOP for Unpaid Leaves') _deductLopForUnpaidLeaves = newValue;
                  else if (label == 'Allow Half Day LOP') _allowHalfDayLop = newValue;
                  else if (label == 'Consider Sandwich Leaves') _considerSandwichLeaves = newValue;
                  else if (label == 'Include Holidays in Leave Period') _includeHolidaysInLeave = newValue;
                  else if (label == 'Allow Leave Encashment') _allowLeaveEncashment = newValue;
                  else if (label == 'Enable Late Penalty') _enableLatePenalty = newValue;
                  else if (label == 'Allow Attendance Regularization') _allowAttendanceRegularization = newValue;
                  else if (label == 'Enable Overtime') _enableOvertime = newValue;
                  else if (label == 'Auto Approve Overtime') _autoApproveOvertime = newValue;
                  else if (label == 'Enable PF') _enablePf = newValue;
                  else if (label == 'Enable ESI') _enableEsi = newValue;
                  else if (label == 'Enable Professional Tax') _enableProfessionalTax = newValue;
                  else if (label == 'Enable TDS') _enableTds = newValue;
                  else if (label == 'Auto Calculate TDS') _autoCalculateTds = newValue;
                  else if (label == 'Pro-rate for New Joiners') _prorateForNewJoiners = newValue;
                  else if (label == 'Pro-rate for Exits') _prorateForExits = newValue;
                  else if (label == 'Pro-rate Salary Revisions') _prorateSalaryRevisions = newValue;
                  else if (label == 'Pro-rate on Working Days') _prorateOnWorkingDays = newValue;
                  else if (label == 'Allow Arrears') _allowArrears = newValue;
                  else if (label == 'Auto Approve Arrears') _autoApproveArrears = newValue;
                  else if (label == 'Enable Gratuity') _enableGratuity = newValue;
                  else if (label == 'Auto Lock After Approval') _autoLockPayrollAfterApproval = newValue;
                  else if (label == 'Allow Edit After Approval') _allowEditAfterApproval = newValue;
                  else if (label == 'Send Payslip via Email') _sendPayslipEmail = newValue;
                  else if (label == 'Require Payslip Password') _requirePayslipPassword = newValue;
                });
              },
              activeColor: context.accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
