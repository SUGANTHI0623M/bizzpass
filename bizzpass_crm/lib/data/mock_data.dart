// ─── Data Models ─────────────────────────────────────────────────────────────

// ═══ PAYROLL MODELS ═══

class SalaryComponent {
  final int id;
  final String name;
  final String displayName;
  final String type; // 'earning' or 'deduction'
  final String? category; // 'fixed', 'variable', 'statutory', 'voluntary'
  final String calculationType; // 'fixed_amount', 'percentage_of_basic', 'percentage_of_gross', 'formula', 'attendance_based'
  final double? calculationValue;
  final String? formula;
  final bool isTaxable;
  final bool isStatutory;
  final bool affectsGross;
  final bool affectsNet;
  final double? minValue;
  final double? maxValue;
  final List<String>? appliesToCategories;
  final int priorityOrder;
  final bool isActive;
  final String? remarks;

  const SalaryComponent({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    this.category,
    required this.calculationType,
    this.calculationValue,
    this.formula,
    this.isTaxable = true,
    this.isStatutory = false,
    this.affectsGross = true,
    this.affectsNet = true,
    this.minValue,
    this.maxValue,
    this.appliesToCategories,
    this.priorityOrder = 0,
    this.isActive = true,
    this.remarks,
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> j) {
    return SalaryComponent(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      displayName: (j['display_name'] as String?) ?? (j['displayName'] as String?) ?? '',
      type: (j['type'] as String?) ?? 'earning',
      category: j['category'] as String?,
      calculationType: (j['calculation_type'] as String?) ?? (j['calculationType'] as String?) ?? 'fixed_amount',
      calculationValue: (j['calculation_value'] as num?)?.toDouble() ?? (j['calculationValue'] as num?)?.toDouble(),
      formula: j['formula'] as String?,
      isTaxable: (j['is_taxable'] as bool?) ?? (j['isTaxable'] as bool?) ?? true,
      isStatutory: (j['is_statutory'] as bool?) ?? (j['isStatutory'] as bool?) ?? false,
      affectsGross: (j['affects_gross'] as bool?) ?? (j['affectsGross'] as bool?) ?? true,
      affectsNet: (j['affects_net'] as bool?) ?? (j['affectsNet'] as bool?) ?? true,
      minValue: (j['min_value'] as num?)?.toDouble() ?? (j['minValue'] as num?)?.toDouble(),
      maxValue: (j['max_value'] as num?)?.toDouble() ?? (j['maxValue'] as num?)?.toDouble(),
      appliesToCategories: j['applies_to_categories'] != null 
          ? List<String>.from(j['applies_to_categories'] as List)
          : (j['appliesToCategories'] != null ? List<String>.from(j['appliesToCategories'] as List) : null),
      priorityOrder: (j['priority_order'] as num?)?.toInt() ?? (j['priorityOrder'] as num?)?.toInt() ?? 0,
      isActive: (j['is_active'] as bool?) ?? (j['isActive'] as bool?) ?? true,
      remarks: j['remarks'] as String?,
    );
  }
}

class PayrollSettings {
  final String payCycleType;
  final int payDay;
  final int attendanceCutoffDay;
  final String workingDaysBasis;
  final int? customWorkingDays;
  final double workingHoursPerDay;
  final List<String>? paidLeaveTypes;
  final List<String>? unpaidLeaveTypes;
  final bool leaveEncashmentEnabled;
  final Map<String, dynamic>? leaveEncashmentRules;
  final String sandwichLeavePolicy;
  final String lopCalculationMethod;
  final double lopDeductionMultiplier;
  final int graceDaysPerMonth;
  final Map<String, dynamic>? lateComingRules;
  final Map<String, dynamic>? halfDayRules;
  final bool overtimeEnabled;
  final String overtimeCalculationBasis;
  final double weekdayOtMultiplier;
  final double weekendOtMultiplier;
  final double holidayOtMultiplier;
  final double? maxOtHoursPerMonth;
  final Map<String, dynamic>? otEligibilityCriteria;
  final String holidayWorkCompensation;
  final bool pfEnabled;
  final double pfEmployeeRate;
  final double pfEmployerRate;
  final double pfWageCeiling;
  final String pfCalculationBasis;
  final bool esiEnabled;
  final double esiEmployeeRate;
  final double esiEmployerRate;
  final double esiWageCeiling;
  final bool ptEnabled;
  final String? ptState;
  final Map<String, dynamic>? ptSlabRules;
  final bool tdsEnabled;
  final String tdsCalculationMethod;
  final bool gratuityEnabled;
  final int gratuityMinServiceYears;
  final String gratuityFormula;
  final String gratuityWageBasis;
  final bool joiningDayIncluded;
  final bool exitDayIncluded;
  final String prorataCalculationBasis;
  final bool arrearsEnabled;
  final String arrearsPaymentMethod;
  final Map<String, dynamic>? locationBasedAllowances;
  final String defaultTaxRegime;
  final Map<String, dynamic>? reimbursementCategories;
  final String currency;
  final String? remarks;

  const PayrollSettings({
    this.payCycleType = 'monthly',
    this.payDay = 1,
    this.attendanceCutoffDay = 25,
    this.workingDaysBasis = '26_days',
    this.customWorkingDays,
    this.workingHoursPerDay = 8.0,
    this.paidLeaveTypes,
    this.unpaidLeaveTypes,
    this.leaveEncashmentEnabled = false,
    this.leaveEncashmentRules,
    this.sandwichLeavePolicy = 'count_as_leave',
    this.lopCalculationMethod = 'per_day',
    this.lopDeductionMultiplier = 1.0,
    this.graceDaysPerMonth = 0,
    this.lateComingRules,
    this.halfDayRules,
    this.overtimeEnabled = false,
    this.overtimeCalculationBasis = 'hourly',
    this.weekdayOtMultiplier = 1.5,
    this.weekendOtMultiplier = 2.0,
    this.holidayOtMultiplier = 2.5,
    this.maxOtHoursPerMonth,
    this.otEligibilityCriteria,
    this.holidayWorkCompensation = 'double_pay',
    this.pfEnabled = true,
    this.pfEmployeeRate = 12.0,
    this.pfEmployerRate = 12.0,
    this.pfWageCeiling = 15000.0,
    this.pfCalculationBasis = 'basic_only',
    this.esiEnabled = true,
    this.esiEmployeeRate = 0.75,
    this.esiEmployerRate = 3.25,
    this.esiWageCeiling = 21000.0,
    this.ptEnabled = true,
    this.ptState,
    this.ptSlabRules,
    this.tdsEnabled = true,
    this.tdsCalculationMethod = 'monthly',
    this.gratuityEnabled = true,
    this.gratuityMinServiceYears = 5,
    this.gratuityFormula = '15/26',
    this.gratuityWageBasis = 'basic_only',
    this.joiningDayIncluded = true,
    this.exitDayIncluded = false,
    this.prorataCalculationBasis = 'calendar_days',
    this.arrearsEnabled = true,
    this.arrearsPaymentMethod = 'lump_sum',
    this.locationBasedAllowances,
    this.defaultTaxRegime = 'old',
    this.reimbursementCategories,
    this.currency = 'INR',
    this.remarks,
  });

  factory PayrollSettings.fromJson(Map<String, dynamic> j) {
    return PayrollSettings(
      payCycleType: (j['pay_cycle_type'] as String?) ?? (j['payCycleType'] as String?) ?? 'monthly',
      payDay: (j['pay_day'] as num?)?.toInt() ?? (j['payDay'] as num?)?.toInt() ?? 1,
      attendanceCutoffDay: (j['attendance_cutoff_day'] as num?)?.toInt() ?? (j['attendanceCutoffDay'] as num?)?.toInt() ?? 25,
      workingDaysBasis: (j['working_days_basis'] as String?) ?? (j['workingDaysBasis'] as String?) ?? '26_days',
      customWorkingDays: (j['custom_working_days'] as num?)?.toInt() ?? (j['customWorkingDays'] as num?)?.toInt(),
      workingHoursPerDay: (j['working_hours_per_day'] as num?)?.toDouble() ?? (j['workingHoursPerDay'] as num?)?.toDouble() ?? 8.0,
      paidLeaveTypes: j['paid_leave_types'] != null ? List<String>.from(j['paid_leave_types'] as List) : (j['paidLeaveTypes'] != null ? List<String>.from(j['paidLeaveTypes'] as List) : null),
      unpaidLeaveTypes: j['unpaid_leave_types'] != null ? List<String>.from(j['unpaid_leave_types'] as List) : (j['unpaidLeaveTypes'] != null ? List<String>.from(j['unpaidLeaveTypes'] as List) : null),
      leaveEncashmentEnabled: (j['leave_encashment_enabled'] as bool?) ?? (j['leaveEncashmentEnabled'] as bool?) ?? false,
      leaveEncashmentRules: j['leave_encashment_rules'] as Map<String, dynamic>? ?? j['leaveEncashmentRules'] as Map<String, dynamic>?,
      sandwichLeavePolicy: (j['sandwich_leave_policy'] as String?) ?? (j['sandwichLeavePolicy'] as String?) ?? 'count_as_leave',
      lopCalculationMethod: (j['lop_calculation_method'] as String?) ?? (j['lopCalculationMethod'] as String?) ?? 'per_day',
      lopDeductionMultiplier: (j['lop_deduction_multiplier'] as num?)?.toDouble() ?? (j['lopDeductionMultiplier'] as num?)?.toDouble() ?? 1.0,
      graceDaysPerMonth: (j['grace_days_per_month'] as num?)?.toInt() ?? (j['graceDaysPerMonth'] as num?)?.toInt() ?? 0,
      lateComingRules: j['late_coming_rules'] as Map<String, dynamic>? ?? j['lateComingRules'] as Map<String, dynamic>?,
      halfDayRules: j['half_day_rules'] as Map<String, dynamic>? ?? j['halfDayRules'] as Map<String, dynamic>?,
      overtimeEnabled: (j['overtime_enabled'] as bool?) ?? (j['overtimeEnabled'] as bool?) ?? false,
      overtimeCalculationBasis: (j['overtime_calculation_basis'] as String?) ?? (j['overtimeCalculationBasis'] as String?) ?? 'hourly',
      weekdayOtMultiplier: (j['weekday_ot_multiplier'] as num?)?.toDouble() ?? (j['weekdayOtMultiplier'] as num?)?.toDouble() ?? 1.5,
      weekendOtMultiplier: (j['weekend_ot_multiplier'] as num?)?.toDouble() ?? (j['weekendOtMultiplier'] as num?)?.toDouble() ?? 2.0,
      holidayOtMultiplier: (j['holiday_ot_multiplier'] as num?)?.toDouble() ?? (j['holidayOtMultiplier'] as num?)?.toDouble() ?? 2.5,
      maxOtHoursPerMonth: (j['max_ot_hours_per_month'] as num?)?.toDouble() ?? (j['maxOtHoursPerMonth'] as num?)?.toDouble(),
      otEligibilityCriteria: j['ot_eligibility_criteria'] as Map<String, dynamic>? ?? j['otEligibilityCriteria'] as Map<String, dynamic>?,
      holidayWorkCompensation: (j['holiday_work_compensation'] as String?) ?? (j['holidayWorkCompensation'] as String?) ?? 'double_pay',
      pfEnabled: (j['pf_enabled'] as bool?) ?? (j['pfEnabled'] as bool?) ?? true,
      pfEmployeeRate: (j['pf_employee_rate'] as num?)?.toDouble() ?? (j['pfEmployeeRate'] as num?)?.toDouble() ?? 12.0,
      pfEmployerRate: (j['pf_employer_rate'] as num?)?.toDouble() ?? (j['pfEmployerRate'] as num?)?.toDouble() ?? 12.0,
      pfWageCeiling: (j['pf_wage_ceiling'] as num?)?.toDouble() ?? (j['pfWageCeiling'] as num?)?.toDouble() ?? 15000.0,
      pfCalculationBasis: (j['pf_calculation_basis'] as String?) ?? (j['pfCalculationBasis'] as String?) ?? 'basic_only',
      esiEnabled: (j['esi_enabled'] as bool?) ?? (j['esiEnabled'] as bool?) ?? true,
      esiEmployeeRate: (j['esi_employee_rate'] as num?)?.toDouble() ?? (j['esiEmployeeRate'] as num?)?.toDouble() ?? 0.75,
      esiEmployerRate: (j['esi_employer_rate'] as num?)?.toDouble() ?? (j['esiEmployerRate'] as num?)?.toDouble() ?? 3.25,
      esiWageCeiling: (j['esi_wage_ceiling'] as num?)?.toDouble() ?? (j['esiWageCeiling'] as num?)?.toDouble() ?? 21000.0,
      ptEnabled: (j['pt_enabled'] as bool?) ?? (j['ptEnabled'] as bool?) ?? true,
      ptState: j['pt_state'] as String? ?? j['ptState'] as String?,
      ptSlabRules: j['pt_slab_rules'] as Map<String, dynamic>? ?? j['ptSlabRules'] as Map<String, dynamic>?,
      tdsEnabled: (j['tds_enabled'] as bool?) ?? (j['tdsEnabled'] as bool?) ?? true,
      tdsCalculationMethod: (j['tds_calculation_method'] as String?) ?? (j['tdsCalculationMethod'] as String?) ?? 'monthly',
      gratuityEnabled: (j['gratuity_enabled'] as bool?) ?? (j['gratuityEnabled'] as bool?) ?? true,
      gratuityMinServiceYears: (j['gratuity_min_service_years'] as num?)?.toInt() ?? (j['gratuityMinServiceYears'] as num?)?.toInt() ?? 5,
      gratuityFormula: (j['gratuity_formula'] as String?) ?? (j['gratuityFormula'] as String?) ?? '15/26',
      gratuityWageBasis: (j['gratuity_wage_basis'] as String?) ?? (j['gratuityWageBasis'] as String?) ?? 'basic_only',
      joiningDayIncluded: (j['joining_day_included'] as bool?) ?? (j['joiningDayIncluded'] as bool?) ?? true,
      exitDayIncluded: (j['exit_day_included'] as bool?) ?? (j['exitDayIncluded'] as bool?) ?? false,
      prorataCalculationBasis: (j['prorata_calculation_basis'] as String?) ?? (j['prorataCalculationBasis'] as String?) ?? 'calendar_days',
      arrearsEnabled: (j['arrears_enabled'] as bool?) ?? (j['arrearsEnabled'] as bool?) ?? true,
      arrearsPaymentMethod: (j['arrears_payment_method'] as String?) ?? (j['arrearsPaymentMethod'] as String?) ?? 'lump_sum',
      locationBasedAllowances: j['location_based_allowances'] as Map<String, dynamic>? ?? j['locationBasedAllowances'] as Map<String, dynamic>?,
      defaultTaxRegime: (j['default_tax_regime'] as String?) ?? (j['defaultTaxRegime'] as String?) ?? 'old',
      reimbursementCategories: j['reimbursement_categories'] as Map<String, dynamic>? ?? j['reimbursementCategories'] as Map<String, dynamic>?,
      currency: (j['currency'] as String?) ?? 'INR',
      remarks: j['remarks'] as String?,
    );
  }
}

class PayrollRun {
  final int id;
  final int month;
  final int year;
  final String payPeriodStart;
  final String payPeriodEnd;
  final String status; // 'draft', 'processing', 'calculated', 'approved', 'paid', 'cancelled'
  final int totalEmployees;
  final double totalGross;
  final double totalDeductions;
  final double totalNetPay;
  final String? remarks;

  const PayrollRun({
    required this.id,
    required this.month,
    required this.year,
    required this.payPeriodStart,
    required this.payPeriodEnd,
    required this.status,
    this.totalEmployees = 0,
    this.totalGross = 0,
    this.totalDeductions = 0,
    this.totalNetPay = 0,
    this.remarks,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> j) {
    return PayrollRun(
      id: (j['id'] as num?)?.toInt() ?? 0,
      month: (j['month'] as num?)?.toInt() ?? 1,
      year: (j['year'] as num?)?.toInt() ?? 2025,
      payPeriodStart: (j['pay_period_start'] as String?) ?? (j['payPeriodStart'] as String?) ?? '',
      payPeriodEnd: (j['pay_period_end'] as String?) ?? (j['payPeriodEnd'] as String?) ?? '',
      status: (j['status'] as String?) ?? 'draft',
      totalEmployees: (j['total_employees'] as num?)?.toInt() ?? (j['totalEmployees'] as num?)?.toInt() ?? 0,
      totalGross: (j['total_gross'] as num?)?.toDouble() ?? (j['totalGross'] as num?)?.toDouble() ?? 0,
      totalDeductions: (j['total_deductions'] as num?)?.toDouble() ?? (j['totalDeductions'] as num?)?.toDouble() ?? 0,
      totalNetPay: (j['total_net_pay'] as num?)?.toDouble() ?? (j['totalNetPay'] as num?)?.toDouble() ?? 0,
      remarks: j['remarks'] as String?,
    );
  }
}

class PayrollTransaction {
  final int id;
  final int employeeId;
  final String employeeName;
  final String? employeeNumber;
  final String? designation;
  final String? department;
  final int month;
  final int year;
  final double totalWorkingDays;
  final double daysPresent;
  final double daysAbsent;
  final double lopDays;
  final double grossSalary;
  final double totalEarnings;
  final double totalDeductions;
  final double netSalary;
  final List<Map<String, dynamic>> earningsBreakdown;
  final List<Map<String, dynamic>> deductionsBreakdown;
  final double lopAmount;
  final String status; // 'draft', 'calculated', 'approved', 'paid', 'hold'
  final String? holdReason;

  const PayrollTransaction({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeNumber,
    this.designation,
    this.department,
    required this.month,
    required this.year,
    this.totalWorkingDays = 0,
    this.daysPresent = 0,
    this.daysAbsent = 0,
    this.lopDays = 0,
    required this.grossSalary,
    required this.totalEarnings,
    required this.totalDeductions,
    required this.netSalary,
    this.earningsBreakdown = const [],
    this.deductionsBreakdown = const [],
    this.lopAmount = 0,
    this.status = 'draft',
    this.holdReason,
  });

  factory PayrollTransaction.fromJson(Map<String, dynamic> j) {
    return PayrollTransaction(
      id: (j['id'] as num?)?.toInt() ?? 0,
      employeeId: (j['employee_id'] as num?)?.toInt() ?? (j['employeeId'] as num?)?.toInt() ?? 0,
      employeeName: (j['employee_name'] as String?) ?? (j['employeeName'] as String?) ?? '',
      employeeNumber: j['employee_number'] as String? ?? j['employeeNumber'] as String?,
      designation: j['designation'] as String?,
      department: j['department'] as String?,
      month: (j['month'] as num?)?.toInt() ?? 1,
      year: (j['year'] as num?)?.toInt() ?? 2025,
      totalWorkingDays: (j['total_working_days'] as num?)?.toDouble() ?? (j['totalWorkingDays'] as num?)?.toDouble() ?? 0,
      daysPresent: (j['days_present'] as num?)?.toDouble() ?? (j['daysPresent'] as num?)?.toDouble() ?? 0,
      daysAbsent: (j['days_absent'] as num?)?.toDouble() ?? (j['daysAbsent'] as num?)?.toDouble() ?? 0,
      lopDays: (j['lop_days'] as num?)?.toDouble() ?? (j['lopDays'] as num?)?.toDouble() ?? 0,
      grossSalary: (j['gross_salary'] as num?)?.toDouble() ?? (j['grossSalary'] as num?)?.toDouble() ?? 0,
      totalEarnings: (j['total_earnings'] as num?)?.toDouble() ?? (j['totalEarnings'] as num?)?.toDouble() ?? 0,
      totalDeductions: (j['total_deductions'] as num?)?.toDouble() ?? (j['totalDeductions'] as num?)?.toDouble() ?? 0,
      netSalary: (j['net_salary'] as num?)?.toDouble() ?? (j['netSalary'] as num?)?.toDouble() ?? 0,
      earningsBreakdown: j['earnings_breakdown'] != null 
          ? List<Map<String, dynamic>>.from(j['earnings_breakdown'] as List)
          : (j['earningsBreakdown'] != null ? List<Map<String, dynamic>>.from(j['earningsBreakdown'] as List) : []),
      deductionsBreakdown: j['deductions_breakdown'] != null
          ? List<Map<String, dynamic>>.from(j['deductions_breakdown'] as List)
          : (j['deductionsBreakdown'] != null ? List<Map<String, dynamic>>.from(j['deductionsBreakdown'] as List) : []),
      lopAmount: (j['lop_amount'] as num?)?.toDouble() ?? (j['lopAmount'] as num?)?.toDouble() ?? 0,
      status: (j['status'] as String?) ?? 'draft',
      holdReason: j['hold_reason'] as String? ?? j['holdReason'] as String?,
    );
  }
}

class Company {
  final int id;
  final String name,
      email,
      phone,
      city,
      state,
      subscriptionPlan,
      subscriptionStatus,
      subscriptionEndDate,
      licenseKey;
  final bool isActive;
  final int staffCount, branches;
  /// Max staff (users) from plan/license. Null = unlimited.
  final int? maxStaff;
  /// Max branches from plan/license. Null = unlimited.
  final int? maxBranches;

  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.isActive,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.subscriptionEndDate,
    required this.staffCount,
    required this.branches,
    required this.licenseKey,
    this.maxStaff,
    this.maxBranches,
  });

  factory Company.fromJson(Map<String, dynamic> j) {
    return Company(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      city: (j['city'] as String?) ?? '',
      state: (j['state'] as String?) ?? '',
      subscriptionPlan: (j['subscriptionPlan'] as String?) ?? 'Starter',
      subscriptionStatus: (j['subscriptionStatus'] as String?) ?? 'active',
      subscriptionEndDate: (j['subscriptionEndDate'] as String?) ?? '',
      licenseKey: (j['licenseKey'] as String?) ?? '',
      isActive: (j['isActive'] as bool?) ?? true,
      staffCount: (j['staffCount'] as num?)?.toInt() ?? 0,
      branches: (j['branches'] as num?)?.toInt() ?? 0,
      maxStaff: (j['maxStaff'] as num?)?.toInt(),
      maxBranches: (j['maxBranches'] as num?)?.toInt(),
    );
  }
}

class Plan {
  final int id;
  final String planCode, planName, description, currency, maxBranches;
  final int price, durationMonths, maxUsers, trialDays;
  final List<String> features;
  final bool isActive;

  const Plan({
    required this.id,
    required this.planCode,
    required this.planName,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationMonths,
    required this.maxUsers,
    required this.maxBranches,
    required this.features,
    required this.trialDays,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> j) {
    final f = j['features'];
    final list = f is List ? f.map((e) => e.toString()).toList() : <String>[];
    return Plan(
      id: (j['id'] as num?)?.toInt() ?? 0,
      planCode: (j['planCode'] as String?) ?? '',
      planName: (j['planName'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      price: (j['price'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      durationMonths: (j['durationMonths'] as num?)?.toInt() ?? 12,
      maxUsers: (j['maxUsers'] as num?)?.toInt() ?? 0,
      maxBranches: (j['maxBranches'] as String?) ?? 'Unlimited',
      features: List<String>.from(list),
      trialDays: (j['trialDays'] as num?)?.toInt() ?? 0,
      isActive: (j['isActive'] as bool?) ?? true,
    );
  }
}

class License {
  final int id;
  final String licenseKey, plan, status;
  final String? company, validFrom, validUntil;
  final int maxUsers;
  final bool isTrial;

  const License({
    required this.id,
    required this.licenseKey,
    this.company,
    required this.plan,
    required this.maxUsers,
    required this.status,
    this.validFrom,
    this.validUntil,
    required this.isTrial,
  });

  factory License.fromJson(Map<String, dynamic> j) {
    return License(
      id: (j['id'] as num?)?.toInt() ?? 0,
      licenseKey: (j['licenseKey'] as String?) ?? '',
      company: j['company'] as String?,
      plan: (j['plan'] as String?) ?? '',
      maxUsers: (j['maxUsers'] as num?)?.toInt() ?? 0,
      status: (j['status'] as String?) ?? 'unassigned',
      validFrom: j['validFrom'] as String?,
      validUntil: j['validUntil'] as String?,
      isTrial: (j['isTrial'] as bool?) ?? false,
    );
  }
}

class Payment {
  final int id;
  final String company,
      status,
      gateway,
      method,
      razorpayId,
      paidAt,
      plan,
      currency;
  final int amount;

  const Payment({
    required this.id,
    required this.company,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gateway,
    required this.method,
    required this.razorpayId,
    required this.paidAt,
    required this.plan,
  });

  factory Payment.fromJson(Map<String, dynamic> j) {
    return Payment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      company: (j['company'] as String?) ?? '',
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      currency: (j['currency'] as String?) ?? 'INR',
      status: ((j['status'] as String?) ?? 'captured').toLowerCase(),
      gateway: ((j['gateway'] as String?) ?? 'razorpay').toLowerCase(),
      method: ((j['method'] as String?) ?? 'upi').toUpperCase(),
      razorpayId: (j['razorpayId'] as String?) ?? '',
      paidAt: (j['paidAt'] as String?) ?? '',
      plan: (j['plan'] as String?) ?? '',
    );
  }
}

class Staff {
  final int id;
  final String employeeId,
      name,
      email,
      phone,
      company,
      designation,
      department,
      status,
      joiningDate;
  final int? roleId;
  final String? roleName;
  final int? branchId;
  final String? branchName;
  final int? attendanceModalId;
  final int? shiftModalId;
  final int? leaveModalId;
  final int? holidayModalId;
  final String? staffType;
  final String? reportingManager;
  final String? salaryCycle;
  final double? grossSalary;
  final double? netSalary;
  final String? gender;
  final String? dob;
  final String? maritalStatus;
  final String? bloodGroup;
  final String? addressLine1;
  final String? addressCity;
  final String? addressState;
  final String? addressPostalCode;
  final String? addressCountry;
  final String? uan;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? pfNumber;
  final String? esiNumber;
  final String? bankName;
  final String? ifscCode;
  final String? accountNumber;
  final String? accountHolderName;
  final String? upiId;
  final String? bankVerificationStatus;

  const Staff({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.designation,
    required this.department,
    required this.status,
    required this.joiningDate,
    this.roleId,
    this.roleName,
    this.branchId,
    this.branchName,
    this.attendanceModalId,
    this.shiftModalId,
    this.leaveModalId,
    this.holidayModalId,
    this.staffType,
    this.reportingManager,
    this.salaryCycle,
    this.grossSalary,
    this.netSalary,
    this.gender,
    this.dob,
    this.maritalStatus,
    this.bloodGroup,
    this.addressLine1,
    this.addressCity,
    this.addressState,
    this.addressPostalCode,
    this.addressCountry,
    this.uan,
    this.panNumber,
    this.aadhaarNumber,
    this.pfNumber,
    this.esiNumber,
    this.bankName,
    this.ifscCode,
    this.accountNumber,
    this.accountHolderName,
    this.upiId,
    this.bankVerificationStatus,
  });

  factory Staff.fromJson(Map<String, dynamic> j) {
    return Staff(
      id: (j['id'] as num?)?.toInt() ?? 0,
      employeeId: (j['employeeId'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      designation: (j['designation'] as String?) ?? '',
      department: (j['department'] as String?) ?? '',
      status: ((j['status'] as String?) ?? 'active').toLowerCase(),
      joiningDate: (j['joiningDate'] as String?) ?? '',
      roleId: (j['roleId'] as num?)?.toInt(),
      roleName: j['roleName'] as String?,
      branchId: (j['branchId'] as num?)?.toInt(),
      branchName: j['branchName'] as String?,
      attendanceModalId: (j['attendanceModalId'] as num?)?.toInt(),
      shiftModalId: (j['shiftModalId'] as num?)?.toInt(),
      leaveModalId: (j['leaveModalId'] as num?)?.toInt(),
      holidayModalId: (j['holidayModalId'] as num?)?.toInt(),
      staffType: j['staffType'] as String?,
      reportingManager: j['reportingManager'] as String?,
      salaryCycle: j['salaryCycle'] as String?,
      grossSalary: (j['grossSalary'] as num?)?.toDouble(),
      netSalary: (j['netSalary'] as num?)?.toDouble(),
      gender: j['gender'] as String?,
      dob: j['dob'] as String?,
      maritalStatus: j['maritalStatus'] as String?,
      bloodGroup: j['bloodGroup'] as String?,
      addressLine1: j['addressLine1'] as String?,
      addressCity: j['addressCity'] as String?,
      addressState: j['addressState'] as String?,
      addressPostalCode: j['addressPostalCode'] as String?,
      addressCountry: j['addressCountry'] as String?,
      uan: j['uan'] as String?,
      panNumber: j['panNumber'] as String?,
      aadhaarNumber: j['aadhaarNumber'] as String?,
      pfNumber: j['pfNumber'] as String?,
      esiNumber: j['esiNumber'] as String?,
      bankName: j['bankName'] as String?,
      ifscCode: j['ifscCode'] as String?,
      accountNumber: j['accountNumber'] as String?,
      accountHolderName: j['accountHolderName'] as String?,
      upiId: j['upiId'] as String?,
      bankVerificationStatus: j['bankVerificationStatus'] as String?,
    );
  }
}

class Visitor {
  final int id;
  final String name,
      companyVisiting,
      visitorCompany,
      purpose,
      host,
      status,
      badge;
  final String? checkIn;

  const Visitor({
    required this.id,
    required this.name,
    required this.companyVisiting,
    required this.visitorCompany,
    required this.purpose,
    required this.host,
    required this.status,
    required this.badge,
    this.checkIn,
  });

  factory Visitor.fromJson(Map<String, dynamic> j) {
    return Visitor(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] as String?) ?? '',
      companyVisiting: (j['companyVisiting'] as String?) ?? '',
      visitorCompany: (j['visitorCompany'] as String?) ?? '',
      purpose: (j['purpose'] as String?) ?? '',
      host: (j['host'] as String?) ?? '',
      status: (j['status'] as String?) ?? 'expected',
      badge: (j['badge'] as String?) ?? '',
      checkIn: j['checkIn'] as String?,
    );
  }
}

class AttendanceRecord {
  final int id;
  final String employee, company, status;
  final String? punchIn, punchOut;
  final double workHours;
  final int lateMinutes;

  const AttendanceRecord({
    required this.id,
    required this.employee,
    required this.company,
    this.punchIn,
    this.punchOut,
    required this.status,
    required this.workHours,
    required this.lateMinutes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    return AttendanceRecord(
      id: (j['id'] as num?)?.toInt() ?? 0,
      employee: (j['employee'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      punchIn: j['punchIn'] as String?,
      punchOut: j['punchOut'] as String?,
      status: ((j['status'] as String?) ?? 'absent').toLowerCase(),
      workHours: (j['workHours'] as num?)?.toDouble() ?? 0,
      lateMinutes: (j['lateMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppNotification {
  final int id;
  final String type, title, company, channel, status, priority, createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.company,
    required this.channel,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: (j['type'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      company: (j['company'] as String?) ?? '',
      channel: ((j['channel'] as String?) ?? 'email').toLowerCase(),
      status: ((j['status'] as String?) ?? 'pending').toLowerCase(),
      priority: ((j['priority'] as String?) ?? 'normal').toLowerCase(),
      createdAt: (j['createdAt'] as String?) ?? '',
    );
  }
}

// ─── Mock Data ───────────────────────────────────────────────────────────────

const List<Company> companies = [
  Company(
      id: 1,
      name: "TechNova Solutions",
      email: "admin@technova.in",
      phone: "+91 98765 43210",
      city: "Mumbai",
      state: "Maharashtra",
      isActive: true,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "active",
      subscriptionEndDate: "2026-06-15",
      staffCount: 142,
      branches: 4,
      licenseKey: "BP-ENT-2025-0A1B"),
  Company(
      id: 2,
      name: "GreenLeaf Agritech",
      email: "ops@greenleaf.co",
      phone: "+91 87654 32109",
      city: "Pune",
      state: "Maharashtra",
      isActive: true,
      subscriptionPlan: "Professional",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-09-30",
      staffCount: 58,
      branches: 2,
      licenseKey: "BP-PRO-2025-1C2D"),
  Company(
      id: 3,
      name: "Meridian Logistics",
      email: "hr@meridian.in",
      phone: "+91 76543 21098",
      city: "Chennai",
      state: "Tamil Nadu",
      isActive: true,
      subscriptionPlan: "Starter",
      subscriptionStatus: "expiring_soon",
      subscriptionEndDate: "2025-03-15",
      staffCount: 23,
      branches: 1,
      licenseKey: "BP-STR-2025-3E4F"),
  Company(
      id: 4,
      name: "Pinnacle Edutech",
      email: "info@pinnacle.edu",
      phone: "+91 65432 10987",
      city: "Bangalore",
      state: "Karnataka",
      isActive: false,
      subscriptionPlan: "Professional",
      subscriptionStatus: "expired",
      subscriptionEndDate: "2025-01-20",
      staffCount: 76,
      branches: 3,
      licenseKey: "BP-PRO-2024-5G6H"),
  Company(
      id: 5,
      name: "Dharma Healthcare",
      email: "admin@dharma.health",
      phone: "+91 54321 09876",
      city: "Hyderabad",
      state: "Telangana",
      isActive: true,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "active",
      subscriptionEndDate: "2026-12-31",
      staffCount: 210,
      branches: 7,
      licenseKey: "BP-ENT-2025-7I8J"),
  Company(
      id: 6,
      name: "Artisan Foods Pvt Ltd",
      email: "ceo@artisanfoods.in",
      phone: "+91 43210 98765",
      city: "Delhi",
      state: "Delhi",
      isActive: true,
      subscriptionPlan: "Starter",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-08-10",
      staffCount: 15,
      branches: 1,
      licenseKey: "BP-STR-2025-9K0L"),
  Company(
      id: 7,
      name: "Vyom Infrastructure",
      email: "pm@vyom.build",
      phone: "+91 32109 87654",
      city: "Ahmedabad",
      state: "Gujarat",
      isActive: true,
      subscriptionPlan: "Professional",
      subscriptionStatus: "active",
      subscriptionEndDate: "2025-11-22",
      staffCount: 89,
      branches: 3,
      licenseKey: "BP-PRO-2025-1M2N"),
  Company(
      id: 8,
      name: "Nexus Finserv",
      email: "compliance@nex.fin",
      phone: "+91 21098 76543",
      city: "Mumbai",
      state: "Maharashtra",
      isActive: false,
      subscriptionPlan: "Enterprise",
      subscriptionStatus: "suspended",
      subscriptionEndDate: "2025-04-01",
      staffCount: 165,
      branches: 5,
      licenseKey: "BP-ENT-2024-3O4P"),
];

const List<License> licenses = [
  License(
      id: 1,
      licenseKey: "BP-ENT-2025-0A1B",
      company: "TechNova Solutions",
      plan: "Enterprise",
      maxUsers: 200,
      status: "active",
      validFrom: "2025-06-15",
      validUntil: "2026-06-15",
      isTrial: false),
  License(
      id: 2,
      licenseKey: "BP-PRO-2025-1C2D",
      company: "GreenLeaf Agritech",
      plan: "Professional",
      maxUsers: 100,
      status: "active",
      validFrom: "2024-09-30",
      validUntil: "2025-09-30",
      isTrial: false),
  License(
      id: 3,
      licenseKey: "BP-STR-2025-3E4F",
      company: "Meridian Logistics",
      plan: "Starter",
      maxUsers: 30,
      status: "active",
      validFrom: "2024-03-15",
      validUntil: "2025-03-15",
      isTrial: false),
  License(
      id: 4,
      licenseKey: "BP-PRO-2024-5G6H",
      company: "Pinnacle Edutech",
      plan: "Professional",
      maxUsers: 100,
      status: "expired",
      validFrom: "2024-01-20",
      validUntil: "2025-01-20",
      isTrial: false),
  License(
      id: 5,
      licenseKey: "BP-ENT-2025-7I8J",
      company: "Dharma Healthcare",
      plan: "Enterprise",
      maxUsers: 300,
      status: "active",
      validFrom: "2025-01-01",
      validUntil: "2026-12-31",
      isTrial: false),
  License(
      id: 6,
      licenseKey: "BP-TRL-2025-XXYY",
      company: null,
      plan: "Starter",
      maxUsers: 25,
      status: "unassigned",
      validFrom: null,
      validUntil: null,
      isTrial: true),
  License(
      id: 7,
      licenseKey: "BP-ENT-2024-3O4P",
      company: "Nexus Finserv",
      plan: "Enterprise",
      maxUsers: 200,
      status: "suspended",
      validFrom: "2024-04-01",
      validUntil: "2025-04-01",
      isTrial: false),
];

const List<Payment> payments = [
  Payment(
      id: 1,
      company: "TechNova Solutions",
      amount: 149999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Nk2x8Qs9TgZ",
      paidAt: "2025-06-14",
      plan: "Enterprise"),
  Payment(
      id: 2,
      company: "GreenLeaf Agritech",
      amount: 59999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "Card",
      razorpayId: "pay_Mj7w5Pr8SfY",
      paidAt: "2024-09-29",
      plan: "Professional"),
  Payment(
      id: 3,
      company: "Dharma Healthcare",
      amount: 249999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "Netbanking",
      razorpayId: "pay_Ol3v4Ks6RhX",
      paidAt: "2025-01-01",
      plan: "Enterprise"),
  Payment(
      id: 4,
      company: "Meridian Logistics",
      amount: 19999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Li9u3Jr5QgW",
      paidAt: "2024-03-14",
      plan: "Starter"),
  Payment(
      id: 5,
      company: "Pinnacle Edutech",
      amount: 59999,
      currency: "INR",
      status: "refunded",
      gateway: "razorpay",
      method: "Card",
      razorpayId: "pay_Kh8t2Iq4PfV",
      paidAt: "2024-01-19",
      plan: "Professional"),
  Payment(
      id: 6,
      company: "Vyom Infrastructure",
      amount: 59999,
      currency: "INR",
      status: "captured",
      gateway: "razorpay",
      method: "UPI",
      razorpayId: "pay_Pm4x7Lt9UiB",
      paidAt: "2024-11-21",
      plan: "Professional"),
];

const List<Staff> staffData = [
  Staff(
      id: 1,
      employeeId: "TN-001",
      name: "Arjun Mehta",
      email: "arjun@technova.in",
      phone: "+91 98111 22334",
      company: "TechNova Solutions",
      designation: "Sr. Developer",
      department: "Engineering",
      status: "active",
      joiningDate: "2023-04-10"),
  Staff(
      id: 2,
      employeeId: "TN-002",
      name: "Priya Sharma",
      email: "priya@technova.in",
      phone: "+91 98222 33445",
      company: "TechNova Solutions",
      designation: "Product Manager",
      department: "Product",
      status: "active",
      joiningDate: "2022-08-15"),
  Staff(
      id: 3,
      employeeId: "GL-001",
      name: "Rohit Patel",
      email: "rohit@greenleaf.co",
      phone: "+91 87333 44556",
      company: "GreenLeaf Agritech",
      designation: "Operations Head",
      department: "Operations",
      status: "active",
      joiningDate: "2023-01-05"),
  Staff(
      id: 4,
      employeeId: "DH-001",
      name: "Dr. Kavitha Rao",
      email: "kavitha@dharma.health",
      phone: "+91 76444 55667",
      company: "Dharma Healthcare",
      designation: "Chief Medical Officer",
      department: "Medical",
      status: "active",
      joiningDate: "2021-06-20"),
  Staff(
      id: 5,
      employeeId: "ML-001",
      name: "Suresh Kumar",
      email: "suresh@meridian.in",
      phone: "+91 65555 66778",
      company: "Meridian Logistics",
      designation: "Fleet Manager",
      department: "Logistics",
      status: "active",
      joiningDate: "2024-02-01"),
  Staff(
      id: 6,
      employeeId: "PE-001",
      name: "Ananya Joshi",
      email: "ananya@pinnacle.edu",
      phone: "+91 54666 77889",
      company: "Pinnacle Edutech",
      designation: "Content Director",
      department: "Content",
      status: "inactive",
      joiningDate: "2022-11-10"),
  Staff(
      id: 7,
      employeeId: "NF-001",
      name: "Vikram Singh",
      email: "vikram@nex.fin",
      phone: "+91 43777 88990",
      company: "Nexus Finserv",
      designation: "Compliance Officer",
      department: "Compliance",
      status: "inactive",
      joiningDate: "2023-07-25"),
  Staff(
      id: 8,
      employeeId: "TN-003",
      name: "Deepa Nair",
      email: "deepa@technova.in",
      phone: "+91 98888 99001",
      company: "TechNova Solutions",
      designation: "UX Designer",
      department: "Design",
      status: "active",
      joiningDate: "2024-01-15"),
];

const List<Visitor> visitors = [
  Visitor(
      id: 1,
      name: "Rajesh Khanna",
      companyVisiting: "TechNova Solutions",
      visitorCompany: "Infosys",
      purpose: "Client Meeting",
      host: "Arjun Mehta",
      status: "checked_in",
      checkIn: "2025-02-08 09:30",
      badge: "V-0142"),
  Visitor(
      id: 2,
      name: "Meera Iyer",
      companyVisiting: "Dharma Healthcare",
      visitorCompany: "Apollo Hospitals",
      purpose: "Partnership Discussion",
      host: "Dr. Kavitha Rao",
      status: "expected",
      checkIn: null,
      badge: "V-0143"),
  Visitor(
      id: 3,
      name: "Amit Desai",
      companyVisiting: "GreenLeaf Agritech",
      visitorCompany: "Bayer CropScience",
      purpose: "Product Demo",
      host: "Rohit Patel",
      status: "checked_out",
      checkIn: "2025-02-07 14:00",
      badge: "V-0141"),
  Visitor(
      id: 4,
      name: "Sunita Reddy",
      companyVisiting: "TechNova Solutions",
      visitorCompany: "Self",
      purpose: "Interview",
      host: "Priya Sharma",
      status: "checked_in",
      checkIn: "2025-02-08 10:15",
      badge: "V-0144"),
];

const List<AttendanceRecord> attendanceToday = [
  AttendanceRecord(
      id: 1,
      employee: "Arjun Mehta",
      company: "TechNova Solutions",
      punchIn: "09:02",
      punchOut: null,
      status: "present",
      workHours: 5.2,
      lateMinutes: 2),
  AttendanceRecord(
      id: 2,
      employee: "Priya Sharma",
      company: "TechNova Solutions",
      punchIn: "08:45",
      punchOut: null,
      status: "present",
      workHours: 5.5,
      lateMinutes: 0),
  AttendanceRecord(
      id: 3,
      employee: "Rohit Patel",
      company: "GreenLeaf Agritech",
      punchIn: "09:15",
      punchOut: null,
      status: "late",
      workHours: 5.0,
      lateMinutes: 15),
  AttendanceRecord(
      id: 4,
      employee: "Dr. Kavitha Rao",
      company: "Dharma Healthcare",
      punchIn: "07:30",
      punchOut: null,
      status: "present",
      workHours: 6.8,
      lateMinutes: 0),
  AttendanceRecord(
      id: 5,
      employee: "Suresh Kumar",
      company: "Meridian Logistics",
      punchIn: null,
      punchOut: null,
      status: "absent",
      workHours: 0,
      lateMinutes: 0),
  AttendanceRecord(
      id: 6,
      employee: "Deepa Nair",
      company: "TechNova Solutions",
      punchIn: "09:30",
      punchOut: null,
      status: "late",
      workHours: 4.8,
      lateMinutes: 30),
];

const List<AppNotification> notifications = [
  AppNotification(
      id: 1,
      type: "license_expiry_reminder",
      title: "License expiring in 35 days",
      company: "Meridian Logistics",
      channel: "email",
      status: "sent",
      priority: "high",
      createdAt: "2025-02-08"),
  AppNotification(
      id: 2,
      type: "payment_confirmation",
      title: "Payment received — ₹1,49,999",
      company: "TechNova Solutions",
      channel: "email",
      status: "delivered",
      priority: "normal",
      createdAt: "2025-02-07"),
  AppNotification(
      id: 3,
      type: "license_suspended",
      title: "License suspended — payment overdue",
      company: "Nexus Finserv",
      channel: "email",
      status: "sent",
      priority: "urgent",
      createdAt: "2025-02-06"),
  AppNotification(
      id: 4,
      type: "visitor_arrival",
      title: "Visitor Rajesh Khanna checked in",
      company: "TechNova Solutions",
      channel: "in_app",
      status: "read",
      priority: "low",
      createdAt: "2025-02-08"),
];
