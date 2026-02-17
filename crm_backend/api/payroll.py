"""
Payroll API - Comprehensive payroll management system
Handles salary components, payroll configuration, payroll runs, and calculations
"""
import json
from datetime import date, datetime, timedelta
from decimal import Decimal
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission, _audit_log

try:
    import psycopg2
except ImportError:
    psycopg2 = None  # type: ignore

router = APIRouter(prefix="/payroll", tags=["payroll"])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def check_permission(current_user: dict, permission: str):
    """Helper function to check if user has permission. Super Admin bypasses."""
    role = (current_user.get("role") or "").lower()
    if role == "super_admin" and not current_user.get("company_id"):
        return  # Super admin has all permissions
    perms = current_user.get("permissions") or []
    if permission not in perms:
        raise HTTPException(status_code=403, detail=f"Permission required: {permission}")


def _company_id_str(company_id) -> str | None:
    """Payroll tables use company_id VARCHAR(24); cast for SQL."""
    return str(company_id) if company_id is not None else None


# ============================================================================
# MODELS - Request/Response
# ============================================================================

class SalaryComponentBody(BaseModel):
    name: str
    displayName: str
    type: str  # 'earning' or 'deduction'
    category: str | None = None  # 'fixed', 'variable', 'statutory', 'voluntary'
    calculationType: str  # 'fixed_amount', 'percentage_of_basic', 'percentage_of_gross', 'formula', 'attendance_based'
    calculationValue: float | None = None
    formula: str | None = None
    isTaxable: bool = True
    isStatutory: bool = False
    affectsGross: bool = True
    affectsNet: bool = True
    minValue: float | None = None
    maxValue: float | None = None
    appliesToCategories: list[str] | None = None
    priorityOrder: int = 0
    isActive: bool = True
    remarks: str | None = None


class SalaryModalComponentItem(BaseModel):
    """One component in a salary modal, with optional overrides for this template."""
    componentId: int
    displayOrder: int = 0
    typeOverride: str | None = None  # 'earning' | 'deduction'
    calculationTypeOverride: str | None = None
    calculationValueOverride: float | None = None
    isTaxableOverride: bool | None = None
    isStatutoryOverride: bool | None = None


class CreateSalaryModalBody(BaseModel):
    """Create salary modal (template): name, description, list of components (with optional overrides)."""
    name: str
    description: str | None = None
    components: list[SalaryModalComponentItem] | None = None  # if omitted, empty template
    componentIds: list[int] | None = None  # legacy: just IDs in order (no overrides)


class UpdateSalaryModalBody(BaseModel):
    name: str | None = None
    description: str | None = None
    isActive: bool | None = None
    components: list[SalaryModalComponentItem] | None = None
    componentIds: list[int] | None = None  # legacy


class PayrollSettingsBody(BaseModel):
    payCycleType: str = "monthly"
    payDay: int = 1
    attendanceCutoffDay: int = 25
    workingDaysBasis: str = "26_days"
    customWorkingDays: int | None = None
    workingHoursPerDay: float = 8.0
    paidLeaveTypes: list[str] | None = None
    unpaidLeaveTypes: list[str] | None = None
    leaveEncashmentEnabled: bool = False
    leaveEncashmentRules: dict | None = None
    sandwichLeavePolicy: str = "count_as_leave"
    lopCalculationMethod: str = "per_day"
    lopDeductionMultiplier: float = 1.0
    graceDaysPerMonth: int = 0
    lateComingRules: dict | None = None
    halfDayRules: dict | None = None
    overtimeEnabled: bool = False
    overtimeCalculationBasis: str = "hourly"
    weekdayOtMultiplier: float = 1.5
    weekendOtMultiplier: float = 2.0
    holidayOtMultiplier: float = 2.5
    maxOtHoursPerMonth: float | None = None
    otEligibilityCriteria: dict | None = None
    holidayWorkCompensation: str = "double_pay"
    pfEnabled: bool = True
    pfEmployeeRate: float = 12.0
    pfEmployerRate: float = 12.0
    pfWageCeiling: float = 15000.0
    pfCalculationBasis: str = "basic_only"
    esiEnabled: bool = True
    esiEmployeeRate: float = 0.75
    esiEmployerRate: float = 3.25
    esiWageCeiling: float = 21000.0
    ptEnabled: bool = True
    ptState: str | None = None
    ptSlabRules: dict | None = None
    tdsEnabled: bool = True
    tdsCalculationMethod: str = "monthly"
    gratuityEnabled: bool = True
    gratuityMinServiceYears: int = 5
    gratuityFormula: str = "15/26"
    gratuityWageBasis: str = "basic_only"
    joiningDayIncluded: bool = True
    exitDayIncluded: bool = False
    prorataCalculationBasis: str = "calendar_days"
    arrearsEnabled: bool = True
    arrearsPaymentMethod: str = "lump_sum"
    locationBasedAllowances: dict | None = None
    defaultTaxRegime: str = "old"
    reimbursementCategories: dict | None = None
    currency: str = "INR"
    remarks: str | None = None


class OvertimeSettingsBody(BaseModel):
    """Body for PATCH /payroll/settings/overtime (Salary Components > Overtime tab)."""
    overtimeCalculationMethod: str = "fixed_amount"  # 'fixed_amount' | 'gross_pay_multiplier' | 'basic_pay_multiplier'
    overtimeFixedAmountPerHour: float | None = None
    overtimeGrossPayMultiplier: float | None = None
    overtimeBasicPayMultiplier: float | None = None


class OvertimeTemplateBody(BaseModel):
    """Body for create/update overtime template (universal customizable config)."""
    name: str | None = None
    companyType: str | None = None  # manufacturing, it, healthcare, retail, corporate, custom
    isDefault: bool | None = None
    config: dict | None = None  # full overtimeRules + optional companyType; default below


def _default_overtime_config() -> dict:
    """Default universal config for new templates. Level 1: calculation base; Level 2: multipliers; Level 3: caps/eligibility/approval/payment."""
    return {
        "companyType": "custom",
        "overtimeRules": {
            "calculationBase": "gross_salary",  # fixed_amount | gross_salary | basic_da | combination | tiered_rates
            "defaultMultiplier": 1.5,
            "fixedAmountPerHour": None,
            "grossPercentage": None,
            "basicDaPercentage": None,
            "combinationRule": "higher_of",  # higher_of | sum
            "combinationFixedAmount": None,
            "combinationPercentageOf": None,  # gross_salary | basic_da
            "combinationPercentage": None,  # e.g. 100 for 100%
            "tieredRates": {
                "weekday": 1.5,
                "saturday": 1.75,
                "sunday": 2.0,
                "holiday": 2.5,
                "nightShift": 1.75,
                "doubleShift": 2.0,
            },
            "caps": {"daily": 4, "weekly": 20, "monthly": 60},
            "eligibility": {
                "minServiceDays": 30,
                "excludeEmployees": [],
                "excludeRoles": ["trainees", "interns"],
                "minHoursForOT": 1,
            },
            "approvalWorkflow": {
                "required": True,
                "levels": 2,
                "autoApproveUpTo": 10,
            },
            "paymentOptions": {
                "payInSalary": True,
                "compensatoryOff": False,
                "carryForward": 5,
                "lapseAfter": 90,
            },
        },
    }


class EmployeeSalaryStructureBody(BaseModel):
    employeeId: int
    effectiveFrom: str
    effectiveTo: str | None = None
    ctc: float
    grossSalary: float
    netSalary: float
    earnings: list[dict]  # [{"componentId": 1, "name": "Basic", "amount": 50000}]
    deductions: list[dict]
    workingDaysBasis: str | None = None
    paidLeaveTypes: list[str] | None = None
    pfApplicable: bool = True
    pfEmployeeRate: float | None = None
    esiApplicable: bool = True
    ptApplicable: bool = True
    revisionReason: str | None = None
    remarks: str | None = None


class PayrollRunBody(BaseModel):
    month: int  # 1-12
    year: int
    payPeriodStart: str
    payPeriodEnd: str
    departmentFilter: str | None = None
    branchFilter: int | None = None
    employeeIds: list[int] | None = None
    remarks: str | None = None


class PayrollTransactionUpdateBody(BaseModel):
    status: str | None = None
    holdReason: str | None = None
    paymentMode: str | None = None
    paymentDate: str | None = None
    paymentReference: str | None = None
    remarks: str | None = None


class TaxDeclarationBody(BaseModel):
    financialYear: str
    taxRegime: str = "old"
    section80c: dict | None = None
    section80cTotal: float = 0
    section80dSelf: float = 0
    section80dParents: float = 0
    hraExemptionDetails: dict | None = None
    section80g: float = 0
    section24: float = 0
    ltaClaimed: float = 0
    standardDeduction: float = 50000
    proofDocuments: dict | None = None
    remarks: str | None = None


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def _serialize_decimal(obj):
    """Convert Decimal to float for JSON serialization"""
    if isinstance(obj, Decimal):
        return float(obj)
    elif isinstance(obj, dict):
        return {k: _serialize_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [_serialize_decimal(item) for item in obj]
    elif isinstance(obj, date):
        return obj.isoformat()
    return obj


def _calculate_working_days(year: int, month: int, basis: str, custom_days: int = None) -> float:
    """Calculate working days based on company policy"""
    if basis == "26_days":
        return 26.0
    elif basis == "30_days":
        return 30.0
    elif basis == "custom" and custom_days:
        return float(custom_days)
    elif basis == "actual_calendar":
        # Get actual days in month
        if month == 12:
            next_month = datetime(year + 1, 1, 1)
        else:
            next_month = datetime(year, month + 1, 1)
        current_month = datetime(year, month, 1)
        return (next_month - current_month).days
    return 26.0  # Default


def _calculate_per_day_rate(monthly_salary: float, working_days: float) -> float:
    """Calculate per day salary rate"""
    if working_days == 0:
        return 0
    return monthly_salary / working_days


def _calculate_component_amount(component: dict, basic_salary: float, gross_salary: float, attendance_data: dict = None) -> float:
    """Calculate amount for a salary component based on its calculation type"""
    calc_type = component.get("calculation_type", "fixed_amount")
    calc_value = float(component.get("calculation_value", 0))
    
    if calc_type == "fixed_amount":
        amount = calc_value
    elif calc_type == "percentage_of_basic":
        amount = (basic_salary * calc_value) / 100
    elif calc_type == "percentage_of_gross":
        amount = (gross_salary * calc_value) / 100
    elif calc_type == "formula":
        # TODO: Implement formula evaluation (safe eval)
        amount = calc_value
    elif calc_type == "attendance_based":
        # Adjust based on attendance
        if attendance_data:
            days_present = attendance_data.get("days_present", 0)
            working_days = attendance_data.get("total_working_days", 26)
            amount = (calc_value * days_present) / working_days if working_days > 0 else 0
        else:
            amount = calc_value
    else:
        amount = calc_value
    
    # Apply min/max constraints
    min_val = component.get("min_value")
    max_val = component.get("max_value")
    if min_val is not None:
        amount = max(amount, float(min_val))
    if max_val is not None:
        amount = min(amount, float(max_val))
    
    return round(amount, 2)


def _fetch_attendance_summary(db_name: str, employee_id: int, month: int, year: int) -> dict:
    """Fetch attendance summary for an employee for a given month"""
    with get_cursor(db_name=db_name) as cur:
        # Get attendance records for the month
        cur.execute("""
            SELECT 
                COUNT(*) FILTER (WHERE status IN ('present', 'late')) as days_present,
                COUNT(*) FILTER (WHERE status = 'absent') as days_absent,
                COUNT(*) FILTER (WHERE status = 'half_day') as days_half,
                SUM(COALESCE(work_hours, 0)) as total_work_hours,
                SUM(COALESCE(overtime, 0)) as total_overtime,
                SUM(COALESCE(late_minutes, 0)) as total_late_minutes,
                COUNT(*) FILTER (WHERE late_minutes > 0) as late_days
            FROM attendances
            WHERE employee_id = %s
              AND EXTRACT(MONTH FROM date) = %s
              AND EXTRACT(YEAR FROM date) = %s
        """, (str(employee_id), month, year))
        
        row = cur.fetchone()
        if not row:
            return {
                "days_present": 0,
                "days_absent": 0,
                "days_half": 0,
                "total_work_hours": 0,
                "total_overtime": 0,
                "total_late_minutes": 0,
                "late_days": 0
            }
        
        return {
            "days_present": float(row["days_present"] or 0) + (float(row["days_half"] or 0) * 0.5),
            "days_absent": float(row["days_absent"] or 0),
            "days_half": float(row["days_half"] or 0),
            "total_work_hours": float(row["total_work_hours"] or 0),
            "total_overtime": float(row["total_overtime"] or 0),
            "total_late_minutes": int(row["total_late_minutes"] or 0),
            "late_days": int(row["late_days"] or 0)
        }


def _fetch_leave_summary(db_name: str, employee_id: int, month: int, year: int, paid_leave_types: list) -> dict:
    """Fetch leave summary for an employee for a given month"""
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            SELECT 
                leave_type,
                SUM(days) as total_days
            FROM leaves
            WHERE employee_id = %s
              AND status = 'approved'
              AND EXTRACT(MONTH FROM start_date) = %s
              AND EXTRACT(YEAR FROM start_date) = %s
            GROUP BY leave_type
        """, (str(employee_id), month, year))
        
        rows = cur.fetchall()
        
        paid_days = 0
        unpaid_days = 0
        total_days = 0
        
        for row in rows:
            leave_type = row["leave_type"]
            days = float(row["total_days"] or 0)
            total_days += days
            
            if leave_type in paid_leave_types:
                paid_days += days
            else:
                unpaid_days += days
        
        return {
            "total_leaves": total_days,
            "paid_leaves": paid_days,
            "unpaid_leaves": unpaid_days,
            "lop_days": unpaid_days
        }


# ============================================================================
# SALARY COMPONENTS ENDPOINTS
# ============================================================================

@router.get("/components")
def get_salary_components(
    type: str | None = Query(None),
    current_user=Depends(get_current_user)
):
    """Get all salary components (earnings and deductions) for the company"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        query = """
            SELECT 
                id, name, display_name, type, category,
                calculation_type, calculation_value, formula,
                is_taxable, is_statutory, affects_gross, affects_net,
                min_value, max_value, applies_to_categories,
                priority_order, is_active, remarks, created_at
            FROM salary_components
            WHERE company_id = %s
        """
        params = [_company_id_str(company_id)]
        
        if type:
            query += " AND type = %s"
            params.append(type)
        
        query += " ORDER BY priority_order, name"
        
        cur.execute(query, params)
        components = cur.fetchall()
        
        return {
            "components": [dict(_serialize_decimal(c)) for c in components],
            "count": len(components)
        }


@router.post("/components")
def create_salary_component(
    body: SalaryComponentBody,
    current_user=Depends(get_current_user)
):
    """Create a new salary component"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            INSERT INTO salary_components (
                company_id, name, display_name, type, category,
                calculation_type, calculation_value, formula,
                is_taxable, is_statutory, affects_gross, affects_net,
                min_value, max_value, applies_to_categories,
                priority_order, is_active, remarks
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING id
        """, (
                _company_id_str(company_id), body.name, body.displayName, body.type, body.category,
            body.calculationType, body.calculationValue, body.formula,
            body.isTaxable, body.isStatutory, body.affectsGross, body.affectsNet,
            body.minValue, body.maxValue, json.dumps(body.appliesToCategories) if body.appliesToCategories else None,
            body.priorityOrder, body.isActive, body.remarks
        ))
        
        component_id = cur.fetchone()["id"]
        
        _audit_log(user_id, company_id, "created", "salary_component", str(component_id))
        
        return {"id": component_id, "message": "Salary component created"}


@router.patch("/components/{component_id}")
def update_salary_component(
    component_id: int,
    body: SalaryComponentBody,
    current_user=Depends(get_current_user)
):
    """Update a salary component"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    user_id = current_user.get("id")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            UPDATE salary_components SET
                name = %s, display_name = %s, category = %s,
                calculation_type = %s, calculation_value = %s, formula = %s,
                is_taxable = %s, is_statutory = %s, affects_gross = %s, affects_net = %s,
                min_value = %s, max_value = %s, applies_to_categories = %s,
                priority_order = %s, is_active = %s, remarks = %s,
                updated_at = NOW()
            WHERE id = %s
        """, (
            body.name, body.displayName, body.category,
            body.calculationType, body.calculationValue, body.formula,
            body.isTaxable, body.isStatutory, body.affectsGross, body.affectsNet,
            body.minValue, body.maxValue, json.dumps(body.appliesToCategories) if body.appliesToCategories else None,
            body.priorityOrder, body.isActive, body.remarks,
            component_id
        ))
        
        _audit_log(user_id, company_id, "updated", "salary_component", str(component_id))
        
        return {"message": "Salary component updated"}


@router.delete("/components/{component_id}")
def delete_salary_component(
    component_id: int,
    current_user=Depends(get_current_user)
):
    """Delete a salary component (soft delete by marking inactive)"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    user_id = current_user.get("id")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            UPDATE salary_components 
            SET is_active = FALSE, updated_at = NOW()
            WHERE id = %s
        """, (component_id,))
        
        _audit_log(user_id, company_id, "deleted", "salary_component", str(component_id))
        
        return {"message": "Salary component deleted"}


# ============================================================================
# SALARY MODALS (Templates: name, description, set of components)
# ============================================================================

def _salary_modal_component_response(row: dict) -> dict:
    """Build API response for one component in a modal (with base fields + overrides)."""
    d = dict(_serialize_decimal(row))
    # RealDictCursor returns lowercase keys
    return {
        "id": d.get("id"),
        "componentId": d.get("componentid"),
        "displayOrder": d.get("displayorder", 0),
        "typeOverride": d.get("typeoverride"),
        "calculationTypeOverride": d.get("calculationtypeoverride"),
        "calculationValueOverride": d.get("calculationvalueoverride"),
        "isTaxableOverride": d.get("istaxableoverride"),
        "isStatutoryOverride": d.get("isstatutoryoverride"),
        "name": d.get("name"),
        "displayName": d.get("displayname"),
        "type": d.get("type"),
        "calculationType": d.get("calculationtype"),
        "calculationValue": d.get("calculationvalue"),
        "isTaxable": d.get("istaxable"),
        "isStatutory": d.get("isstatutory"),
    }


def _salary_modal_row(row: dict, components: list | None = None) -> dict:
    """Build API response for a salary modal."""
    out = {
        "id": row["id"],
        "name": row.get("name") or "",
        "description": row.get("description"),
        "isActive": bool(row.get("is_active", True)),
        "createdAt": row.get("created_at").isoformat() if row.get("created_at") and hasattr(row["created_at"], "isoformat") else str(row.get("created_at")) if row.get("created_at") else None,
        "updatedAt": row.get("updated_at").isoformat() if row.get("updated_at") and hasattr(row["updated_at"], "isoformat") else str(row.get("updated_at")) if row.get("updated_at") else None,
    }
    if components is not None:
        out["components"] = components
    return out


@router.get("/salary-modals")
def get_salary_modals(
    active_only: bool = Query(True, alias="activeOnly"),
    current_user=Depends(get_current_user)
):
    """List all salary modals (templates) for the company."""
    check_permission(current_user, "payroll.view")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    with get_cursor(db_name=db_name) as cur:
        q = """
            SELECT id, name, description, is_active, created_at, updated_at
            FROM salary_modals
            WHERE company_id = %s
        """
        params: list = [_company_id_str(company_id)]
        if active_only:
            q += " AND is_active = TRUE"
        q += " ORDER BY name"
        cur.execute(q, params)
        rows = cur.fetchall()
        modals = []
        for r in rows:
            cur.execute(
                """
                SELECT smc.id, smc.salary_component_id AS componentId, smc.display_order AS displayOrder,
                       smc.type_override AS typeOverride, smc.calculation_type_override AS calculationTypeOverride,
                       smc.calculation_value_override AS calculationValueOverride,
                       smc.is_taxable_override AS isTaxableOverride,
                       smc.is_statutory_override AS isStatutoryOverride,
                       sc.name, sc.display_name AS displayName, sc.type, sc.calculation_type AS calculationType,
                       sc.calculation_value AS calculationValue, sc.is_taxable AS isTaxable, sc.is_statutory AS isStatutory
                FROM salary_modal_components smc
                JOIN salary_components sc ON sc.id = smc.salary_component_id
                WHERE smc.salary_modal_id = %s
                ORDER BY smc.display_order, smc.id
                """,
                (r["id"],),
            )
            comp_rows = cur.fetchall()
            comp_list = [_salary_modal_component_response(c) for c in comp_rows]
            modals.append(_salary_modal_row(dict(r), comp_list))
        return {"modals": modals, "count": len(modals)}


@router.post("/salary-modals")
def create_salary_modal(
    body: CreateSalaryModalBody,
    current_user=Depends(get_current_user)
):
    """Create a salary modal (template) with name, description, and components."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    if not db_name:
        raise HTTPException(
            status_code=503,
            detail="Company database not configured. Please log in again or contact support.",
        )
    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Modal name is required")
    try:
        with get_cursor(db_name=db_name) as cur:
            cur.execute(
                """
                INSERT INTO salary_modals (company_id, name, description, is_active)
                VALUES (%s, %s, %s, TRUE)
                RETURNING id, name, description, is_active, created_at, updated_at
                """,
                (_company_id_str(company_id), name, (body.description or "").strip() or None),
            )
            row = cur.fetchone()
            modal_id = row["id"]
            if body.components:
                for idx, item in enumerate(body.components):
                    cur.execute(
                        """
                        INSERT INTO salary_modal_components (salary_modal_id, salary_component_id, display_order, type_override, calculation_type_override, calculation_value_override, is_taxable_override, is_statutory_override)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (salary_modal_id, salary_component_id) DO UPDATE SET
                          display_order = EXCLUDED.display_order,
                          type_override = EXCLUDED.type_override,
                          calculation_type_override = EXCLUDED.calculation_type_override,
                          calculation_value_override = EXCLUDED.calculation_value_override,
                          is_taxable_override = EXCLUDED.is_taxable_override,
                          is_statutory_override = EXCLUDED.is_statutory_override
                        """,
                        (modal_id, item.componentId, item.displayOrder if item.displayOrder else idx,
                         item.typeOverride, item.calculationTypeOverride,
                         item.calculationValueOverride, item.isTaxableOverride, item.isStatutoryOverride),
                    )
            else:
                for idx, comp_id in enumerate(body.componentIds or []):
                    cur.execute(
                        """
                        INSERT INTO salary_modal_components (salary_modal_id, salary_component_id, display_order)
                        VALUES (%s, %s, %s)
                        ON CONFLICT (salary_modal_id, salary_component_id) DO UPDATE SET display_order = EXCLUDED.display_order
                        """,
                        (modal_id, comp_id, idx),
                    )
            _audit_log(user_id, company_id, "created", "salary_modal", str(modal_id))
            cur.execute(
                "SELECT id, name, description, is_active, created_at, updated_at FROM salary_modals WHERE id = %s",
                (modal_id,),
            )
            r = cur.fetchone()
            cur.execute(
                """
                SELECT smc.id, smc.salary_component_id AS componentId, smc.display_order AS displayOrder,
                       smc.type_override AS typeOverride, smc.calculation_type_override AS calculationTypeOverride,
                       smc.calculation_value_override AS calculationValueOverride,
                       smc.is_taxable_override AS isTaxableOverride,
                       smc.is_statutory_override AS isStatutoryOverride,
                       sc.name, sc.display_name AS displayName, sc.type, sc.calculation_type AS calculationType,
                       sc.calculation_value AS calculationValue, sc.is_taxable AS isTaxable, sc.is_statutory AS isStatutory
                FROM salary_modal_components smc
                JOIN salary_components sc ON sc.id = smc.salary_component_id
                WHERE smc.salary_modal_id = %s
                ORDER BY smc.display_order, smc.id
                """,
                (modal_id,),
            )
            comp_list = [_salary_modal_component_response(c) for c in cur.fetchall()]
            return _salary_modal_row(dict(r), comp_list)
    except Exception as e:
        err_msg = str(e).lower()
        if psycopg2 and isinstance(e, psycopg2.ProgrammingError):
            if "salary_modals" in err_msg and ("does not exist" in err_msg or "relation" in err_msg):
                raise HTTPException(
                    status_code=503,
                    detail="Payroll schema not initialized for this tenant. Run the payroll schema migration (init_payroll_schema.py) for your company database.",
                ) from e
            if "salary_modal_components" in err_msg and ("does not exist" in err_msg or "relation" in err_msg):
                raise HTTPException(
                    status_code=503,
                    detail="Payroll schema not initialized for this tenant. Run the payroll schema migration (init_payroll_schema.py) for your company database.",
                ) from e
        raise HTTPException(status_code=500, detail=f"Failed to create salary modal: {e!s}") from e


@router.get("/salary-modals/{modal_id}")
def get_salary_modal(
    modal_id: int,
    current_user=Depends(get_current_user)
):
    """Get a single salary modal with its components."""
    check_permission(current_user, "payroll.view")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    with get_cursor(db_name=db_name) as cur:
        cur.execute(
            "SELECT id, name, description, is_active, created_at, updated_at FROM salary_modals WHERE id = %s AND company_id = %s",
            (modal_id, _company_id_str(company_id)),
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Salary modal not found")
        cur.execute(
            """
            SELECT smc.id, smc.salary_component_id AS componentId, smc.display_order AS displayOrder,
                   smc.type_override AS typeOverride, smc.calculation_type_override AS calculationTypeOverride,
                   smc.calculation_value_override AS calculationValueOverride,
                   smc.is_taxable_override AS isTaxableOverride,
                   smc.is_statutory_override AS isStatutoryOverride,
                   sc.name, sc.display_name AS displayName, sc.type, sc.calculation_type AS calculationType,
                   sc.calculation_value AS calculationValue, sc.is_taxable AS isTaxable, sc.is_statutory AS isStatutory
            FROM salary_modal_components smc
            JOIN salary_components sc ON sc.id = smc.salary_component_id
            WHERE smc.salary_modal_id = %s
            ORDER BY smc.display_order, smc.id
            """,
            (modal_id,),
        )
        comp_rows = cur.fetchall()
        comp_list = [_salary_modal_component_response(c) for c in comp_rows]
        return _salary_modal_row(dict(row), comp_list)


@router.patch("/salary-modals/{modal_id}")
def update_salary_modal(
    modal_id: int,
    body: UpdateSalaryModalBody,
    current_user=Depends(get_current_user)
):
    """Update a salary modal (name, description, isActive, or component list)."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        cur.execute(
            "SELECT id FROM salary_modals WHERE id = %s AND company_id = %s",
            (modal_id, _company_id_str(company_id)),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Salary modal not found")
        updates = []
        params: list = []
        if body.name is not None:
            name = (body.name or "").strip()
            if not name:
                raise HTTPException(status_code=400, detail="Modal name cannot be empty")
            updates.append("name = %s")
            params.append(name)
        if body.description is not None:
            updates.append("description = %s")
            params.append((body.description or "").strip() or None)
        if body.isActive is not None:
            updates.append("is_active = %s")
            params.append(body.isActive)
        if updates:
            updates.append("updated_at = NOW()")
            params.append(modal_id)
            cur.execute(
                f"UPDATE salary_modals SET {', '.join(updates)} WHERE id = %s",
                tuple(params),
            )
        if body.components is not None:
            cur.execute("DELETE FROM salary_modal_components WHERE salary_modal_id = %s", (modal_id,))
            for idx, item in enumerate(body.components):
                cur.execute(
                    """
                    INSERT INTO salary_modal_components (salary_modal_id, salary_component_id, display_order, type_override, calculation_type_override, calculation_value_override, is_taxable_override, is_statutory_override)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (modal_id, item.componentId, item.displayOrder if item.displayOrder else idx,
                     item.typeOverride, item.calculationTypeOverride,
                     item.calculationValueOverride, item.isTaxableOverride, item.isStatutoryOverride),
                )
        elif body.componentIds is not None:
            cur.execute("DELETE FROM salary_modal_components WHERE salary_modal_id = %s", (modal_id,))
            for idx, comp_id in enumerate(body.componentIds):
                cur.execute(
                    """
                    INSERT INTO salary_modal_components (salary_modal_id, salary_component_id, display_order)
                    VALUES (%s, %s, %s)
                    """,
                    (modal_id, comp_id, idx),
                )
        _audit_log(user_id, company_id, "updated", "salary_modal", str(modal_id))
        cur.execute(
            "SELECT id, name, description, is_active, created_at, updated_at FROM salary_modals WHERE id = %s",
            (modal_id,),
        )
        r = cur.fetchone()
        cur.execute(
            """
            SELECT smc.id, smc.salary_component_id AS componentId, smc.display_order AS displayOrder,
                   smc.type_override AS typeOverride, smc.calculation_type_override AS calculationTypeOverride,
                   smc.calculation_value_override AS calculationValueOverride,
                   smc.is_taxable_override AS isTaxableOverride,
                   smc.is_statutory_override AS isStatutoryOverride,
                   sc.name, sc.display_name AS displayName, sc.type, sc.calculation_type AS calculationType,
                   sc.calculation_value AS calculationValue, sc.is_taxable AS isTaxable, sc.is_statutory AS isStatutory
            FROM salary_modal_components smc
            JOIN salary_components sc ON sc.id = smc.salary_component_id
            WHERE smc.salary_modal_id = %s
            ORDER BY smc.display_order, smc.id
            """,
            (modal_id,),
        )
        comp_list = [_salary_modal_component_response(c) for c in cur.fetchall()]
        return _salary_modal_row(dict(r), comp_list)


@router.delete("/salary-modals/{modal_id}")
def delete_salary_modal(
    modal_id: int,
    current_user=Depends(get_current_user)
):
    """Delete a salary modal (and its component links)."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        cur.execute(
            "SELECT id FROM salary_modals WHERE id = %s AND company_id = %s",
            (modal_id, _company_id_str(company_id)),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Salary modal not found")
        cur.execute("DELETE FROM salary_modal_components WHERE salary_modal_id = %s", (modal_id,))
        cur.execute("DELETE FROM salary_modals WHERE id = %s", (modal_id,))
    _audit_log(user_id, company_id, "deleted", "salary_modal", str(modal_id))
    return {"message": "Salary modal deleted"}


# ============================================================================
# PAYROLL SETTINGS ENDPOINTS
# ============================================================================

@router.get("/settings")
def get_payroll_settings(current_user=Depends(get_current_user)):
    """Get company payroll settings"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            SELECT * FROM payroll_settings WHERE company_id = %s
        """, (_company_id_str(company_id),))
        
        settings = cur.fetchone()
        
        if not settings:
            # Return default settings if not configured
            return {
                "configured": False,
                "settings": {}
            }
        
        return {
            "configured": True,
            "settings": dict(_serialize_decimal(settings))
        }


@router.post("/settings")
def create_or_update_payroll_settings(
    body: PayrollSettingsBody,
    current_user=Depends(get_current_user)
):
    """Create or update company payroll settings"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    with get_cursor(db_name=db_name) as cur:
        # Check if settings exist
        cur.execute("SELECT id FROM payroll_settings WHERE company_id = %s", (_company_id_str(company_id),))
        existing = cur.fetchone()
        
        if existing:
            # Update
            cur.execute("""
                UPDATE payroll_settings SET
                    pay_cycle_type = %s, pay_day = %s, attendance_cutoff_day = %s,
                    working_days_basis = %s, custom_working_days = %s, working_hours_per_day = %s,
                    paid_leave_types = %s, unpaid_leave_types = %s,
                    leave_encashment_enabled = %s, leave_encashment_rules = %s,
                    sandwich_leave_policy = %s, lop_calculation_method = %s, lop_deduction_multiplier = %s,
                    grace_days_per_month = %s, late_coming_rules = %s, half_day_rules = %s,
                    overtime_enabled = %s, overtime_calculation_basis = %s,
                    weekday_ot_multiplier = %s, weekend_ot_multiplier = %s, holiday_ot_multiplier = %s,
                    max_ot_hours_per_month = %s, ot_eligibility_criteria = %s,
                    holiday_work_compensation = %s,
                    pf_enabled = %s, pf_employee_rate = %s, pf_employer_rate = %s,
                    pf_wage_ceiling = %s, pf_calculation_basis = %s,
                    esi_enabled = %s, esi_employee_rate = %s, esi_employer_rate = %s, esi_wage_ceiling = %s,
                    pt_enabled = %s, pt_state = %s, pt_slab_rules = %s,
                    tds_enabled = %s, tds_calculation_method = %s,
                    gratuity_enabled = %s, gratuity_min_service_years = %s, gratuity_formula = %s, gratuity_wage_basis = %s,
                    joining_day_included = %s, exit_day_included = %s, prorata_calculation_basis = %s,
                    arrears_enabled = %s, arrears_payment_method = %s,
                    location_based_allowances = %s, default_tax_regime = %s, reimbursement_categories = %s,
                    currency = %s, remarks = %s, updated_at = NOW()
                WHERE company_id = %s
            """, (
                body.payCycleType, body.payDay, body.attendanceCutoffDay,
                body.workingDaysBasis, body.customWorkingDays, body.workingHoursPerDay,
                json.dumps(body.paidLeaveTypes), json.dumps(body.unpaidLeaveTypes),
                body.leaveEncashmentEnabled, json.dumps(body.leaveEncashmentRules) if body.leaveEncashmentRules else None,
                body.sandwichLeavePolicy, body.lopCalculationMethod, body.lopDeductionMultiplier,
                body.graceDaysPerMonth, json.dumps(body.lateComingRules) if body.lateComingRules else None,
                json.dumps(body.halfDayRules) if body.halfDayRules else None,
                body.overtimeEnabled, body.overtimeCalculationBasis,
                body.weekdayOtMultiplier, body.weekendOtMultiplier, body.holidayOtMultiplier,
                body.maxOtHoursPerMonth, json.dumps(body.otEligibilityCriteria) if body.otEligibilityCriteria else None,
                body.holidayWorkCompensation,
                body.pfEnabled, body.pfEmployeeRate, body.pfEmployerRate, body.pfWageCeiling, body.pfCalculationBasis,
                body.esiEnabled, body.esiEmployeeRate, body.esiEmployerRate, body.esiWageCeiling,
                body.ptEnabled, body.ptState, json.dumps(body.ptSlabRules) if body.ptSlabRules else None,
                body.tdsEnabled, body.tdsCalculationMethod,
                body.gratuityEnabled, body.gratuityMinServiceYears, body.gratuityFormula, body.gratuityWageBasis,
                body.joiningDayIncluded, body.exitDayIncluded, body.prorataCalculationBasis,
                body.arrearsEnabled, body.arrearsPaymentMethod,
                json.dumps(body.locationBasedAllowances) if body.locationBasedAllowances else None,
                body.defaultTaxRegime, json.dumps(body.reimbursementCategories) if body.reimbursementCategories else None,
                body.currency, body.remarks,
                _company_id_str(company_id)
            ))
            message = "Payroll settings updated"
        else:
            # Insert (53 columns - placeholder count must match)
            _vals = (
                _company_id_str(company_id),
                body.payCycleType,
                body.payDay,
                body.attendanceCutoffDay,
                body.workingDaysBasis,
                body.customWorkingDays,
                body.workingHoursPerDay,
                json.dumps(body.paidLeaveTypes) if body.paidLeaveTypes is not None else None,
                json.dumps(body.unpaidLeaveTypes) if body.unpaidLeaveTypes is not None else None,
                body.leaveEncashmentEnabled,
                json.dumps(body.leaveEncashmentRules) if body.leaveEncashmentRules else None,
                body.sandwichLeavePolicy,
                body.lopCalculationMethod,
                body.lopDeductionMultiplier,
                body.graceDaysPerMonth,
                json.dumps(body.lateComingRules) if body.lateComingRules else None,
                json.dumps(body.halfDayRules) if body.halfDayRules else None,
                body.overtimeEnabled,
                body.overtimeCalculationBasis,
                body.weekdayOtMultiplier,
                body.weekendOtMultiplier,
                body.holidayOtMultiplier,
                body.maxOtHoursPerMonth,
                json.dumps(body.otEligibilityCriteria) if body.otEligibilityCriteria else None,
                body.holidayWorkCompensation,
                body.pfEnabled,
                body.pfEmployeeRate,
                body.pfEmployerRate,
                body.pfWageCeiling,
                body.pfCalculationBasis,
                body.esiEnabled,
                body.esiEmployeeRate,
                body.esiEmployerRate,
                body.esiWageCeiling,
                body.ptEnabled,
                body.ptState,
                json.dumps(body.ptSlabRules) if body.ptSlabRules else None,
                body.tdsEnabled,
                body.tdsCalculationMethod,
                body.gratuityEnabled,
                body.gratuityMinServiceYears,
                body.gratuityFormula,
                body.gratuityWageBasis,
                body.joiningDayIncluded,
                body.exitDayIncluded,
                body.prorataCalculationBasis,
                body.arrearsEnabled,
                body.arrearsPaymentMethod,
                json.dumps(body.locationBasedAllowances) if body.locationBasedAllowances else None,
                body.defaultTaxRegime,
                json.dumps(body.reimbursementCategories) if body.reimbursementCategories else None,
                body.currency,
                body.remarks,
            )
            _placeholders = ", ".join(["%s"] * len(_vals))
            _sql = (
                """
                INSERT INTO payroll_settings (
                    company_id, pay_cycle_type, pay_day, attendance_cutoff_day,
                    working_days_basis, custom_working_days, working_hours_per_day,
                    paid_leave_types, unpaid_leave_types,
                    leave_encashment_enabled, leave_encashment_rules,
                    sandwich_leave_policy, lop_calculation_method, lop_deduction_multiplier,
                    grace_days_per_month, late_coming_rules, half_day_rules,
                    overtime_enabled, overtime_calculation_basis,
                    weekday_ot_multiplier, weekend_ot_multiplier, holiday_ot_multiplier,
                    max_ot_hours_per_month, ot_eligibility_criteria,
                    holiday_work_compensation,
                    pf_enabled, pf_employee_rate, pf_employer_rate, pf_wage_ceiling, pf_calculation_basis,
                    esi_enabled, esi_employee_rate, esi_employer_rate, esi_wage_ceiling,
                    pt_enabled, pt_state, pt_slab_rules,
                    tds_enabled, tds_calculation_method,
                    gratuity_enabled, gratuity_min_service_years, gratuity_formula, gratuity_wage_basis,
                    joining_day_included, exit_day_included, prorata_calculation_basis,
                    arrears_enabled, arrears_payment_method,
                    location_based_allowances, default_tax_regime, reimbursement_categories,
                    currency, remarks
                ) VALUES ("""
                + _placeholders
                + ")"
            )
            cur.execute(_sql, _vals)
            message = "Payroll settings created"
        
        _audit_log(user_id, company_id, "updated" if existing else "created", "payroll_settings", str(company_id))
        
        return {"message": message}


@router.patch("/settings/overtime")
def update_payroll_overtime_settings(
    body: OvertimeSettingsBody,
    current_user=Depends(get_current_user),
):
    """Update only overtime calculation settings (Salary Components > Overtime tab)."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        cur.execute(
            """
            UPDATE payroll_settings SET
                overtime_calculation_method = %s,
                overtime_fixed_amount_per_hour = %s,
                overtime_gross_pay_multiplier = %s,
                overtime_basic_pay_multiplier = %s,
                updated_at = NOW()
            WHERE company_id = %s
            """,
            (
                body.overtimeCalculationMethod,
                body.overtimeFixedAmountPerHour,
                body.overtimeGrossPayMultiplier,
                body.overtimeBasicPayMultiplier,
                _company_id_str(company_id),
            ),
        )
        if cur.rowcount == 0:
            # No settings row yet; create one with just overtime fields (other columns use defaults)
            cur.execute(
                """
                INSERT INTO payroll_settings (
                    company_id, overtime_calculation_method,
                    overtime_fixed_amount_per_hour, overtime_gross_pay_multiplier, overtime_basic_pay_multiplier
                ) VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    _company_id_str(company_id),
                    body.overtimeCalculationMethod,
                    body.overtimeFixedAmountPerHour,
                    body.overtimeGrossPayMultiplier,
                    body.overtimeBasicPayMultiplier,
                ),
            )
    _audit_log(user_id, company_id, "updated", "payroll_settings_overtime", str(company_id))
    return {"message": "Overtime settings updated"}


# ============================================================================
# OVERTIME TEMPLATES (Multiple customizable templates per company)
# ============================================================================


def _ensure_overtime_templates_table(cur) -> None:
    """Create overtime_templates table and indexes if they do not exist (migration for existing DBs)."""
    cur.execute("""
        CREATE TABLE IF NOT EXISTS overtime_templates (
            id BIGSERIAL PRIMARY KEY,
            company_id VARCHAR(24) NOT NULL,
            name VARCHAR(255) NOT NULL,
            company_type VARCHAR(50) DEFAULT 'custom',
            is_default BOOLEAN DEFAULT FALSE,
            config JSONB NOT NULL DEFAULT '{}',
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW()
        )
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_overtime_templates_company ON overtime_templates(company_id)")
    cur.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS idx_overtime_templates_company_default
        ON overtime_templates(company_id) WHERE is_default = TRUE
    """)


@router.get("/overtime-templates")
def list_overtime_templates(current_user=Depends(get_current_user)):
    """List all overtime templates for the company."""
    check_permission(current_user, "payroll.view")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            """
            SELECT id, company_id, name, company_type, is_default, config, created_at, updated_at
            FROM overtime_templates
            WHERE company_id = %s
            ORDER BY is_default DESC, name
            """,
            (_company_id_str(company_id),),
        )
        rows = cur.fetchall()
    return {
        "templates": [
            {
                "id": r["id"],
                "companyId": r["company_id"],
                "name": r["name"],
                "companyType": r["company_type"] or "custom",
                "isDefault": bool(r["is_default"]),
                "config": _serialize_decimal(r["config"]) if r.get("config") else _default_overtime_config(),
                "createdAt": r["created_at"].isoformat() if r.get("created_at") else None,
                "updatedAt": r["updated_at"].isoformat() if r.get("updated_at") else None,
            }
            for r in rows
        ],
    }


@router.get("/overtime-templates/{template_id}")
def get_overtime_template(
    template_id: int,
    current_user=Depends(get_current_user),
):
    """Get one overtime template by id."""
    check_permission(current_user, "payroll.view")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            """
            SELECT id, company_id, name, company_type, is_default, config, created_at, updated_at
            FROM overtime_templates
            WHERE id = %s AND company_id = %s
            """,
            (template_id, _company_id_str(company_id)),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Overtime template not found")
    return {
        "id": row["id"],
        "companyId": row["company_id"],
        "name": row["name"],
        "companyType": row["company_type"] or "custom",
        "isDefault": bool(row["is_default"]),
        "config": _serialize_decimal(row["config"]) if row.get("config") else _default_overtime_config(),
        "createdAt": row["created_at"].isoformat() if row.get("created_at") else None,
        "updatedAt": row["updated_at"].isoformat() if row.get("updated_at") else None,
    }


@router.post("/overtime-templates")
def create_overtime_template(
    body: OvertimeTemplateBody,
    current_user=Depends(get_current_user),
):
    """Create a new overtime template. If isDefault=True, unsets other defaults."""
    check_permission(current_user, "payroll.write")
    if not (body.name or "").strip():
        raise HTTPException(status_code=400, detail="Template name is required")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    config = body.config if body.config is not None else _default_overtime_config()
    if isinstance(config, dict) and "companyType" not in config:
        config["companyType"] = body.companyType or "custom"
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        if body.isDefault:
            cur.execute(
                "UPDATE overtime_templates SET is_default = FALSE WHERE company_id = %s",
                (_company_id_str(company_id),),
            )
        cur.execute(
            """
            INSERT INTO overtime_templates (company_id, name, company_type, is_default, config, updated_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
            RETURNING id, name, company_type, is_default, config, created_at, updated_at
            """,
            (
                _company_id_str(company_id),
                (body.name or "").strip(),
                body.companyType or "custom",
                body.isDefault if body.isDefault is not None else False,
                json.dumps(config),
            ),
        )
        row = cur.fetchone()
    _audit_log(user_id, company_id, "created", "overtime_template", str(row["id"]))
    return {
        "id": row["id"],
        "companyId": _company_id_str(company_id),
        "name": row["name"],
        "companyType": row["company_type"] or "custom",
        "isDefault": bool(row["is_default"]),
        "config": _serialize_decimal(row["config"]) if row.get("config") else config,
        "createdAt": row["created_at"].isoformat() if row.get("created_at") else None,
        "updatedAt": row["updated_at"].isoformat() if row.get("updated_at") else None,
    }


@router.patch("/overtime-templates/{template_id}")
def update_overtime_template(
    template_id: int,
    body: OvertimeTemplateBody,
    current_user=Depends(get_current_user),
):
    """Update an overtime template. Partial update: only sent fields are changed."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            "SELECT id, config FROM overtime_templates WHERE id = %s AND company_id = %s",
            (template_id, _company_id_str(company_id)),
        )
        existing = cur.fetchone()
    if not existing:
        raise HTTPException(status_code=404, detail="Overtime template not found")
    updates = []
    params = []
    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name)
    if body.companyType is not None:
        updates.append("company_type = %s")
        params.append(body.companyType)
    if body.isDefault is not None:
        if body.isDefault:
            with get_cursor(db_name=db_name) as cur2:
                _ensure_overtime_templates_table(cur2)
                cur2.execute(
                    "UPDATE overtime_templates SET is_default = FALSE WHERE company_id = %s AND id != %s",
                    (_company_id_str(company_id), template_id),
                )
        updates.append("is_default = %s")
        params.append(body.isDefault)
    if body.config is not None:
        updates.append("config = %s")
        params.append(json.dumps(body.config))
    if not updates:
        return get_overtime_template(template_id, current_user)
    params.extend([template_id, _company_id_str(company_id)])
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            f"UPDATE overtime_templates SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s AND company_id = %s",
            params,
        )
    _audit_log(user_id, company_id, "updated", "overtime_template", str(template_id))
    return get_overtime_template(template_id, current_user)


@router.patch("/overtime-templates/{template_id}/set-default")
def set_default_overtime_template(
    template_id: int,
    current_user=Depends(get_current_user),
):
    """Set this template as the company default. Unsets other defaults."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            "SELECT id FROM overtime_templates WHERE id = %s AND company_id = %s",
            (template_id, _company_id_str(company_id)),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Overtime template not found")
        cur.execute(
            "UPDATE overtime_templates SET is_default = FALSE WHERE company_id = %s",
            (_company_id_str(company_id),),
        )
        cur.execute(
            "UPDATE overtime_templates SET is_default = TRUE, updated_at = NOW() WHERE id = %s",
            (template_id,),
        )
    _audit_log(user_id, company_id, "updated", "overtime_template_default", str(template_id))
    return {"message": "Default template set", "templateId": template_id}


@router.delete("/overtime-templates/{template_id}")
def delete_overtime_template(
    template_id: int,
    current_user=Depends(get_current_user),
):
    """Delete an overtime template."""
    check_permission(current_user, "payroll.write")
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    with get_cursor(db_name=db_name) as cur:
        _ensure_overtime_templates_table(cur)
        cur.execute(
            "DELETE FROM overtime_templates WHERE id = %s AND company_id = %s RETURNING id",
            (template_id, _company_id_str(company_id)),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Overtime template not found")
    _audit_log(user_id, company_id, "deleted", "overtime_template", str(template_id))
    return {"message": "Overtime template deleted"}


# ============================================================================
# EMPLOYEE SALARY STRUCTURE ENDPOINTS
# ============================================================================

@router.get("/salary-structures")
def get_employee_salary_structures(
    employeeId: int | None = Query(None),
    current: bool | None = Query(None),
    current_user=Depends(get_current_user)
):
    """Get employee salary structures"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        query = """
            SELECT 
                ess.*,
                s.name as employee_name,
                s.employee_id as employee_number
            FROM employee_salary_structures ess
            JOIN staff s ON ess.employee_id = s.id
            WHERE ess.company_id = %s
        """
        params = [_company_id_str(company_id)]
        
        if employeeId:
            query += " AND ess.employee_id = %s"
            params.append(str(employeeId))
        
        if current:
            query += " AND ess.is_current = TRUE"
        
        query += " ORDER BY ess.effective_from DESC"
        
        cur.execute(query, params)
        structures = cur.fetchall()
        
        return {
            "salaryStructures": [dict(_serialize_decimal(s)) for s in structures],
            "count": len(structures)
        }


@router.post("/salary-structures")
def create_employee_salary_structure(
    body: EmployeeSalaryStructureBody,
    current_user=Depends(get_current_user)
):
    """Create employee salary structure"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    with get_cursor(db_name=db_name) as cur:
        # Mark previous structures as not current
        cur.execute("""
            UPDATE employee_salary_structures 
            SET is_current = FALSE, effective_to = %s, updated_at = NOW()
            WHERE employee_id = %s AND is_current = TRUE
        """, (body.effectiveFrom, str(body.employeeId)))
        
        # Insert new structure
        cur.execute("""
            INSERT INTO employee_salary_structures (
                employee_id, company_id, effective_from, effective_to, is_current,
                ctc, gross_salary, net_salary, earnings, deductions,
                working_days_basis, paid_leave_types,
                pf_applicable, pf_employee_rate, esi_applicable, pt_applicable,
                revision_reason, remarks, created_by
            ) VALUES (
                %s, %s, %s, %s, TRUE, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING id
        """, (
            str(body.employeeId), _company_id_str(company_id), body.effectiveFrom, body.effectiveTo,
            body.ctc, body.grossSalary, body.netSalary,
            json.dumps(body.earnings), json.dumps(body.deductions),
            body.workingDaysBasis, json.dumps(body.paidLeaveTypes) if body.paidLeaveTypes else None,
            body.pfApplicable, body.pfEmployeeRate, body.esiApplicable, body.ptApplicable,
            body.revisionReason, body.remarks, str(user_id)
        ))
        
        structure_id = cur.fetchone()["id"]
        
        # Update staff table with current gross/net salary
        cur.execute("""
            UPDATE staff 
            SET gross_salary = %s, net_salary = %s, current_salary_structure_id = %s, updated_at = NOW()
            WHERE id = %s
        """, (body.grossSalary, body.netSalary, structure_id, body.employeeId))
        
        _audit_log(user_id, company_id, "created", "salary_structure", str(structure_id))
        
        return {"id": structure_id, "message": "Salary structure created"}


# ============================================================================
# PAYROLL RUN ENDPOINTS
# ============================================================================

@router.get("/runs")
def get_payroll_runs(
    month: int | None = Query(None),
    year: int | None = Query(None),
    status: str | None = Query(None),
    current_user=Depends(get_current_user)
):
    """Get payroll runs"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        query = """
            SELECT * FROM payroll_runs WHERE company_id = %s
        """
        params = [_company_id_str(company_id)]
        
        if month:
            query += " AND month = %s"
            params.append(month)
        
        if year:
            query += " AND year = %s"
            params.append(year)
        
        if status:
            query += " AND status = %s"
            params.append(status)
        
        query += " ORDER BY year DESC, month DESC"
        
        cur.execute(query, params)
        runs = cur.fetchall()
        
        return {
            "runs": [dict(_serialize_decimal(r)) for r in runs],
            "count": len(runs)
        }


@router.get("/runs/{run_id}")
def get_payroll_run(
    run_id: int,
    current_user=Depends(get_current_user)
):
    """Get detailed payroll run with transactions"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    
    with get_cursor(db_name=db_name) as cur:
        # Get run details
        cur.execute("SELECT * FROM payroll_runs WHERE id = %s", (run_id,))
        run = cur.fetchone()
        
        if not run:
            raise HTTPException(status_code=404, detail="Payroll run not found")
        
        # Get transactions
        cur.execute("""
            SELECT * FROM payroll_transactions 
            WHERE payroll_run_id = %s
            ORDER BY employee_name
        """, (run_id,))
        transactions = cur.fetchall()
        
        return {
            "run": dict(_serialize_decimal(run)),
            "transactions": [dict(_serialize_decimal(t)) for t in transactions],
            "transactionCount": len(transactions)
        }


@router.post("/runs")
def create_payroll_run(
    body: PayrollRunBody,
    current_user=Depends(get_current_user)
):
    """Create a new payroll run"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    with get_cursor(db_name=db_name) as cur:
        # Check if payroll already exists for this period
        cur.execute("""
            SELECT id FROM payroll_runs 
            WHERE company_id = %s AND month = %s AND year = %s
        """, (_company_id_str(company_id), body.month, body.year))
        
        existing = cur.fetchone()
        if existing:
            raise HTTPException(status_code=400, detail=f"Payroll run already exists for {body.month}/{body.year}")
        
        # Create payroll run
        cur.execute("""
            INSERT INTO payroll_runs (
                company_id, month, year, pay_period_start, pay_period_end,
                status, department_filter, branch_filter, employee_ids, remarks
            ) VALUES (
                %s, %s, %s, %s, %s, 'draft', %s, %s, %s, %s
            ) RETURNING id
        """, (
            _company_id_str(company_id), body.month, body.year, body.payPeriodStart, body.payPeriodEnd,
            body.departmentFilter, str(body.branchFilter) if body.branchFilter else None,
            json.dumps([str(e) for e in body.employeeIds]) if body.employeeIds else None,
            body.remarks
        ))
        
        run_id = cur.fetchone()["id"]
        
        _audit_log(user_id, company_id, "created", "payroll_run", str(run_id))
        
        return {"id": run_id, "message": "Payroll run created"}


@router.post("/runs/{run_id}/calculate")
def calculate_payroll_run(
    run_id: int,
    current_user=Depends(get_current_user)
):
    """Calculate payroll for all employees in the run"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    with get_cursor(db_name=db_name) as cur:
        # Get payroll run
        cur.execute("SELECT * FROM payroll_runs WHERE id = %s", (run_id,))
        run = cur.fetchone()
        
        if not run:
            raise HTTPException(status_code=404, detail="Payroll run not found")
        
        if run["status"] not in ["draft", "processing"]:
            raise HTTPException(status_code=400, detail=f"Cannot calculate payroll in {run['status']} status")
        
        # Update status to processing
        cur.execute("""
            UPDATE payroll_runs SET status = 'processing', updated_at = NOW()
            WHERE id = %s
        """, (run_id,))
        
        # Get payroll settings
        cur.execute("SELECT * FROM payroll_settings WHERE company_id = %s", (_company_id_str(company_id),))
        settings = cur.fetchone()
        
        if not settings:
            raise HTTPException(status_code=400, detail="Payroll settings not configured")
        
        working_days = _calculate_working_days(
            run["year"], 
            run["month"], 
            settings["working_days_basis"],
            settings.get("custom_working_days")
        )
        
        paid_leave_types = settings.get("paid_leave_types") or []
        if isinstance(paid_leave_types, str):
            paid_leave_types = json.loads(paid_leave_types)
        
        # Get employees to process
        # Staff table has business_id VARCHAR(24) for company scope (tenant_schema); no company_id column
        query = """
            SELECT DISTINCT s.* 
            FROM staff s
            WHERE s.business_id = %s AND s.status = 'active'
        """
        params = [_company_id_str(company_id)]
        
        if run["department_filter"]:
            query += " AND s.department = %s"
            params.append(run["department_filter"])
        
        if run["branch_filter"]:
            query += " AND s.branch_id = %s"
            params.append(str(run["branch_filter"]))
        
        if run["employee_ids"]:
            emp_ids = json.loads(run["employee_ids"]) if isinstance(run["employee_ids"], str) else run["employee_ids"]
            query += f" AND s.id IN ({','.join(['%s'] * len(emp_ids))})"
            params.extend(emp_ids)
        
        cur.execute(query, params)
        employees = cur.fetchall()
        
        total_employees = 0
        total_gross = 0
        total_deductions = 0
        total_net = 0
        
        # Process each employee
        for emp in employees:
            employee_id = emp["id"]
            
            # Get current salary structure
            cur.execute("""
                SELECT * FROM employee_salary_structures
                WHERE employee_id = %s AND is_current = TRUE
                LIMIT 1
            """, (str(employee_id),))
            
            sal_structure = cur.fetchone()
            if not sal_structure:
                # Skip employees without salary structure
                continue
            
            # Get attendance summary
            attendance_summary = _fetch_attendance_summary(db_name, employee_id, run["month"], run["year"])
            
            # Get leave summary
            leave_summary = _fetch_leave_summary(db_name, employee_id, run["month"], run["year"], paid_leave_types)
            
            # Calculate LOP days
            lop_days = leave_summary["lop_days"] + attendance_summary["days_absent"]
            
            # Calculate salaries
            gross_salary = float(sal_structure["gross_salary"])
            per_day_rate = _calculate_per_day_rate(gross_salary, working_days)
            lop_amount = per_day_rate * lop_days * float(settings["lop_deduction_multiplier"])
            
            # Parse earnings and deductions
            earnings = json.loads(sal_structure["earnings"]) if isinstance(sal_structure["earnings"], str) else sal_structure["earnings"]
            deductions = json.loads(sal_structure["deductions"]) if isinstance(sal_structure["deductions"], str) else sal_structure["deductions"]
            
            # Calculate total earnings (pro-rated for LOP)
            total_earnings = 0
            earnings_breakdown = []
            
            for earn in earnings:
                amount = float(earn["amount"])
                # Pro-rate based on attendance
                if lop_days > 0:
                    amount = amount * ((working_days - lop_days) / working_days)
                
                earnings_breakdown.append({
                    "name": earn["name"],
                    "amount": round(amount, 2)
                })
                total_earnings += amount
            
            # Calculate total deductions
            total_deductions_amt = 0
            deductions_breakdown = []
            
            for ded in deductions:
                amount = float(ded["amount"])
                deductions_breakdown.append({
                    "name": ded["name"],
                    "amount": round(amount, 2)
                })
                total_deductions_amt += amount
            
            # Add LOP deduction
            if lop_amount > 0:
                deductions_breakdown.append({
                    "name": "Loss of Pay",
                    "amount": round(lop_amount, 2)
                })
                total_deductions_amt += lop_amount
            
            # Calculate net salary
            net_salary = total_earnings - total_deductions_amt
            
            # Insert/Update payroll transaction
            cur.execute("""
                INSERT INTO payroll_transactions (
                    payroll_run_id, employee_id, company_id, month, year,
                    pay_period_start, pay_period_end,
                    employee_name, employee_number, designation, department,
                    total_working_days, days_present, days_absent, days_leave,
                    paid_leaves, unpaid_leaves, lop_days,
                    gross_salary, total_earnings, total_deductions, net_salary,
                    earnings_breakdown, deductions_breakdown,
                    lop_amount, status
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, 'calculated'
                )
                ON CONFLICT (payroll_run_id, employee_id) 
                DO UPDATE SET
                    total_working_days = EXCLUDED.total_working_days,
                    days_present = EXCLUDED.days_present,
                    days_absent = EXCLUDED.days_absent,
                    days_leave = EXCLUDED.days_leave,
                    paid_leaves = EXCLUDED.paid_leaves,
                    unpaid_leaves = EXCLUDED.unpaid_leaves,
                    lop_days = EXCLUDED.lop_days,
                    gross_salary = EXCLUDED.gross_salary,
                    total_earnings = EXCLUDED.total_earnings,
                    total_deductions = EXCLUDED.total_deductions,
                    net_salary = EXCLUDED.net_salary,
                    earnings_breakdown = EXCLUDED.earnings_breakdown,
                    deductions_breakdown = EXCLUDED.deductions_breakdown,
                    lop_amount = EXCLUDED.lop_amount,
                    status = 'calculated',
                    updated_at = NOW()
            """, (
                run_id, str(employee_id), _company_id_str(company_id), run["month"], run["year"],
                run["pay_period_start"], run["pay_period_end"],
                emp["name"], emp.get("employee_id"), emp.get("designation"), emp.get("department"),
                working_days, attendance_summary["days_present"], attendance_summary["days_absent"],
                leave_summary["total_leaves"], leave_summary["paid_leaves"], leave_summary["unpaid_leaves"], lop_days,
                gross_salary, total_earnings, total_deductions_amt, net_salary,
                json.dumps(earnings_breakdown), json.dumps(deductions_breakdown),
                lop_amount
            ))
            
            total_employees += 1
            total_gross += total_earnings
            total_deductions += total_deductions_amt
            total_net += net_salary
        
        # Update payroll run with totals
        cur.execute("""
            UPDATE payroll_runs SET
                status = 'calculated',
                total_employees = %s,
                total_gross = %s,
                total_deductions = %s,
                total_net_pay = %s,
                calculated_by = %s,
                calculated_at = NOW(),
                updated_at = NOW()
            WHERE id = %s
        """, (total_employees, total_gross, total_deductions, total_net, str(user_id), run_id))
        
        _audit_log(user_id, company_id, "calculated", "payroll_run", str(run_id))
        
        return {
            "message": "Payroll calculated successfully",
            "totalEmployees": total_employees,
            "totalGross": round(total_gross, 2),
            "totalDeductions": round(total_deductions, 2),
            "totalNetPay": round(total_net, 2)
        }


@router.post("/runs/{run_id}/approve")
def approve_payroll_run(
    run_id: int,
    current_user=Depends(get_current_user)
):
    """Approve a calculated payroll run"""
    check_permission(current_user, "payroll.approve")
    
    db_name = current_user.get("db_name")
    user_id = current_user.get("id")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            UPDATE payroll_runs SET
                status = 'approved',
                approved_by = %s,
                approved_at = NOW(),
                updated_at = NOW()
            WHERE id = %s AND status = 'calculated'
        """, (str(user_id), run_id))
        
        if cur.rowcount == 0:
            raise HTTPException(status_code=400, detail="Payroll run not found or not in calculated status")
        
        # Update all transactions to approved
        cur.execute("""
            UPDATE payroll_transactions SET status = 'approved', updated_at = NOW()
            WHERE payroll_run_id = %s AND status = 'calculated'
        """, (run_id,))
        
        _audit_log(user_id, company_id, "approved", "payroll_run", str(run_id))
        
        return {"message": "Payroll run approved"}


# ============================================================================
# PAYROLL TRANSACTION ENDPOINTS
# ============================================================================

@router.get("/transactions/{transaction_id}")
def get_payroll_transaction(
    transaction_id: int,
    current_user=Depends(get_current_user)
):
    """Get detailed payroll transaction (payslip)"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("SELECT * FROM payroll_transactions WHERE id = %s", (transaction_id,))
        transaction = cur.fetchone()
        
        if not transaction:
            raise HTTPException(status_code=404, detail="Payroll transaction not found")
        
        return {"transaction": dict(_serialize_decimal(transaction))}


@router.patch("/transactions/{transaction_id}")
def update_payroll_transaction(
    transaction_id: int,
    body: PayrollTransactionUpdateBody,
    current_user=Depends(get_current_user)
):
    """Update payroll transaction (mark as paid, hold, etc.)"""
    check_permission(current_user, "payroll.write")
    
    db_name = current_user.get("db_name")
    user_id = current_user.get("id")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        updates = []
        params = []
        
        if body.status:
            updates.append("status = %s")
            params.append(body.status)
        
        if body.holdReason:
            updates.append("hold_reason = %s")
            params.append(body.holdReason)
        
        if body.paymentMode:
            updates.append("payment_mode = %s")
            params.append(body.paymentMode)
        
        if body.paymentDate:
            updates.append("payment_date = %s")
            params.append(body.paymentDate)
        
        if body.paymentReference:
            updates.append("payment_reference = %s")
            params.append(body.paymentReference)
        
        if body.remarks:
            updates.append("remarks = %s")
            params.append(body.remarks)
        
        if not updates:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        updates.append("updated_at = NOW()")
        params.append(transaction_id)
        
        query = f"UPDATE payroll_transactions SET {', '.join(updates)} WHERE id = %s"
        cur.execute(query, params)
        
        _audit_log(user_id, company_id, "updated", "payroll_transaction", str(transaction_id))
        
        return {"message": "Payroll transaction updated"}


# ============================================================================
# TAX DECLARATION ENDPOINTS
# ============================================================================

@router.get("/tax-declarations")
def get_tax_declarations(
    employeeId: int | None = Query(None),
    financialYear: str | None = Query(None),
    current_user=Depends(get_current_user)
):
    """Get tax declarations"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    user_role = current_user.get("role", "")
    
    with get_cursor(db_name=db_name) as cur:
        query = "SELECT * FROM tax_declarations WHERE company_id = %s"
        params = [_company_id_str(company_id)]
        
        # If not admin/hr, show only own declarations
        if user_role not in ["super_admin", "company_admin", "hr"]:
            query += " AND employee_id = %s"
            params.append(str(user_id))
        elif employeeId:
            query += " AND employee_id = %s"
            params.append(str(employeeId))
        
        if financialYear:
            query += " AND financial_year = %s"
            params.append(financialYear)
        
        query += " ORDER BY created_at DESC"
        
        cur.execute(query, params)
        declarations = cur.fetchall()
        
        return {
            "declarations": [dict(_serialize_decimal(d)) for d in declarations],
            "count": len(declarations)
        }


@router.post("/tax-declarations")
def create_or_update_tax_declaration(
    body: TaxDeclarationBody,
    current_user=Depends(get_current_user)
):
    """Create or update tax declaration"""
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    user_id = current_user.get("id")
    
    # Calculate total exemptions
    total = (
        body.section80cTotal +
        body.section80dSelf +
        body.section80dParents +
        body.section80g +
        body.section24 +
        body.ltaClaimed +
        body.standardDeduction
    )
    
    with get_cursor(db_name=db_name) as cur:
        cur.execute("""
            INSERT INTO tax_declarations (
                employee_id, company_id, financial_year, tax_regime,
                section_80c, section_80c_total, section_80d_self, section_80d_parents,
                hra_exemption_details, section_80g, section_24, lta_claimed,
                standard_deduction, total_exemptions, proof_documents, remarks, status
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'draft'
            )
            ON CONFLICT (employee_id, financial_year)
            DO UPDATE SET
                tax_regime = EXCLUDED.tax_regime,
                section_80c = EXCLUDED.section_80c,
                section_80c_total = EXCLUDED.section_80c_total,
                section_80d_self = EXCLUDED.section_80d_self,
                section_80d_parents = EXCLUDED.section_80d_parents,
                hra_exemption_details = EXCLUDED.hra_exemption_details,
                section_80g = EXCLUDED.section_80g,
                section_24 = EXCLUDED.section_24,
                lta_claimed = EXCLUDED.lta_claimed,
                standard_deduction = EXCLUDED.standard_deduction,
                total_exemptions = EXCLUDED.total_exemptions,
                proof_documents = EXCLUDED.proof_documents,
                remarks = EXCLUDED.remarks,
                updated_at = NOW()
            RETURNING id
        """, (
            str(user_id), _company_id_str(company_id), body.financialYear, body.taxRegime,
            json.dumps(body.section80c) if body.section80c else None,
            body.section80cTotal, body.section80dSelf, body.section80dParents,
            json.dumps(body.hraExemptionDetails) if body.hraExemptionDetails else None,
            body.section80g, body.section24, body.ltaClaimed,
            body.standardDeduction, total,
            json.dumps(body.proofDocuments) if body.proofDocuments else None,
            body.remarks
        ))
        
        decl_id = cur.fetchone()["id"]
        
        _audit_log(user_id, company_id, "created_or_updated", "tax_declaration", str(decl_id))
        
        return {"id": decl_id, "message": "Tax declaration saved"}


# ============================================================================
# REPORTS & ANALYTICS
# ============================================================================

@router.get("/reports/summary")
def get_payroll_summary_report(
    year: int = Query(...),
    month: int | None = Query(None),
    current_user=Depends(get_current_user)
):
    """Get payroll summary report for analysis"""
    check_permission(current_user, "payroll.view")
    
    db_name = current_user.get("db_name")
    company_id = current_user.get("company_id")
    
    with get_cursor(db_name=db_name) as cur:
        query = """
            SELECT 
                pr.month,
                pr.year,
                pr.status,
                pr.total_employees,
                pr.total_gross,
                pr.total_deductions,
                pr.total_net_pay,
                pr.approved_at,
                pr.paid_at
            FROM payroll_runs pr
            WHERE pr.company_id = %s AND pr.year = %s
        """
        params = [_company_id_str(company_id), year]
        
        if month:
            query += " AND pr.month = %s"
            params.append(month)
        
        query += " ORDER BY pr.year DESC, pr.month DESC"
        
        cur.execute(query, params)
        runs = cur.fetchall()
        
        return {
            "summary": [dict(_serialize_decimal(r)) for r in runs]
        }
