-- Tenant (per-company) database schema.
-- Run this on each new company database (e.g. bizzpass_c_123).
-- All tables use IF NOT EXISTS so it is safe to run multiple times.

-- 1. users (company-level users)
CREATE TABLE IF NOT EXISTS users (
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

-- 2. staff
CREATE TABLE IF NOT EXISTS staff (
    id                      BIGSERIAL PRIMARY KEY,
    mongo_id                VARCHAR(24) NULL UNIQUE,
    employee_id             VARCHAR(100) NULL,
    user_id                 VARCHAR(24) NULL,
    business_id             VARCHAR(24) NULL,
    branch_id               VARCHAR(24) NULL,
    name                    VARCHAR(255) NULL,
    email                   VARCHAR(255) NULL,
    password                VARCHAR(255) NULL,
    phone                   VARCHAR(50) NULL,
    designation             VARCHAR(255) NULL,
    department              VARCHAR(255) NULL,
    shift_name              VARCHAR(100) NULL,
    attendance_template_id   VARCHAR(24) NULL,
    leave_template_id        VARCHAR(24) NULL,
    holiday_template_id      VARCHAR(24) NULL,
    status                  VARCHAR(50) NULL,
    joining_date            DATE NULL,
    avatar                  TEXT NULL,
    gender                  VARCHAR(50) NULL,
    marital_status          VARCHAR(50) NULL,
    dob                     DATE NULL,
    blood_group             VARCHAR(20) NULL,
    address_line1           TEXT NULL,
    address_city            VARCHAR(100) NULL,
    address_state           VARCHAR(100) NULL,
    uan                     VARCHAR(50) NULL,
    pan                     VARCHAR(50) NULL,
    aadhaar                 VARCHAR(50) NULL,
    pf_number               VARCHAR(50) NULL,
    esi_number               VARCHAR(50) NULL,
    bank_name               VARCHAR(255) NULL,
    account_number          VARCHAR(100) NULL,
    ifsc_code               VARCHAR(50) NULL,
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
    mobile_allowance         DOUBLE PRECISION NULL,
    mobile_allowance_type    VARCHAR(20) NULL,
    employee_pf_rate         DOUBLE PRECISION NULL,
    employee_esi_rate        DOUBLE PRECISION NULL,
    created_at               TIMESTAMP NULL,
    updated_at               TIMESTAMP NULL
);

-- 3b. company_business_settings
CREATE TABLE IF NOT EXISTS company_business_settings (
    id                              BIGSERIAL PRIMARY KEY,
    company_id                      VARCHAR(24) NULL,
    weekly_holidays                  JSONB NULL,
    weekly_off_pattern              VARCHAR(50) NULL,
    allow_attendance_on_weekly_off   BOOLEAN NULL,
    created_at                      TIMESTAMP NULL,
    updated_at                      TIMESTAMP NULL
);

-- 3c. company_attendance_settings
CREATE TABLE IF NOT EXISTS company_attendance_settings (
    id                      BIGSERIAL PRIMARY KEY,
    company_id              VARCHAR(24) NULL,
    geofence_enabled        BOOLEAN NULL,
    shifts                  JSONB NULL,
    automation_rules        JSONB NULL,
    fine_settings           JSONB NULL,
    created_at              TIMESTAMP NULL,
    updated_at              TIMESTAMP NULL
);

-- 4. branches
CREATE TABLE IF NOT EXISTS branches (
    id                  BIGSERIAL PRIMARY KEY,
    mongo_id            VARCHAR(24) NULL UNIQUE,
    branch_name         VARCHAR(255) NULL,
    branch_code         VARCHAR(100) NULL,
    is_head_office      BOOLEAN NULL,
    business_id         VARCHAR(24) NULL,
    email               VARCHAR(255) NULL,
    contact_number      VARCHAR(50) NULL,
    country_code        VARCHAR(10) NULL,
    address_apt_building TEXT NULL,
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

-- 5. roles
CREATE TABLE IF NOT EXISTS roles (
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

-- 6. asset_types
CREATE TABLE IF NOT EXISTS asset_types (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    name         VARCHAR(255) NULL,
    description  TEXT NULL,
    business_id  VARCHAR(24) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 7. assets
CREATE TABLE IF NOT EXISTS assets (
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

-- 8. attendance_templates
CREATE TABLE IF NOT EXISTS attendance_templates (
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

-- 9. attendances
CREATE TABLE IF NOT EXISTS attendances (
    id                    BIGSERIAL PRIMARY KEY,
    mongo_id              VARCHAR(24) NULL UNIQUE,
    employee_id           VARCHAR(24) NULL,
    user_id               VARCHAR(24) NULL,
    date                  DATE NULL,
    punch_in               TIMESTAMP NULL,
    punch_out              TIMESTAMP NULL,
    status                VARCHAR(50) NULL,
    approved_by           VARCHAR(24) NULL,
    approved_at           TIMESTAMP NULL,
    remarks               TEXT NULL,
    work_hours             DOUBLE PRECISION NULL,
    overtime               DOUBLE PRECISION NULL,
    fine_hours             DOUBLE PRECISION NULL,
    late_minutes           INTEGER NULL,
    early_minutes          INTEGER NULL,
    fine_amount            DOUBLE PRECISION NULL,
    location               JSONB NULL,
    ip_address             VARCHAR(45) NULL,
    punch_in_ip_address    VARCHAR(45) NULL,
    punch_out_ip_address   VARCHAR(45) NULL,
    business_id            VARCHAR(24) NULL,
    punch_in_selfie        TEXT NULL,
    punch_out_selfie       TEXT NULL,
    created_at             TIMESTAMP NULL,
    updated_at             TIMESTAMP NULL
);

-- 10. candidates
CREATE TABLE IF NOT EXISTS candidates (
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
    current_company         VARCHAR(255) NULL,
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

-- 11. document_requirements
CREATE TABLE IF NOT EXISTS document_requirements (
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

-- 12. expenses
CREATE TABLE IF NOT EXISTS expenses (
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

-- 13. holiday_templates
CREATE TABLE IF NOT EXISTS holiday_templates (
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

-- 14. job_openings
CREATE TABLE IF NOT EXISTS job_openings (
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

-- 15. leave_templates
CREATE TABLE IF NOT EXISTS leave_templates (
    id           BIGSERIAL PRIMARY KEY,
    mongo_id     VARCHAR(24) NULL UNIQUE,
    name         VARCHAR(255) NULL,
    leave_types  JSONB NULL,
    limits       JSONB NULL,
    business_id  VARCHAR(24) NULL,
    created_at   TIMESTAMP NULL,
    updated_at   TIMESTAMP NULL
);

-- 16. leaves
CREATE TABLE IF NOT EXISTS leaves (
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

-- 17. loans
CREATE TABLE IF NOT EXISTS loans (
    id              BIGSERIAL PRIMARY KEY,
    mongo_id        VARCHAR(24) NULL UNIQUE,
    employee_id     VARCHAR(24) NULL,
    loan_type       VARCHAR(50) NULL,
    amount          DOUBLE PRECISION NULL,
    purpose         TEXT NULL,
    interest_rate    DOUBLE PRECISION NULL,
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

-- 18. onboardings
CREATE TABLE IF NOT EXISTS onboardings (
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

-- 19. payrolls
CREATE TABLE IF NOT EXISTS payrolls (
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

-- 20. payslip_requests
CREATE TABLE IF NOT EXISTS payslip_requests (
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

-- 21. reimbursements
CREATE TABLE IF NOT EXISTS reimbursements (
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

-- visitors (per-company)
CREATE TABLE IF NOT EXISTS visitors (
    id                  BIGSERIAL PRIMARY KEY,
    company_id          BIGINT         NULL,
    branch_id           BIGINT         NULL,
    visitor_name        VARCHAR(255)   NOT NULL,
    visitor_phone       VARCHAR(50)    NULL,
    visitor_email       VARCHAR(255)   NULL,
    visitor_company     VARCHAR(255)   NULL,
    visitor_designation VARCHAR(255)   NULL,
    id_proof_type       VARCHAR(50)    NULL,
    id_proof_number     VARCHAR(100)   NULL,
    visitor_photo       TEXT           NULL,
    visitor_count       INTEGER        NOT NULL DEFAULT 1,
    purpose             VARCHAR(255)   NULL,
    purpose_description TEXT           NULL,
    host_employee_id    BIGINT         NULL,
    host_name           VARCHAR(255)   NULL,
    host_department      VARCHAR(255)   NULL,
    expected_check_in   TIMESTAMP      NULL,
    check_in            TIMESTAMP      NULL,
    check_out           TIMESTAMP      NULL,
    status              VARCHAR(30)    NOT NULL DEFAULT 'expected',
    approved_by         BIGINT         NULL,
    approval_status     VARCHAR(30)    NULL DEFAULT 'pending',
    rejection_reason    TEXT           NULL,
    badge_number        VARCHAR(50)    NULL,
    pass_type           VARCHAR(30)    NULL,
    is_pre_registered   BOOLEAN        NOT NULL DEFAULT FALSE,
    pre_registered_by   BIGINT         NULL,
    invite_sent         BOOLEAN        NOT NULL DEFAULT FALSE,
    notes               TEXT           NULL,
    metadata            JSONB          NULL,
    created_at          TIMESTAMP      NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP      NOT NULL DEFAULT NOW()
);
