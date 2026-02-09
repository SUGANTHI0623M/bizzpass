-- PostgreSQL schema for BizzPass (converted from MongoDB, no foreign keys, all columns nullable except primary key)
-- Run this script to create all tables. ObjectId refs stored as VARCHAR(24).
-- mongo_id: store original MongoDB _id when migrating so refs (company_id, etc.) can resolve without code change.
--
-- Tables: users, staff, companies, company_business_settings, company_attendance_settings, branches, roles,
--         asset_types, assets, attendance_templates, attendances, candidates, document_requirements, expenses,
--         holiday_templates, job_openings, leave_templates, leaves, loans, onboardings, payrolls, payslip_requests, reimbursements.

-- 1. users (from User model)
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    mongo_id        VARCHAR(24) NULL UNIQUE,
    name            VARCHAR(255) NULL,
    email           VARCHAR(255) NULL,
    password        VARCHAR(255) NULL,
    role            VARCHAR(100) NULL,
    phone           VARCHAR(50) NULL,
    company_id      VARCHAR(24) NULL,
    role_id         VARCHAR(24) NULL,
    branch_id       VARCHAR(24) NULL,
    hierarchy_level INTEGER NULL,
    is_active       BOOLEAN NULL,
    last_login      TIMESTAMP NULL,
    reset_password_otp       VARCHAR(50) NULL,
    reset_password_otp_expiry TIMESTAMP NULL,
    avatar          TEXT NULL,
    office_location_latitude  DOUBLE PRECISION NULL,
    office_location_longitude DOUBLE PRECISION NULL,
    office_location_address   TEXT NULL,
    office_location_radius    DOUBLE PRECISION NULL,
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL
);

-- 2. staff (from Staff model)
CREATE TABLE staff (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id              VARCHAR(100) NULL,
    user_id                  VARCHAR(24) NULL,
    business_id              VARCHAR(24) NULL,
    branch_id                VARCHAR(24) NULL,
    name                     VARCHAR(255) NULL,
    email                    VARCHAR(255) NULL,
    password                 VARCHAR(255) NULL,
    phone                    VARCHAR(50) NULL,
    designation              VARCHAR(255) NULL,
    department               VARCHAR(255) NULL,
    shift_name               VARCHAR(100) NULL,
    attendance_template_id   VARCHAR(24) NULL,
    leave_template_id        VARCHAR(24) NULL,
    holiday_template_id      VARCHAR(24) NULL,
    status                   VARCHAR(50) NULL,
    joining_date             DATE NULL,
    avatar                   TEXT NULL,
    gender                   VARCHAR(50) NULL,
    marital_status           VARCHAR(50) NULL,
    dob                      DATE NULL,
    blood_group              VARCHAR(20) NULL,
    address_line1            TEXT NULL,
    address_city             VARCHAR(100) NULL,
    address_state            VARCHAR(100) NULL,
    uan                      VARCHAR(50) NULL,
    pan                      VARCHAR(50) NULL,
    aadhaar                  VARCHAR(50) NULL,
    pf_number                VARCHAR(50) NULL,
    esi_number               VARCHAR(50) NULL,
    bank_name                VARCHAR(255) NULL,
    account_number           VARCHAR(100) NULL,
    ifsc_code                VARCHAR(50) NULL,
    account_holder_name      VARCHAR(255) NULL,
    upi_id                   VARCHAR(100) NULL,
    candidate_id             VARCHAR(24) NULL,
    basic_salary             DOUBLE PRECISION NULL,
    dearness_allowance       DOUBLE PRECISION NULL,
    house_rent_allowance     DOUBLE PRECISION NULL,
    special_allowance        DOUBLE PRECISION NULL,
    employer_pf_rate         DOUBLE PRECISION NULL,
    employer_esi_rate        DOUBLE PRECISION NULL,
    incentive_rate           DOUBLE PRECISION NULL,
    gratuity_rate            DOUBLE PRECISION NULL,
    statutory_bonus_rate     DOUBLE PRECISION NULL,
    medical_insurance_amount DOUBLE PRECISION NULL,
    mobile_allowance        DOUBLE PRECISION NULL,
    mobile_allowance_type    VARCHAR(20) NULL,
    employee_pf_rate        DOUBLE PRECISION NULL,
    employee_esi_rate        DOUBLE PRECISION NULL,
    created_at               TIMESTAMP NULL,
    updated_at               TIMESTAMP NULL
);

-- 3. companies (from Company model) - settings as JSONB for nested/arrays
CREATE TABLE companies (
    id                BIGSERIAL PRIMARY KEY,
    mongo_id          VARCHAR(24) NULL UNIQUE,
    name              VARCHAR(255) NULL,
    email             VARCHAR(255) NULL,
    phone             VARCHAR(50) NULL,
    address_street    TEXT NULL,
    address_city      VARCHAR(100) NULL,
    address_state     VARCHAR(100) NULL,
    address_zip       VARCHAR(20) NULL,
    address_country   VARCHAR(100) NULL,
    logo              TEXT NULL,
    website           VARCHAR(255) NULL,
    is_active         BOOLEAN NULL,
    subscription_plan     VARCHAR(50) NULL,
    subscription_start_date DATE NULL,
    subscription_end_date   DATE NULL,
    subscription_status    VARCHAR(50) NULL,
    settings          JSONB NULL,
    created_by        VARCHAR(24) NULL,
    created_at        TIMESTAMP NULL,
    updated_at        TIMESTAMP NULL
);

-- 3b. company_business_settings (from Company.settings.business - one row per company)
CREATE TABLE company_business_settings (
    id                              BIGSERIAL PRIMARY KEY,
    company_id                      VARCHAR(24) NULL,
    weekly_holidays                 JSONB NULL,
    weekly_off_pattern              VARCHAR(50) NULL,
    allow_attendance_on_weekly_off   BOOLEAN NULL,
    created_at                      TIMESTAMP NULL,
    updated_at                      TIMESTAMP NULL
);

-- 3c. company_attendance_settings (from Company.settings.attendance - one row per company)
CREATE TABLE company_attendance_settings (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              VARCHAR(24) NULL,
    geofence_enabled        BOOLEAN NULL,
    shifts                  JSONB NULL,
    automation_rules        JSONB NULL,
    fine_settings           JSONB NULL,
    created_at              TIMESTAMP NULL,
    updated_at              TIMESTAMP NULL
);

-- 4. branches (from Branch model)
CREATE TABLE branches (
    id                  BIGSERIAL PRIMARY KEY,
    mongo_id            VARCHAR(24) NULL UNIQUE,
    branch_name         VARCHAR(255) NULL,
    branch_code         VARCHAR(100) NULL,
    is_head_office      BOOLEAN NULL,
    business_id         VARCHAR(24) NULL,
    email               VARCHAR(255) NULL,
    contact_number      VARCHAR(50) NULL,
    country_code        VARCHAR(10) NULL,
    address_street      TEXT NULL,
    address_city        VARCHAR(100) NULL,
    address_state       VARCHAR(100) NULL,
    address_zip         VARCHAR(20) NULL,
    address_country     VARCHAR(100) NULL,
    status              VARCHAR(20) NULL,
    logo                TEXT NULL,
    geofence_enabled    BOOLEAN NULL,
    geofence_latitude   DOUBLE PRECISION NULL,
    geofence_longitude  DOUBLE PRECISION NULL,
    geofence_radius     DOUBLE PRECISION NULL,
    created_by          VARCHAR(24) NULL,
    created_at          TIMESTAMP NULL,
    updated_at          TIMESTAMP NULL
);

-- 5. roles (from Role model)
CREATE TABLE roles (
    id              BIGSERIAL PRIMARY KEY,
    mongo_id        VARCHAR(24) NULL UNIQUE,
    name            VARCHAR(255) NULL,
    company_id      VARCHAR(24) NULL,
    description     TEXT NULL,
    permissions     JSONB NULL,
    is_system_role  BOOLEAN NULL,
    is_active       BOOLEAN NULL,
    branch          VARCHAR(50) NULL,
    display_order   INTEGER NULL,
    hierarchy_level INTEGER NULL,
    created_by      VARCHAR(24) NULL,
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL
);

-- 6. asset_types (from AssetType model)
CREATE TABLE asset_types (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    name         VARCHAR(255) NULL,
    description  TEXT NULL,
    business_id  VARCHAR(24) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 7. assets (from Asset model)
CREATE TABLE assets (
    id               BIGSERIAL PRIMARY KEY,
    mongo_id         VARCHAR(24) NULL UNIQUE,
    name             VARCHAR(255) NULL,
    type             VARCHAR(100) NULL,
    asset_category   VARCHAR(100) NULL,
    serial_number    VARCHAR(255) NULL,
    asset_type_id    VARCHAR(24) NULL,
    status           VARCHAR(50) NULL,
    location         VARCHAR(255) NULL,
    assigned_to      VARCHAR(24) NULL,
    purchase_date    DATE NULL,
    purchase_price    DOUBLE PRECISION NULL,
    warranty_expiry  DATE NULL,
    asset_photo      TEXT NULL,
    image            TEXT NULL,
    notes            TEXT NULL,
    business_id      VARCHAR(24) NULL,
    branch_id        VARCHAR(24) NULL,
    created_at       TIMESTAMP NULL,
    updated_at       TIMESTAMP NULL
);

-- 8. attendance_templates (from AttendanceTemplate model)
CREATE TABLE attendance_templates (
    id                          BIGSERIAL PRIMARY KEY,
    mongo_id                    VARCHAR(24) NULL UNIQUE,
    name                        VARCHAR(255) NULL,
    description                 TEXT NULL,
    is_active                   BOOLEAN NULL,
    require_geolocation         BOOLEAN NULL,
    require_selfie              BOOLEAN NULL,
    allow_attendance_on_holidays BOOLEAN NULL,
    allow_attendance_on_weekly_off BOOLEAN NULL,
    allow_late_entry            BOOLEAN NULL,
    allow_early_exit            BOOLEAN NULL,
    allow_overtime              BOOLEAN NULL,
    shift_start_time            VARCHAR(10) NULL,
    shift_end_time              VARCHAR(10) NULL,
    grace_period_minutes        INTEGER NULL,
    business_id                 VARCHAR(24) NULL,
    created_at                  TIMESTAMP NULL,
    updated_at                  TIMESTAMP NULL
);

-- 9. attendances (from Attendance model) - location nested as JSONB
CREATE TABLE attendances (
    id                    BIGSERIAL PRIMARY KEY,
    mongo_id              VARCHAR(24) NULL UNIQUE,
    employee_id           VARCHAR(24) NULL,
    user_id               VARCHAR(24) NULL,
    date                  DATE NULL,
    punch_in              TIMESTAMP NULL,
    punch_out             TIMESTAMP NULL,
    status                VARCHAR(50) NULL,
    approved_by           VARCHAR(24) NULL,
    approved_at           TIMESTAMP NULL,
    remarks               TEXT NULL,
    work_hours            DOUBLE PRECISION NULL,
    overtime              DOUBLE PRECISION NULL,
    fine_hours            DOUBLE PRECISION NULL,
    late_minutes          INTEGER NULL,
    early_minutes         INTEGER NULL,
    fine_amount           DOUBLE PRECISION NULL,
    location              JSONB NULL,
    ip_address            VARCHAR(45) NULL,
    punch_in_ip_address   VARCHAR(45) NULL,
    punch_out_ip_address  VARCHAR(45) NULL,
    business_id           VARCHAR(24) NULL,
    punch_in_selfie       TEXT NULL,
    punch_out_selfie      TEXT NULL,
    created_at            TIMESTAMP NULL,
    updated_at            TIMESTAMP NULL
);

-- 10. candidates (from Candidate model) - education, experience, courses, internships, documents, resume as JSONB
CREATE TABLE candidates (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    first_name              VARCHAR(255) NULL,
    last_name               VARCHAR(255) NULL,
    email                   VARCHAR(255) NULL,
    phone                   VARCHAR(50) NULL,
    country_code            VARCHAR(10) NULL,
    date_of_birth           DATE NULL,
    gender                  VARCHAR(50) NULL,
    current_city            VARCHAR(100) NULL,
    preferred_job_location  VARCHAR(255) NULL,
    position                VARCHAR(255) NULL,
    primary_skill           VARCHAR(255) NULL,
    status                  VARCHAR(50) NULL,
    source                  VARCHAR(50) NULL,
    total_years_of_experience INTEGER NULL,
    current_company        VARCHAR(255) NULL,
    current_job_title       VARCHAR(255) NULL,
    employment_type         VARCHAR(50) NULL,
    education               JSONB NULL,
    experience              JSONB NULL,
    courses                 JSONB NULL,
    internships             JSONB NULL,
    documents               JSONB NULL,
    resume                  JSONB NULL,
    skills                  JSONB NULL,
    location                VARCHAR(255) NULL,
    job_id                  VARCHAR(24) NULL,
    current_job_stage       INTEGER NULL,
    completed_job_stages    JSONB NULL,
    user_id                 VARCHAR(24) NULL,
    business_id             VARCHAR(24) NULL,
    selected_on             DATE NULL,
    rejected_on             DATE NULL,
    created_at              TIMESTAMP NULL,
    updated_at              TIMESTAMP NULL
);

-- 11. document_requirements (from DocumentRequirement model)
CREATE TABLE document_requirements (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    name         VARCHAR(255) NULL,
    type         VARCHAR(50) NULL,
    required     BOOLEAN NULL,
    description  TEXT NULL,
    "order"      INTEGER NULL,
    business_id  VARCHAR(24) NULL,
    is_active    BOOLEAN NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 12. expenses (from Expense model)
CREATE TABLE expenses (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    employee_id  VARCHAR(24) NULL,
    business_id  VARCHAR(24) NULL,
    expense_type VARCHAR(100) NULL,
    amount       DOUBLE PRECISION NULL,
    date         DATE NULL,
    description  TEXT NULL,
    status       VARCHAR(50) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 13. holiday_templates (from HolidayTemplate model) - holidays, assigned_staff as JSONB
CREATE TABLE holiday_templates (
    id            BIGSERIAL PRIMARY KEY,
    mongo_id      VARCHAR(24) NULL UNIQUE,
    name          VARCHAR(255) NULL,
    description   TEXT NULL,
    holidays      JSONB NULL,
    business_id   VARCHAR(24) NULL,
    assigned_staff JSONB NULL,
    created_by    VARCHAR(24) NULL,
    is_active     BOOLEAN NULL,
    created_at    TIMESTAMP NULL,
    updated_at    TIMESTAMP NULL
);

-- 14. job_openings (from JobOpening model) - business_id optional for multi-tenant filtering
CREATE TABLE job_openings (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    title        VARCHAR(255) NULL,
    job_code     VARCHAR(100) NULL,
    department   VARCHAR(255) NULL,
    status       VARCHAR(50) NULL,
    business_id  VARCHAR(24) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 15. leave_templates (from LeaveTemplate model; strict:false - leaveTypes, limits stored at runtime)
CREATE TABLE leave_templates (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    name         VARCHAR(255) NULL,
    leave_types  JSONB NULL,
    limits       JSONB NULL,
    business_id  VARCHAR(24) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 16. leaves (from Leave model)
CREATE TABLE leaves (
    id                BIGSERIAL PRIMARY KEY,
    mongo_id          VARCHAR(24) NULL UNIQUE,
    employee_id       VARCHAR(24) NULL,
    leave_type        VARCHAR(50) NULL,
    session           VARCHAR(50) NULL,
    start_date        DATE NULL,
    end_date          DATE NULL,
    days              DOUBLE PRECISION NULL,
    reason            TEXT NULL,
    status            VARCHAR(50) NULL,
    approved_by       VARCHAR(24) NULL,
    approved_at       TIMESTAMP NULL,
    rejection_reason  TEXT NULL,
    business_id       VARCHAR(24) NULL,
    created_at        TIMESTAMP NULL,
    updated_at        TIMESTAMP NULL
);

-- 17. loans (from Loan model) - installments as JSONB
CREATE TABLE loans (
    id              BIGSERIAL PRIMARY KEY,
    mongo_id        VARCHAR(24) NULL UNIQUE,
    employee_id     VARCHAR(24) NULL,
    loan_type       VARCHAR(50) NULL,
    amount          DOUBLE PRECISION NULL,
    purpose         TEXT NULL,
    interest_rate   DOUBLE PRECISION NULL,
    tenure          INTEGER NULL,
    emi             DOUBLE PRECISION NULL,
    status          VARCHAR(50) NULL,
    approved_by     VARCHAR(24) NULL,
    approved_at     TIMESTAMP NULL,
    start_date      DATE NULL,
    end_date        DATE NULL,
    remaining_amount DOUBLE PRECISION NULL,
    installments    JSONB NULL,
    business_id     VARCHAR(24) NULL,
    created_at      TIMESTAMP NULL,
    updated_at      TIMESTAMP NULL
);

-- 18. onboardings (from Onboarding model) - documents array as JSONB
CREATE TABLE onboardings (
    id            BIGSERIAL PRIMARY KEY,
    mongo_id      VARCHAR(24) NULL UNIQUE,
    staff_id      VARCHAR(24) NULL,
    candidate_id  VARCHAR(24) NULL,
    status        VARCHAR(50) NULL,
    documents     JSONB NULL,
    progress      INTEGER NULL,
    started_at    TIMESTAMP NULL,
    completed_at  TIMESTAMP NULL,
    business_id   VARCHAR(24) NULL,
    created_by    VARCHAR(24) NULL,
    created_at    TIMESTAMP NULL,
    updated_at    TIMESTAMP NULL
);

-- 19. payrolls (from Payroll model) - components as JSONB
CREATE TABLE payrolls (
    id             BIGSERIAL PRIMARY KEY,
    mongo_id       VARCHAR(24) NULL UNIQUE,
    employee_id    VARCHAR(24) NULL,
    month          INTEGER NULL,
    year           INTEGER NULL,
    gross_salary   DOUBLE PRECISION NULL,
    deductions     DOUBLE PRECISION NULL,
    net_pay        DOUBLE PRECISION NULL,
    components     JSONB NULL,
    status         VARCHAR(50) NULL,
    processed_at   TIMESTAMP NULL,
    paid_at        TIMESTAMP NULL,
    payslip_url    TEXT NULL,
    business_id    VARCHAR(24) NULL,
    created_at     TIMESTAMP NULL,
    updated_at     TIMESTAMP NULL
);

-- 20. payslip_requests (from PayslipRequest model)
CREATE TABLE payslip_requests (
    id             BIGSERIAL PRIMARY KEY,
    mongo_id       VARCHAR(24) NULL UNIQUE,
    employee_id    VARCHAR(24) NULL,
    business_id    VARCHAR(24) NULL,
    month          INTEGER NULL,
    year           INTEGER NULL,
    reason         TEXT NULL,
    status         VARCHAR(50) NULL,
    approved_by    VARCHAR(24) NULL,
    rejected_by    VARCHAR(24) NULL,
    action_reason  TEXT NULL,
    payroll_id     VARCHAR(24) NULL,
    approved_at    TIMESTAMP NULL,
    created_at     TIMESTAMP NULL,
    updated_at     TIMESTAMP NULL
);

-- 21. reimbursements (from Reimbursement model) - proof_files as JSONB
CREATE TABLE reimbursements (
    id                   BIGSERIAL PRIMARY KEY,
    mongo_id             VARCHAR(24) NULL UNIQUE,
    employee_id          VARCHAR(24) NULL,
    type                 VARCHAR(50) NULL,
    amount               DOUBLE PRECISION NULL,
    description          TEXT NULL,
    date                 DATE NULL,
    receipt              TEXT NULL,
    proof_files          JSONB NULL,
    status               VARCHAR(50) NULL,
    approved_by          VARCHAR(24) NULL,
    approved_at          TIMESTAMP NULL,
    rejection_reason     TEXT NULL,
    paid_at              TIMESTAMP NULL,
    processed_in_payroll VARCHAR(24) NULL,
    processed_at         TIMESTAMP NULL,
    business_id          VARCHAR(24) NULL,
    created_at           TIMESTAMP NULL,
    updated_at           TIMESTAMP NULL
);

-- Optional: indexes for faster lookups by ref columns and mongo_id (no FKs, just performance)
-- Uncomment as needed after creating tables.
/*
CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_staff_business_id ON staff(business_id);
CREATE INDEX idx_staff_user_id ON staff(user_id);
CREATE INDEX idx_staff_email ON staff(email);
CREATE INDEX idx_company_business_settings_company_id ON company_business_settings(company_id);
CREATE INDEX idx_company_attendance_settings_company_id ON company_attendance_settings(company_id);
CREATE INDEX idx_attendances_employee_date ON attendances(employee_id, date);
CREATE INDEX idx_attendances_business_id ON attendances(business_id);
CREATE INDEX idx_leaves_employee_id ON leaves(employee_id);
CREATE INDEX idx_leaves_business_id ON leaves(business_id);
CREATE INDEX idx_leave_templates_business_id ON leave_templates(business_id);
CREATE INDEX idx_payrolls_employee_month_year ON payrolls(employee_id, month, year);
CREATE INDEX idx_candidates_business_id ON candidates(business_id);
CREATE INDEX idx_candidates_job_id ON candidates(job_id);
*/

-- ============================================================================
-- BizzPass Phase 1 — Missing Tables
-- Run AFTER postgres_schema.sql (existing HRMS tables)
-- ============================================================================

-- ============================================================================
-- 1. SUBSCRIPTION PLANS (master table for all available plans)
-- ============================================================================
CREATE TABLE subscription_plans (
    id                  BIGSERIAL PRIMARY KEY,
    plan_code           VARCHAR(50)    NOT NULL UNIQUE,       -- e.g. 'starter', 'pro', 'enterprise'
    plan_name           VARCHAR(255)   NOT NULL,
    description         TEXT           NULL,
    price               DECIMAL(12,2)  NOT NULL,              -- base price in INR
    currency            VARCHAR(10)    NOT NULL DEFAULT 'INR',
    duration_months     INTEGER        NOT NULL,              -- 1, 3, 6, 12
    max_users           INTEGER        NOT NULL,              -- user cap for this plan
    max_branches        INTEGER        NULL,                  -- branch cap (NULL = unlimited)
    features            JSONB          NULL,                   -- {"attendance":true,"vms":true,"payroll":false}
    is_active           BOOLEAN        NOT NULL DEFAULT TRUE,
    trial_days          INTEGER        NULL DEFAULT 0,        -- free trial period
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscription_plans_active ON subscription_plans(is_active) WHERE is_active = TRUE;


-- ============================================================================
-- 2. LICENSES (core licensing system — Super Admin creates these)
-- ============================================================================
CREATE TABLE licenses (
    id                  BIGSERIAL PRIMARY KEY,
    license_key         VARCHAR(64)    NOT NULL UNIQUE,       -- UUID or custom key
    company_id          BIGINT         NULL,                  -- NULL until a company registers with this key
    plan_id             BIGINT         NOT NULL REFERENCES subscription_plans(id),
    max_users           INTEGER        NOT NULL,
    max_branches        INTEGER        NULL,
    status              VARCHAR(30)    NOT NULL DEFAULT 'unassigned',
                                                              -- unassigned / active / expired / suspended / revoked
    valid_from          DATE           NULL,                  -- set when company activates
    valid_until         DATE           NULL,                  -- set on activation / renewal
    is_trial            BOOLEAN        NOT NULL DEFAULT FALSE,
    activated_at        TIMESTAMP      NULL,
    suspended_at        TIMESTAMP      NULL,
    revoked_at          TIMESTAMP      NULL,
    suspension_reason   TEXT           NULL,
    created_by          BIGINT         NOT NULL,              -- super_admin user id
    notes               TEXT           NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_licenses_license_key  ON licenses(license_key);
CREATE INDEX idx_licenses_company_id   ON licenses(company_id);
CREATE INDEX idx_licenses_status       ON licenses(status);
CREATE INDEX idx_licenses_valid_until  ON licenses(valid_until);


-- ============================================================================
-- 3. PAYMENTS (Razorpay / Stripe transactions)
-- ============================================================================
CREATE TABLE payments (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              BIGINT         NOT NULL,
    license_id              BIGINT         NOT NULL REFERENCES licenses(id),
    plan_id                 BIGINT         NOT NULL REFERENCES subscription_plans(id),

    -- Razorpay-specific fields
    razorpay_order_id       VARCHAR(255)   NULL,
    razorpay_payment_id     VARCHAR(255)   NULL UNIQUE,
    razorpay_signature      VARCHAR(512)   NULL,

    -- Stripe-specific fields (if you add Stripe later)
    stripe_payment_intent_id VARCHAR(255)  NULL UNIQUE,
    stripe_checkout_session_id VARCHAR(255) NULL,

    -- Common payment fields
    gateway                 VARCHAR(30)    NOT NULL DEFAULT 'razorpay',  -- razorpay / stripe
    amount                  DECIMAL(12,2)  NOT NULL,
    tax_amount              DECIMAL(12,2)  NOT NULL DEFAULT 0,           -- GST
    total_amount            DECIMAL(12,2)  NOT NULL,
    currency                VARCHAR(10)    NOT NULL DEFAULT 'INR',
    status                  VARCHAR(30)    NOT NULL DEFAULT 'created',
                                                              -- created / authorized / captured / failed / refunded
    payment_method          VARCHAR(50)    NULL,               -- upi / card / netbanking / wallet
    failure_reason          TEXT           NULL,
    refund_id               VARCHAR(255)   NULL,
    refund_amount           DECIMAL(12,2)  NULL,
    refunded_at             TIMESTAMP      NULL,

    paid_at                 TIMESTAMP      NULL,
    initiated_by            BIGINT         NULL,               -- user who initiated payment
    metadata                JSONB          NULL,               -- any extra gateway response data
    created_at              TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_company_id          ON payments(company_id);
CREATE INDEX idx_payments_license_id          ON payments(license_id);
CREATE INDEX idx_payments_razorpay_order_id   ON payments(razorpay_order_id);
CREATE INDEX idx_payments_status              ON payments(status);


-- ============================================================================
-- 4. INVOICES (generated after successful payment)
-- ============================================================================
CREATE TABLE invoices (
    id                  BIGSERIAL PRIMARY KEY,
    invoice_number      VARCHAR(50)    NOT NULL UNIQUE,       -- e.g. BP-INV-2025-00001
    company_id          BIGINT         NOT NULL,
    payment_id          BIGINT         NOT NULL REFERENCES payments(id),
    license_id          BIGINT         NOT NULL REFERENCES licenses(id),

    -- Billing details (snapshot at time of invoice)
    billing_name        VARCHAR(255)   NOT NULL,
    billing_email       VARCHAR(255)   NULL,
    billing_address     TEXT           NULL,
    billing_gst_number  VARCHAR(20)    NULL,                  -- GSTIN for Indian invoicing
    billing_pan         VARCHAR(20)    NULL,

    -- Amounts
    subtotal            DECIMAL(12,2)  NOT NULL,
    cgst_amount         DECIMAL(12,2)  NOT NULL DEFAULT 0,
    sgst_amount         DECIMAL(12,2)  NOT NULL DEFAULT 0,
    igst_amount         DECIMAL(12,2)  NOT NULL DEFAULT 0,
    total_amount        DECIMAL(12,2)  NOT NULL,

    -- Plan details (snapshot)
    plan_name           VARCHAR(255)   NULL,
    plan_duration_months INTEGER       NULL,
    period_start        DATE           NULL,
    period_end          DATE           NULL,

    -- PDF
    pdf_url             TEXT           NULL,                   -- S3/GCS URL of generated PDF
    pdf_generated_at    TIMESTAMP      NULL,

    status              VARCHAR(30)    NOT NULL DEFAULT 'generated',
                                                              -- generated / sent / void
    sent_at             TIMESTAMP      NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invoices_company_id     ON invoices(company_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);


-- ============================================================================
-- 5. OTP AUTHENTICATION (login, verification, password reset)
-- ============================================================================
CREATE TABLE otps (
    id                  BIGSERIAL PRIMARY KEY,
    identifier          VARCHAR(255)   NOT NULL,              -- phone number or email
    identifier_type     VARCHAR(20)    NOT NULL DEFAULT 'phone', -- phone / email
    otp_code            VARCHAR(10)    NOT NULL,
    purpose             VARCHAR(30)    NOT NULL,              -- login / verify_phone / verify_email / reset_password
    attempts            INTEGER        NOT NULL DEFAULT 0,
    max_attempts        INTEGER        NOT NULL DEFAULT 5,
    is_verified         BOOLEAN        NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMP      NULL,
    expires_at          TIMESTAMP      NOT NULL,
    ip_address          VARCHAR(45)    NULL,
    user_agent          TEXT           NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_otps_identifier_purpose ON otps(identifier, purpose);
CREATE INDEX idx_otps_expires_at         ON otps(expires_at);

-- Cleanup: auto-delete expired OTPs (run via cron or pg_cron)
-- DELETE FROM otps WHERE expires_at < NOW() - INTERVAL '24 hours';


-- ============================================================================
-- 6. VISITORS (Visitor Management System — VMS)
-- ============================================================================
CREATE TABLE visitors (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          BIGINT         NOT NULL,
    branch_id           BIGINT         NULL,

    -- Visitor info
    visitor_name        VARCHAR(255)   NOT NULL,
    visitor_phone       VARCHAR(50)    NULL,
    visitor_email       VARCHAR(255)   NULL,
    visitor_company     VARCHAR(255)   NULL,                  -- visitor's organization
    visitor_designation VARCHAR(255)   NULL,
    id_proof_type       VARCHAR(50)    NULL,                  -- aadhaar / pan / driving_license / passport
    id_proof_number     VARCHAR(100)   NULL,
    visitor_photo       TEXT           NULL,                   -- selfie/photo URL
    visitor_count       INTEGER        NOT NULL DEFAULT 1,    -- group visits

    -- Visit details
    purpose             VARCHAR(255)   NULL,
    purpose_description TEXT           NULL,
    host_employee_id    BIGINT         NULL,                  -- who they're visiting
    host_name           VARCHAR(255)   NULL,                  -- denormalized for quick display
    host_department     VARCHAR(255)   NULL,

    -- Timing
    expected_check_in   TIMESTAMP      NULL,
    check_in            TIMESTAMP      NULL,
    check_out           TIMESTAMP      NULL,

    -- Approval
    status              VARCHAR(30)    NOT NULL DEFAULT 'expected',
                                                              -- expected / checked_in / checked_out / cancelled / rejected
    approved_by         BIGINT         NULL,
    approval_status     VARCHAR(30)    NULL DEFAULT 'pending',-- pending / approved / rejected
    rejection_reason    TEXT           NULL,

    -- Badges / passes
    badge_number        VARCHAR(50)    NULL,
    pass_type           VARCHAR(30)    NULL,                  -- single_day / multi_day / recurring

    -- Pre-registration
    is_pre_registered   BOOLEAN        NOT NULL DEFAULT FALSE,
    pre_registered_by   BIGINT         NULL,                  -- employee who pre-registered
    invite_sent         BOOLEAN        NOT NULL DEFAULT FALSE,

    notes               TEXT           NULL,
    metadata            JSONB          NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_visitors_company_id    ON visitors(company_id);
CREATE INDEX idx_visitors_branch_id     ON visitors(branch_id);
CREATE INDEX idx_visitors_status        ON visitors(status);
CREATE INDEX idx_visitors_check_in      ON visitors(check_in);
CREATE INDEX idx_visitors_host          ON visitors(host_employee_id);


-- ============================================================================
-- 7. NOTIFICATIONS (expiry reminders, payment confirmations, etc.)
-- ============================================================================
CREATE TABLE notifications (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          BIGINT         NULL,
    user_id             BIGINT         NULL,                  -- target user (NULL for company-level)
    license_id          BIGINT         NULL,

    -- Notification details
    type                VARCHAR(50)    NOT NULL,              -- license_expiry_reminder / payment_confirmation
                                                              -- payment_failed / license_activated / license_suspended
                                                              -- visitor_arrival / visitor_pre_register
    title               VARCHAR(255)   NOT NULL,
    message             TEXT           NOT NULL,
    channel             VARCHAR(20)    NOT NULL,              -- email / sms / whatsapp / in_app / push
    priority            VARCHAR(20)    NOT NULL DEFAULT 'normal', -- low / normal / high / urgent

    -- Delivery tracking
    status              VARCHAR(30)    NOT NULL DEFAULT 'pending',
                                                              -- pending / sent / delivered / failed / read
    sent_at             TIMESTAMP      NULL,
    delivered_at        TIMESTAMP      NULL,
    read_at             TIMESTAMP      NULL,
    failed_at           TIMESTAMP      NULL,
    failure_reason      TEXT           NULL,
    retry_count         INTEGER        NOT NULL DEFAULT 0,
    max_retries         INTEGER        NOT NULL DEFAULT 3,

    -- References
    reference_type      VARCHAR(50)    NULL,                  -- payment / invoice / visitor / license
    reference_id        BIGINT         NULL,                  -- ID of the related entity

    -- Email-specific
    email_to            VARCHAR(255)   NULL,
    email_subject       VARCHAR(500)   NULL,
    email_body          TEXT           NULL,
    email_provider_id   VARCHAR(255)   NULL,                  -- SES message ID / SendGrid ID

    metadata            JSONB          NULL,
    scheduled_at        TIMESTAMP      NULL,                  -- for scheduled reminders
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_company_id ON notifications(company_id);
CREATE INDEX idx_notifications_user_id    ON notifications(user_id);
CREATE INDEX idx_notifications_type       ON notifications(type);
CREATE INDEX idx_notifications_status     ON notifications(status);
CREATE INDEX idx_notifications_scheduled  ON notifications(scheduled_at) WHERE status = 'pending';


-- ============================================================================
-- 8. LICENSE AUDIT LOG (track all license state changes)
-- ============================================================================
CREATE TABLE license_audit_logs (
    id                  BIGSERIAL PRIMARY KEY,
    license_id          BIGINT         NOT NULL REFERENCES licenses(id),
    company_id          BIGINT         NULL,
    action              VARCHAR(50)    NOT NULL,              -- created / activated / renewed / expired / suspended / revoked / plan_changed
    previous_status     VARCHAR(30)    NULL,
    new_status          VARCHAR(30)    NULL,
    previous_valid_until DATE          NULL,
    new_valid_until     DATE           NULL,
    performed_by        BIGINT         NOT NULL,              -- user who made the change
    reason              TEXT           NULL,
    metadata            JSONB          NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_license_audit_license_id ON license_audit_logs(license_id);
CREATE INDEX idx_license_audit_company_id ON license_audit_logs(company_id);


-- ============================================================================
-- 9. ALTER EXISTING TABLES (add missing columns for Phase 1)
-- ============================================================================

-- Add license reference + billing fields to companies
ALTER TABLE companies
    ADD COLUMN IF NOT EXISTS license_id          BIGINT NULL,
    ADD COLUMN IF NOT EXISTS db_name             VARCHAR(64) NULL,  -- per-company DB e.g. bizzpass_c_123
    ADD COLUMN IF NOT EXISTS gst_number          VARCHAR(20) NULL,
    ADD COLUMN IF NOT EXISTS pan_number          VARCHAR(20) NULL,
    ADD COLUMN IF NOT EXISTS billing_email       VARCHAR(255) NULL,
    ADD COLUMN IF NOT EXISTS billing_address     TEXT NULL,
    ADD COLUMN IF NOT EXISTS max_users_allowed   INTEGER NULL,
    ADD COLUMN IF NOT EXISTS registered_via      VARCHAR(50) NULL DEFAULT 'license_key';
                                                              -- license_key / invite / admin_created

-- Add super_admin flag to users (or rely on role = 'super_admin')
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_super_admin      BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS login_otp           VARCHAR(10) NULL,
    ADD COLUMN IF NOT EXISTS login_otp_expiry    TIMESTAMP NULL,
    ADD COLUMN IF NOT EXISTS phone_verified      BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS email_verified      BOOLEAN NOT NULL DEFAULT FALSE;


-- ============================================================================
-- 10. UNCOMMENT & ADD CRITICAL INDEXES FROM ORIGINAL SCHEMA
-- ============================================================================

-- These were commented out in the original file — they're essential for production
CREATE INDEX IF NOT EXISTS idx_users_company_id                    ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_email                         ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone                         ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_is_super_admin                ON users(is_super_admin) WHERE is_super_admin = TRUE;
CREATE INDEX IF NOT EXISTS idx_staff_business_id                   ON staff(business_id);
CREATE INDEX IF NOT EXISTS idx_staff_user_id                       ON staff(user_id);
CREATE INDEX IF NOT EXISTS idx_staff_email                         ON staff(email);
CREATE INDEX IF NOT EXISTS idx_company_business_settings_company   ON company_business_settings(company_id);
CREATE INDEX IF NOT EXISTS idx_company_attendance_settings_company ON company_attendance_settings(company_id);
CREATE INDEX IF NOT EXISTS idx_attendances_employee_date           ON attendances(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_attendances_business_id             ON attendances(business_id);
CREATE INDEX IF NOT EXISTS idx_leaves_employee_id                  ON leaves(employee_id);
CREATE INDEX IF NOT EXISTS idx_leaves_business_id                  ON leaves(business_id);
CREATE INDEX IF NOT EXISTS idx_leave_templates_business_id         ON leave_templates(business_id);
CREATE INDEX IF NOT EXISTS idx_payrolls_employee_month_year        ON payrolls(employee_id, month, year);
CREATE INDEX IF NOT EXISTS idx_candidates_business_id              ON candidates(business_id);
CREATE INDEX IF NOT EXISTS idx_candidates_job_id                   ON candidates(job_id);
CREATE INDEX IF NOT EXISTS idx_companies_license_id                ON companies(license_id);
