-- Comprehensive Payroll System Schema
-- This schema supports flexible, multi-company payroll customization
-- Run this on each tenant database to add payroll tables

-- ============================================================================
-- 1. SALARY COMPONENTS MASTER (Earning & Deduction Templates)
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_components (
    id                  BIGSERIAL PRIMARY KEY,
    mongo_id            VARCHAR(24) NULL UNIQUE,
    company_id          VARCHAR(24) NULL,
    name                VARCHAR(255) NOT NULL,           -- e.g., "Basic Salary", "HRA", "PF"
    display_name        VARCHAR(255) NOT NULL,           -- Display label
    type                VARCHAR(20) NOT NULL,            -- 'earning' or 'deduction'
    category            VARCHAR(50) NULL,                -- 'fixed', 'variable', 'statutory', 'voluntary'
    calculation_type    VARCHAR(50) NOT NULL,            -- 'fixed_amount', 'percentage_of_basic', 'percentage_of_gross', 'formula', 'attendance_based'
    calculation_value   DOUBLE PRECISION NULL,           -- Value for percentage or fixed
    formula             TEXT NULL,                       -- Custom formula (e.g., "(basic + da) * 0.12")
    is_taxable          BOOLEAN DEFAULT TRUE,
    is_statutory        BOOLEAN DEFAULT FALSE,           -- PF, ESI, PT, TDS
    affects_gross       BOOLEAN DEFAULT TRUE,            -- Affects gross salary calculation
    affects_net         BOOLEAN DEFAULT TRUE,            -- Affects net salary calculation
    min_value           DOUBLE PRECISION NULL,           -- Minimum value
    max_value           DOUBLE PRECISION NULL,           -- Maximum cap
    applies_to_categories JSONB NULL,                    -- ["full_time", "contract"] - staff type filter
    priority_order      INTEGER DEFAULT 0,               -- Calculation order
    is_active           BOOLEAN DEFAULT TRUE,
    remarks             TEXT NULL,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_salary_components_company ON salary_components(company_id);
CREATE INDEX IF NOT EXISTS idx_salary_components_type ON salary_components(type);

-- ============================================================================
-- 1b. SALARY MODALS (Templates: name, description, set of salary components)
--     Assignable to department or staff for industry/department-specific salary structures.
-- ============================================================================
CREATE TABLE IF NOT EXISTS salary_modals (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          VARCHAR(24) NOT NULL,
    name                VARCHAR(255) NOT NULL,
    description         TEXT NULL,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_salary_modals_company ON salary_modals(company_id);

-- Links a salary modal to salary components (many components per modal).
-- Optional overrides allow template-specific value, taxable, statutory per component.
CREATE TABLE IF NOT EXISTS salary_modal_components (
    id                          BIGSERIAL PRIMARY KEY,
    salary_modal_id             BIGINT NOT NULL REFERENCES salary_modals(id) ON DELETE CASCADE,
    salary_component_id         BIGINT NOT NULL,
    display_order               INTEGER DEFAULT 0,
    type_override               VARCHAR(20) NULL,
    calculation_type_override   VARCHAR(50) NULL,
    calculation_value_override  DOUBLE PRECISION NULL,
    is_taxable_override         BOOLEAN NULL,
    is_statutory_override       BOOLEAN NULL,
    created_at                  TIMESTAMP DEFAULT NOW(),
    UNIQUE(salary_modal_id, salary_component_id)
);

CREATE INDEX IF NOT EXISTS idx_salary_modal_components_modal ON salary_modal_components(salary_modal_id);

-- ============================================================================
-- 2. PAYROLL SETTINGS (Company-wide configuration)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_settings (
    id                          BIGSERIAL PRIMARY KEY,
    company_id                  VARCHAR(24) UNIQUE NOT NULL,
    
    -- Pay Cycle Configuration
    pay_cycle_type              VARCHAR(30) DEFAULT 'monthly',    -- 'monthly', 'bi-monthly', 'weekly'
    pay_day                     INTEGER DEFAULT 1,                -- Day of month for salary (1-31)
    attendance_cutoff_day       INTEGER DEFAULT 25,               -- Attendance freeze date
    
    -- Working Days Configuration
    working_days_basis          VARCHAR(30) DEFAULT '26_days',    -- '26_days', '30_days', 'actual_calendar', 'custom'
    custom_working_days         INTEGER NULL,
    working_hours_per_day       DOUBLE PRECISION DEFAULT 8.0,
    
    -- Leave Configuration
    paid_leave_types            JSONB NULL,                       -- ["casual", "sick", "earned"]
    unpaid_leave_types          JSONB NULL,                       -- ["lwp"]
    leave_encashment_enabled    BOOLEAN DEFAULT FALSE,
    leave_encashment_rules      JSONB NULL,                       -- Max days, percentage, etc.
    sandwich_leave_policy       VARCHAR(30) DEFAULT 'count_as_leave', -- 'count_as_leave', 'ignore'
    
    -- Attendance & LOP Configuration
    lop_calculation_method      VARCHAR(50) DEFAULT 'per_day',    -- 'per_day', 'per_hour', 'progressive'
    lop_deduction_multiplier    DOUBLE PRECISION DEFAULT 1.0,     -- 1.0 = normal, 2.0 = double deduction
    grace_days_per_month        INTEGER DEFAULT 0,
    grace_config                JSONB NULL,                       -- Company-level grace: lateLogin, earlyLogout rules
    late_coming_rules           JSONB NULL,                       -- Grace minutes, penalties
    half_day_rules              JSONB NULL,                       -- Entry after X, exit before Y
    
    -- Overtime Configuration
    overtime_enabled            BOOLEAN DEFAULT FALSE,
    overtime_calculation_basis   VARCHAR(30) DEFAULT 'hourly',     -- 'hourly', 'daily'
    overtime_calculation_method VARCHAR(40) DEFAULT 'fixed_amount', -- 'fixed_amount', 'gross_pay_multiplier', 'basic_pay_multiplier'
    overtime_fixed_amount_per_hour DOUBLE PRECISION NULL,
    overtime_gross_pay_multiplier  DOUBLE PRECISION NULL,
    overtime_basic_pay_multiplier  DOUBLE PRECISION NULL,
    weekday_ot_multiplier       DOUBLE PRECISION DEFAULT 1.5,
    weekend_ot_multiplier       DOUBLE PRECISION DEFAULT 2.0,
    holiday_ot_multiplier       DOUBLE PRECISION DEFAULT 2.5,
    max_ot_hours_per_month      DOUBLE PRECISION NULL,
    ot_eligibility_criteria     JSONB NULL,                       -- Salary threshold, grades
    
    -- Holiday Configuration
    holiday_work_compensation   VARCHAR(30) DEFAULT 'double_pay', -- 'double_pay', 'comp_off', 'normal_pay'
    
    -- Statutory Configuration
    pf_enabled                  BOOLEAN DEFAULT TRUE,
    pf_employee_rate            DOUBLE PRECISION DEFAULT 12.0,    -- Percentage
    pf_employer_rate            DOUBLE PRECISION DEFAULT 12.0,
    pf_wage_ceiling             DOUBLE PRECISION DEFAULT 15000.0,
    pf_calculation_basis        VARCHAR(50) DEFAULT 'basic_only', -- 'basic_only', 'basic_da'
    
    esi_enabled                 BOOLEAN DEFAULT TRUE,
    esi_employee_rate           DOUBLE PRECISION DEFAULT 0.75,
    esi_employer_rate           DOUBLE PRECISION DEFAULT 3.25,
    esi_wage_ceiling            DOUBLE PRECISION DEFAULT 21000.0,
    
    pt_enabled                  BOOLEAN DEFAULT TRUE,
    pt_state                    VARCHAR(50) NULL,                 -- State for PT rules
    pt_slab_rules               JSONB NULL,                       -- Slab-wise PT deduction
    
    tds_enabled                 BOOLEAN DEFAULT TRUE,
    tds_calculation_method      VARCHAR(30) DEFAULT 'monthly',    -- 'monthly', 'quarterly', 'annual'
    
    -- Gratuity Configuration
    gratuity_enabled            BOOLEAN DEFAULT TRUE,
    gratuity_min_service_years  INTEGER DEFAULT 5,
    gratuity_formula            VARCHAR(100) DEFAULT '15/26',     -- '15/26' or '15/30'
    gratuity_wage_basis         VARCHAR(50) DEFAULT 'basic_only', -- 'basic_only', 'basic_da', 'gross'
    
    -- Pro-rata Configuration
    joining_day_included        BOOLEAN DEFAULT TRUE,
    exit_day_included           BOOLEAN DEFAULT FALSE,
    prorata_calculation_basis   VARCHAR(50) DEFAULT 'calendar_days', -- 'calendar_days', 'working_days'
    
    -- Arrears Configuration
    arrears_enabled             BOOLEAN DEFAULT TRUE,
    arrears_payment_method      VARCHAR(30) DEFAULT 'lump_sum',   -- 'lump_sum', 'installments'
    
    -- Location-based Configuration
    location_based_allowances   JSONB NULL,                       -- City-wise HRA, etc.
    
    -- Tax Configuration
    default_tax_regime          VARCHAR(20) DEFAULT 'old',        -- 'old', 'new'
    
    -- Reimbursement Configuration
    reimbursement_categories    JSONB NULL,                       -- Travel, medical, food, etc.
    
    -- General
    currency                    VARCHAR(10) DEFAULT 'INR',
    remarks                     TEXT NULL,
    created_at                  TIMESTAMP DEFAULT NOW(),
    updated_at                  TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 2b. OVERTIME TEMPLATES (Multiple customizable templates per company)
-- ============================================================================
-- Universal config: calculationBase, tieredRates, caps, eligibility, approvalWorkflow, paymentOptions
CREATE TABLE IF NOT EXISTS overtime_templates (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              VARCHAR(24) NOT NULL,
    name                    VARCHAR(255) NOT NULL,                -- e.g. "Manufacturing", "IT Standard", "Custom"
    company_type            VARCHAR(50) DEFAULT 'custom',        -- manufacturing, it, healthcare, retail, corporate, custom
    is_default              BOOLEAN DEFAULT FALSE,                -- one default per company
    config                  JSONB NOT NULL DEFAULT '{}',         -- full universal template (see below)
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_overtime_templates_company ON overtime_templates(company_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_overtime_templates_company_default
    ON overtime_templates(company_id) WHERE is_default = TRUE;

-- ============================================================================
-- 3. EMPLOYEE SALARY STRUCTURE (Individual assignments)
-- ============================================================================
CREATE TABLE IF NOT EXISTS employee_salary_structures (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Effective Period
    effective_from          DATE NOT NULL,
    effective_to            DATE NULL,
    is_current              BOOLEAN DEFAULT TRUE,
    
    -- Basic Info
    ctc                     DOUBLE PRECISION NOT NULL,
    gross_salary            DOUBLE PRECISION NOT NULL,
    net_salary              DOUBLE PRECISION NOT NULL,
    
    -- Salary Components (JSON array of component assignments)
    earnings                JSONB NOT NULL,                       -- [{"component_id": 1, "name": "Basic", "amount": 50000, ...}]
    deductions              JSONB NOT NULL,                       -- [{"component_id": 5, "name": "PF", "amount": 1800, ...}]
    
    -- Attendance & Leave Settings
    working_days_basis      VARCHAR(30) NULL,                     -- Override company setting
    paid_leave_types        JSONB NULL,                           -- Override for this employee
    
    -- Statutory overrides
    pf_applicable           BOOLEAN DEFAULT TRUE,
    pf_employee_rate        DOUBLE PRECISION NULL,                -- Override company rate
    esi_applicable          BOOLEAN DEFAULT TRUE,
    pt_applicable           BOOLEAN DEFAULT TRUE,
    
    -- Remarks
    revision_reason         TEXT NULL,
    remarks                 TEXT NULL,
    created_by              VARCHAR(24) NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emp_salary_structure_employee ON employee_salary_structures(employee_id);
CREATE INDEX IF NOT EXISTS idx_emp_salary_structure_current ON employee_salary_structures(is_current) WHERE is_current = TRUE;
CREATE INDEX IF NOT EXISTS idx_emp_salary_structure_effective ON employee_salary_structures(effective_from, effective_to);

-- ============================================================================
-- 4. PAYROLL RUNS (Monthly payroll processing)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_runs (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Period
    month                   INTEGER NOT NULL,                     -- 1-12
    year                    INTEGER NOT NULL,                     -- 2025
    pay_period_start        DATE NOT NULL,
    pay_period_end          DATE NOT NULL,
    
    -- Status
    status                  VARCHAR(30) DEFAULT 'draft',          -- 'draft', 'processing', 'calculated', 'approved', 'paid', 'cancelled'
    
    -- Filters (which employees included)
    department_filter       VARCHAR(255) NULL,
    branch_filter           VARCHAR(24) NULL,
    employee_ids            JSONB NULL,                           -- Specific employees if not all
    
    -- Statistics
    total_employees         INTEGER DEFAULT 0,
    total_gross             DOUBLE PRECISION DEFAULT 0,
    total_deductions        DOUBLE PRECISION DEFAULT 0,
    total_net_pay           DOUBLE PRECISION DEFAULT 0,
    
    -- Attendance Data Lock
    attendance_locked_at    TIMESTAMP NULL,
    attendance_data_snapshot JSONB NULL,                          -- Freeze attendance for the period
    
    -- Approval
    calculated_by           VARCHAR(24) NULL,
    calculated_at           TIMESTAMP NULL,
    approved_by             VARCHAR(24) NULL,
    approved_at             TIMESTAMP NULL,
    paid_by                 VARCHAR(24) NULL,
    paid_at                 TIMESTAMP NULL,
    
    -- Bank file
    bank_file_generated     BOOLEAN DEFAULT FALSE,
    bank_file_url           TEXT NULL,
    bank_file_format        VARCHAR(30) NULL,                     -- 'neft', 'rtgs', 'custom'
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(company_id, month, year)
);

CREATE INDEX IF NOT EXISTS idx_payroll_runs_company ON payroll_runs(company_id);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_period ON payroll_runs(month, year);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_status ON payroll_runs(status);

-- ============================================================================
-- 5. PAYROLL TRANSACTIONS (Individual employee payslips)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_transactions (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    payroll_run_id          BIGINT NOT NULL REFERENCES payroll_runs(id) ON DELETE CASCADE,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Period
    month                   INTEGER NOT NULL,
    year                    INTEGER NOT NULL,
    pay_period_start        DATE NOT NULL,
    pay_period_end          DATE NOT NULL,
    
    -- Employee Info (snapshot)
    employee_name           VARCHAR(255) NOT NULL,
    employee_number         VARCHAR(100) NULL,
    designation             VARCHAR(255) NULL,
    department              VARCHAR(255) NULL,
    branch                  VARCHAR(255) NULL,
    bank_account            VARCHAR(100) NULL,
    pan_number              VARCHAR(50) NULL,
    uan_number              VARCHAR(50) NULL,
    
    -- Attendance Summary
    total_working_days      DOUBLE PRECISION DEFAULT 0,
    days_present            DOUBLE PRECISION DEFAULT 0,
    days_absent             DOUBLE PRECISION DEFAULT 0,
    days_leave              DOUBLE PRECISION DEFAULT 0,
    paid_leaves             DOUBLE PRECISION DEFAULT 0,
    unpaid_leaves           DOUBLE PRECISION DEFAULT 0,
    lop_days                DOUBLE PRECISION DEFAULT 0,
    holidays_worked         DOUBLE PRECISION DEFAULT 0,
    overtime_hours          DOUBLE PRECISION DEFAULT 0,
    late_days               INTEGER DEFAULT 0,
    
    -- Salary Calculation
    gross_salary            DOUBLE PRECISION NOT NULL,
    total_earnings          DOUBLE PRECISION NOT NULL,
    total_deductions        DOUBLE PRECISION NOT NULL,
    net_salary              DOUBLE PRECISION NOT NULL,
    
    -- Components Breakdown (JSON)
    earnings_breakdown      JSONB NOT NULL,                       -- [{"name": "Basic", "amount": 50000, ...}]
    deductions_breakdown    JSONB NOT NULL,                       -- [{"name": "PF", "amount": 1800, ...}]
    
    -- Additional Payments
    reimbursements          DOUBLE PRECISION DEFAULT 0,
    bonuses                 DOUBLE PRECISION DEFAULT 0,
    arrears                 DOUBLE PRECISION DEFAULT 0,
    leave_encashment        DOUBLE PRECISION DEFAULT 0,
    
    -- Additional Deductions
    loan_recovery           DOUBLE PRECISION DEFAULT 0,
    advance_recovery        DOUBLE PRECISION DEFAULT 0,
    other_deductions        DOUBLE PRECISION DEFAULT 0,
    
    -- LOP Details
    lop_amount              DOUBLE PRECISION DEFAULT 0,
    lop_calculation_detail  JSONB NULL,
    
    -- Overtime Details
    ot_amount               DOUBLE PRECISION DEFAULT 0,
    ot_calculation_detail   JSONB NULL,
    
    -- Statutory
    pf_employee             DOUBLE PRECISION DEFAULT 0,
    pf_employer             DOUBLE PRECISION DEFAULT 0,
    esi_employee            DOUBLE PRECISION DEFAULT 0,
    esi_employer            DOUBLE PRECISION DEFAULT 0,
    professional_tax        DOUBLE PRECISION DEFAULT 0,
    tds                     DOUBLE PRECISION DEFAULT 0,
    
    -- YTD (Year to Date) - for tax calculations
    ytd_gross               DOUBLE PRECISION DEFAULT 0,
    ytd_tds                 DOUBLE PRECISION DEFAULT 0,
    
    -- Status
    status                  VARCHAR(30) DEFAULT 'draft',          -- 'draft', 'calculated', 'approved', 'paid', 'hold'
    hold_reason             TEXT NULL,
    
    -- Payment
    payment_mode            VARCHAR(30) NULL,                     -- 'bank_transfer', 'cheque', 'cash'
    payment_date            DATE NULL,
    payment_reference       VARCHAR(100) NULL,
    
    -- Payslip
    payslip_generated       BOOLEAN DEFAULT FALSE,
    payslip_url             TEXT NULL,
    payslip_sent            BOOLEAN DEFAULT FALSE,
    payslip_sent_at         TIMESTAMP NULL,
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(payroll_run_id, employee_id)
);

CREATE INDEX IF NOT EXISTS idx_payroll_trans_run ON payroll_transactions(payroll_run_id);
CREATE INDEX IF NOT EXISTS idx_payroll_trans_employee ON payroll_transactions(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_trans_period ON payroll_transactions(month, year);
CREATE INDEX IF NOT EXISTS idx_payroll_trans_status ON payroll_transactions(status);

-- ============================================================================
-- 6. PAYROLL ARREARS (Salary revision arrears)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_arrears (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Arrear Period
    arrear_type             VARCHAR(50) NOT NULL,                 -- 'salary_revision', 'bonus', 'allowance_change'
    effective_from          DATE NOT NULL,
    effective_to            DATE NOT NULL,
    calculated_on           DATE NOT NULL,
    
    -- Amount Details
    component_name          VARCHAR(255) NOT NULL,
    old_amount              DOUBLE PRECISION NOT NULL,
    new_amount              DOUBLE PRECISION NOT NULL,
    difference_amount       DOUBLE PRECISION NOT NULL,
    number_of_months        INTEGER NOT NULL,
    total_arrear_amount     DOUBLE PRECISION NOT NULL,
    
    -- Payment
    status                  VARCHAR(30) DEFAULT 'pending',        -- 'pending', 'partial', 'paid'
    payment_method          VARCHAR(30) DEFAULT 'lump_sum',       -- 'lump_sum', 'installments'
    installments_count      INTEGER NULL,
    paid_amount             DOUBLE PRECISION DEFAULT 0,
    remaining_amount        DOUBLE PRECISION NULL,
    
    -- Link to payroll runs where paid
    paid_in_payroll_runs    JSONB NULL,                           -- [{"run_id": 123, "amount": 5000}]
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_arrears_employee ON payroll_arrears(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_arrears_status ON payroll_arrears(status);

-- ============================================================================
-- 7. PAYROLL HOLD/FREEZE (Salary hold scenarios)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_holds (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Hold Details
    hold_type               VARCHAR(50) NOT NULL,                 -- 'disciplinary', 'notice_period', 'legal', 'absconding'
    hold_percentage         DOUBLE PRECISION NULL,                -- Percentage to hold (e.g., 50%)
    hold_amount             DOUBLE PRECISION NULL,                -- Fixed amount to hold
    
    -- Period
    hold_from               DATE NOT NULL,
    hold_to                 DATE NULL,                            -- NULL = indefinite
    is_active               BOOLEAN DEFAULT TRUE,
    
    -- Approval
    reason                  TEXT NOT NULL,
    initiated_by            VARCHAR(24) NULL,
    approved_by             VARCHAR(24) NULL,
    approved_at             TIMESTAMP NULL,
    
    -- Release
    released_by             VARCHAR(24) NULL,
    released_at             TIMESTAMP NULL,
    release_reason          TEXT NULL,
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_holds_employee ON payroll_holds(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_holds_active ON payroll_holds(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- 8. LOAN INSTALLMENTS TRACKING (Link to payroll)
-- ============================================================================
CREATE TABLE IF NOT EXISTS loan_installments (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    loan_id                 VARCHAR(24) NOT NULL,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    
    -- Installment Details
    installment_number      INTEGER NOT NULL,
    due_date                DATE NOT NULL,
    installment_amount      DOUBLE PRECISION NOT NULL,
    principal_amount        DOUBLE PRECISION DEFAULT 0,
    interest_amount         DOUBLE PRECISION DEFAULT 0,
    
    -- Payment
    status                  VARCHAR(30) DEFAULT 'pending',        -- 'pending', 'deducted', 'skipped'
    paid_date               DATE NULL,
    paid_amount             DOUBLE PRECISION NULL,
    payroll_transaction_id  BIGINT NULL,                          -- Link to payroll where deducted
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loan_installments_loan ON loan_installments(loan_id);
CREATE INDEX IF NOT EXISTS idx_loan_installments_employee ON loan_installments(employee_id);
CREATE INDEX IF NOT EXISTS idx_loan_installments_status ON loan_installments(status);

-- ============================================================================
-- 9. TAX DECLARATIONS (Employee tax saving declarations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tax_declarations (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id             VARCHAR(24) NOT NULL,
    company_id              VARCHAR(24) NOT NULL,
    financial_year          VARCHAR(10) NOT NULL,                 -- '2024-25'
    
    -- Regime Selection
    tax_regime              VARCHAR(20) DEFAULT 'old',            -- 'old', 'new'
    
    -- Section 80C Investments (max 1.5L)
    section_80c             JSONB NULL,                           -- {"ppf": 50000, "elss": 30000, ...}
    section_80c_total       DOUBLE PRECISION DEFAULT 0,
    
    -- Section 80D Health Insurance
    section_80d_self        DOUBLE PRECISION DEFAULT 0,           -- Max 25K
    section_80d_parents     DOUBLE PRECISION DEFAULT 0,           -- Max 50K
    
    -- HRA Details
    hra_exemption_details   JSONB NULL,                           -- Rent paid, metro city, etc.
    
    -- Other Exemptions
    section_80g             DOUBLE PRECISION DEFAULT 0,           -- Donations
    section_24              DOUBLE PRECISION DEFAULT 0,           -- Home loan interest
    lta_claimed             DOUBLE PRECISION DEFAULT 0,
    standard_deduction      DOUBLE PRECISION DEFAULT 50000,
    
    -- Total
    total_exemptions        DOUBLE PRECISION DEFAULT 0,
    
    -- Proof Upload
    proof_documents         JSONB NULL,                           -- URLs to uploaded proofs
    
    -- Status
    status                  VARCHAR(30) DEFAULT 'draft',          -- 'draft', 'submitted', 'verified', 'rejected'
    submitted_at            TIMESTAMP NULL,
    verified_by             VARCHAR(24) NULL,
    verified_at             TIMESTAMP NULL,
    rejection_reason        TEXT NULL,
    
    remarks                 TEXT NULL,
    created_at              TIMESTAMP DEFAULT NOW(),
    updated_at              TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(employee_id, financial_year)
);

CREATE INDEX IF NOT EXISTS idx_tax_declarations_employee ON tax_declarations(employee_id);
CREATE INDEX IF NOT EXISTS idx_tax_declarations_fy ON tax_declarations(financial_year);

-- ============================================================================
-- 10. PAYROLL AUDIT LOG (Track all payroll changes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS payroll_audit_log (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              VARCHAR(24) NOT NULL,
    entity_type             VARCHAR(50) NOT NULL,                 -- 'payroll_run', 'transaction', 'salary_structure'
    entity_id               VARCHAR(24) NOT NULL,
    action                  VARCHAR(50) NOT NULL,                 -- 'created', 'updated', 'deleted', 'approved', 'paid'
    changed_by              VARCHAR(24) NULL,
    changes                 JSONB NULL,                           -- Before/after values
    ip_address              VARCHAR(45) NULL,
    created_at              TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payroll_audit_entity ON payroll_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_payroll_audit_date ON payroll_audit_log(created_at);

-- ============================================================================
-- MIGRATION: Update existing staff table to link with new payroll system
-- ============================================================================
-- Add new columns to staff table if they don't exist
DO $$
BEGIN
    -- Salary cycle
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'salary_cycle') THEN
        ALTER TABLE staff ADD COLUMN salary_cycle VARCHAR(30) DEFAULT 'monthly';
    END IF;
    
    -- Gross and Net salary (if not already exists)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'gross_salary') THEN
        ALTER TABLE staff ADD COLUMN gross_salary DOUBLE PRECISION NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'net_salary') THEN
        ALTER TABLE staff ADD COLUMN net_salary DOUBLE PRECISION NULL;
    END IF;
    
    -- Staff type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'staff_type') THEN
        ALTER TABLE staff ADD COLUMN staff_type VARCHAR(50) NULL;
    END IF;
    
    -- Reporting manager
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'reporting_manager') THEN
        ALTER TABLE staff ADD COLUMN reporting_manager VARCHAR(255) NULL;
    END IF;
    
    -- Address fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'address_postal_code') THEN
        ALTER TABLE staff ADD COLUMN address_postal_code VARCHAR(20) NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'address_country') THEN
        ALTER TABLE staff ADD COLUMN address_country VARCHAR(100) NULL;
    END IF;
    
    -- Bank verification status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'bank_verification_status') THEN
        ALTER TABLE staff ADD COLUMN bank_verification_status VARCHAR(50) DEFAULT 'Pending';
    END IF;
    
    -- Current salary structure link
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'staff' AND column_name = 'current_salary_structure_id') THEN
        ALTER TABLE staff ADD COLUMN current_salary_structure_id BIGINT NULL;
    END IF;
END $$;

-- ============================================================================
-- SEED DATA: Default Salary Components (Run per company)
-- ============================================================================
-- This will be inserted programmatically via API/script
-- Examples included here for reference

-- Default Earnings Components:
-- 1. Basic Salary (50% of gross)
-- 2. House Rent Allowance (40% of basic)
-- 3. Special Allowance
-- 4. Transport Allowance (Fixed 1600)
-- 5. Medical Allowance (Fixed 1250)
-- 6. Dearness Allowance (% of basic)

-- Default Deduction Components:
-- 1. Provident Fund (12% of basic, statutory)
-- 2. Employee State Insurance (0.75% of gross, statutory)
-- 3. Professional Tax (Slab-based, statutory)
-- 4. TDS/Income Tax (Calculated, statutory)
-- 5. Loan Recovery (If applicable)

-- ============================================================================
-- PERFORMANCE INDEXES
-- ============================================================================
-- Additional indexes for query optimization
CREATE INDEX IF NOT EXISTS idx_payroll_trans_employee_period ON payroll_transactions(employee_id, month, year);
CREATE INDEX IF NOT EXISTS idx_emp_salary_structure_employee_current ON employee_salary_structures(employee_id, is_current) WHERE is_current = TRUE;

-- ============================================================================
-- END OF PAYROLL SCHEMA
-- ============================================================================
