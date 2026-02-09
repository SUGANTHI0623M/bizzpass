"""
Initialize bizzpass database: create DB if not exists, run schema, seed superadmin.
Run from project root: python -m scripts.init_db (or from crm_backend: python scripts/init_db.py)
"""
import os
import sys
from pathlib import Path

# Allow importing config from crm_backend
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

import psycopg2
from psycopg2.extras import RealDictCursor
import bcrypt

from config.settings import settings
from config.database import get_connection, get_cursor


SUPERADMIN_EMAIL = "shadmin@gmail.com"
SUPERADMIN_PASSWORD = "#sh123"
SUPERADMIN_NAME = "Super Admin"


def create_database_if_not_exists():
    """Create database bizzpass if it does not exist."""
    conn = get_connection(db_name="postgres")
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(
        "SELECT 1 FROM pg_database WHERE datname = %s",
        (settings.db_name,),
    )
    if cur.fetchone():
        print(f"Database '{settings.db_name}' already exists.")
    else:
        cur.execute(f'CREATE DATABASE "{settings.db_name}"')
        print(f"Created database '{settings.db_name}'.")
    cur.close()
    conn.close()


def schema_already_applied(cur) -> bool:
    """Return True if users table exists."""
    cur.execute(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
        """
    )
    return cur.fetchone() is not None


def run_schema(cur):
    """Run postgres_schema.sql. Make CREATE TABLE and CREATE INDEX idempotent."""
    # When run from repo (host): crm_backend/scripts/ -> ROOT.parent = repo root
    # When run in Docker: /app/scripts/ -> ROOT = /app, postgres_schema.sql is copied to /app
    schema_path = ROOT.parent / "postgres_schema.sql"
    if not schema_path.exists():
        schema_path = ROOT / "postgres_schema.sql"
    if not schema_path.exists():
        raise FileNotFoundError(
            "Schema file not found. Run from repo root (postgres_schema.sql) or ensure it is in crm_backend/."
        )
    sql = schema_path.read_text(encoding="utf-8")

    # Idempotent: avoid "already exists" on re-run
    sql = sql.replace("CREATE TABLE ", "CREATE TABLE IF NOT EXISTS ")
    # Only replace "CREATE INDEX " where not already "CREATE INDEX IF NOT EXISTS "
    sql = sql.replace("CREATE INDEX ", "CREATE INDEX IF NOT EXISTS ")
    # Fix double IF NOT EXISTS
    sql = sql.replace("CREATE INDEX IF NOT EXISTS IF NOT EXISTS ", "CREATE INDEX IF NOT EXISTS ")

    # Split into statements (semicolon at end of line or alone)
    import re
    parts = re.split(r";\s*\n", sql)
    statements = []
    for p in parts:
        stmt = p.strip()
        # Remove comment-only lines for cleaner execution
        if not stmt or stmt == ";":
            continue
        if stmt.startswith("--"):
            continue
        if not stmt.endswith(";"):
            stmt += ";"
        statements.append(stmt)

    for stmt in statements:
        stmt = stmt.strip()
        if not stmt or stmt == ";":
            continue
        try:
            cur.execute(stmt)
        except Exception as e:
            # Ignore "already exists" for table/index
            if "already exists" in str(e).lower():
                continue
            raise
    print("Schema applied.")


def run_migrations(cur):
    """Add missing columns (staff.company_id, companies Phase 1 columns e.g. db_name)."""
    try:
        cur.execute(
            "ALTER TABLE staff ADD COLUMN IF NOT EXISTS company_id BIGINT NULL"
        )
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_staff_company_id ON staff(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note:", e)

    # Phase 1: companies table columns for per-company DB and licensing
    try:
        cur.execute(
            """
            ALTER TABLE companies
                ADD COLUMN IF NOT EXISTS license_id          BIGINT NULL,
                ADD COLUMN IF NOT EXISTS db_name             VARCHAR(64) NULL,
                ADD COLUMN IF NOT EXISTS gst_number          VARCHAR(20) NULL,
                ADD COLUMN IF NOT EXISTS pan_number          VARCHAR(20) NULL,
                ADD COLUMN IF NOT EXISTS billing_email       VARCHAR(255) NULL,
                ADD COLUMN IF NOT EXISTS billing_address     TEXT NULL,
                ADD COLUMN IF NOT EXISTS max_users_allowed   INTEGER NULL,
                ADD COLUMN IF NOT EXISTS registered_via       VARCHAR(50) NULL
            """
        )
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_companies_license_id ON companies(license_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (companies):", e)

    # Branches: add company_id for company-scoped listing
    try:
        cur.execute(
            "ALTER TABLE branches ADD COLUMN IF NOT EXISTS company_id BIGINT NULL"
        )
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_branches_company_id ON branches(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (branches):", e)

    # Branches: geofence columns for lat/long and attendance check-in radius (tenant_schema may already have them)
    for col, typ in [
        ("geofence_latitude", "DOUBLE PRECISION NULL"),
        ("geofence_longitude", "DOUBLE PRECISION NULL"),
        ("geofence_radius", "DOUBLE PRECISION NULL"),
    ]:
        try:
            cur.execute(f"ALTER TABLE branches ADD COLUMN IF NOT EXISTS {col} {typ}")
        except Exception as e:
            if "already exists" not in str(e).lower():
                print("Migration note (branches geofence):", e)

    # Departments table (company-scoped list of department names)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS departments (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_departments_company_id ON departments(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (departments):", e)

    # Attendance templates: add company_id for company-scoped attendance modals
    try:
        cur.execute(
            "ALTER TABLE attendance_templates ADD COLUMN IF NOT EXISTS company_id BIGINT NULL"
        )
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_attendance_templates_company_id ON attendance_templates(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (attendance_templates):", e)

    # Shift modals table (company-scoped shift definitions)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS shift_modals (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                start_time VARCHAR(10) NOT NULL,
                end_time VARCHAR(10) NOT NULL,
                grace_minutes INTEGER NOT NULL DEFAULT 10,
                grace_unit VARCHAR(20) NOT NULL DEFAULT 'Minutes',
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_shift_modals_company_id ON shift_modals(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (shift_modals):", e)

    # Shift modals: add is_active for activate/deactivate
    try:
        cur.execute(
            "ALTER TABLE shift_modals ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (shift_modals is_active):", e)

    # Leave categories (company-scoped: Sick, Casual, etc.)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS leave_categories (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_leave_categories_company_id ON leave_categories(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (leave_categories):", e)

    # Leave modals (company-scoped leave templates for CRM)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS leave_modals (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                description TEXT NULL,
                leave_types JSONB NULL,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_leave_modals_company_id ON leave_modals(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (leave_modals):", e)

    # Holiday modals (company-scoped weekly off patterns: sundays, odd_saturday, etc.)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS holiday_modals (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                pattern_type VARCHAR(32) NOT NULL DEFAULT 'sundays',
                custom_days JSONB NULL,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_holiday_modals_company_id ON holiday_modals(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (holiday_modals):", e)

    # Office holidays (company-scoped list of holiday dates)
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS office_holidays (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                date DATE NOT NULL,
                created_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_office_holidays_company_id ON office_holidays(company_id)"
        )
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (office_holidays):", e)

    # Ensure "basic" plan exists for CRM UI (idempotent). Max 30 staff, 1 branch.
    try:
        cur.execute(
            """
            INSERT INTO subscription_plans (plan_code, plan_name, description, price, currency, duration_months, max_users, max_branches, is_active, trial_days, created_at, updated_at)
            VALUES ('basic', 'Basic', 'Basic plan', 9999, 'INR', 12, 30, 1, TRUE, 0, NOW(), NOW())
            ON CONFLICT (plan_code) DO UPDATE SET max_users = 30, max_branches = 1, updated_at = NOW()
            """
        )
    except Exception as e:
        if "already exists" not in str(e).lower() and "duplicate" not in str(e).lower():
            print("Migration note (basic plan):", e)


def seed_subscription_plans(cur):
    """Seed subscription plans if empty."""
    cur.execute("SELECT COUNT(*) AS n FROM subscription_plans")
    n = (cur.fetchone() or {}).get("n", 0) or 0
    if n > 0:
        print("Subscription plans already exist.")
        return
    plans = [
        ("basic", "Basic", "Basic plan", 9999, 12, 10, 1, True, 0),
        ("starter", "Starter", "Starter plan", 19999, 12, 30, 1, True, 0),
        ("professional", "Professional", "Pro plan", 59999, 12, 100, 5, True, 0),
        ("enterprise", "Enterprise", "Enterprise plan", 149999, 12, 300, None, True, 0),
    ]
    for code, name, desc, price, dur, users, branches, active, trial in plans:
        cur.execute(
            """
            INSERT INTO subscription_plans (plan_code, plan_name, description, price, duration_months, max_users, max_branches, is_active, trial_days, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            ON CONFLICT (plan_code) DO NOTHING
            """,
            (code, name, desc, price, dur, users, branches, active, trial),
        )
    print("Subscription plans seeded.")


def seed_superadmin(cur):
    """Insert superadmin user if not exists. Password hashed with bcrypt."""
    cur.execute(
        "SELECT id FROM users WHERE LOWER(email) = LOWER(%s)",
        (SUPERADMIN_EMAIL,),
    )
    if cur.fetchone():
        print("Superadmin user already exists.")
        return

    hashed = bcrypt.hashpw(
        SUPERADMIN_PASSWORD.encode("utf-8"),
        bcrypt.gensalt(rounds=12),
    ).decode("utf-8")

    cur.execute(
        """
        INSERT INTO users (name, email, password, role, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, 'super_admin', TRUE, NOW(), NOW())
        RETURNING id
        """,
        (SUPERADMIN_NAME, SUPERADMIN_EMAIL.lower(), hashed),
    )
    row = cur.fetchone()
    # Add is_super_admin column if not present (schema Phase 1 ALTER)
    try:
        cur.execute(
            """
            ALTER TABLE users
            ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN NOT NULL DEFAULT FALSE
            """
        )
        cur.execute(
            "UPDATE users SET is_super_admin = TRUE WHERE id = %s",
            (row["id"],),
        )
    except Exception:
        pass
    print("Superadmin user created: shadmin@gmail.com / #sh123")


def seed_crm_sample_data(cur):
    """Seed sample companies, licenses, staff, visitors, payments, notifications."""
    cur.execute("SELECT id FROM users WHERE role = 'super_admin' LIMIT 1")
    admin = cur.fetchone()
    admin_id = admin["id"] if admin else 1

    cur.execute("SELECT COUNT(*) AS n FROM companies")
    if (cur.fetchone() or {}).get("n", 0) or 0 > 0:
        print("Sample CRM data already exists.")
        return

    cur.execute("SELECT id FROM subscription_plans WHERE plan_code = 'starter' LIMIT 1")
    sp_starter = (cur.fetchone() or {}).get("id")
    cur.execute("SELECT id FROM subscription_plans WHERE plan_code = 'professional' LIMIT 1")
    sp_pro = (cur.fetchone() or {}).get("id")
    cur.execute("SELECT id FROM subscription_plans WHERE plan_code = 'enterprise' LIMIT 1")
    sp_ent = (cur.fetchone() or {}).get("id")
    if not sp_starter:
        print("Subscription plans not found, skipping sample data.")
        return

    # Companies
    companies_data = [
        ("TechNova Solutions", "admin@technova.in", "+91 98765 43210", "Mumbai", "Maharashtra", "enterprise", "active", "2026-06-15"),
        ("GreenLeaf Agritech", "ops@greenleaf.co", "+91 87654 32109", "Pune", "Maharashtra", "professional", "active", "2025-09-30"),
        ("Meridian Logistics", "hr@meridian.in", "+91 76543 21098", "Chennai", "Tamil Nadu", "starter", "expiring_soon", "2025-03-15"),
    ]
    import uuid
    for name, email, phone, city, state, plan, status, end_date in companies_data:
        cur.execute(
            """
            INSERT INTO companies (name, email, phone, address_city, address_state, subscription_plan, subscription_status, subscription_end_date, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s::date, TRUE, NOW(), NOW())
            RETURNING id
            """,
            (name, email, phone, city, state, plan.title(), status, end_date),
        )

    # Licenses linked to companies
    plan_ids = {"starter": sp_starter, "professional": sp_pro or sp_starter, "enterprise": sp_ent or sp_starter}
    cur.execute("SELECT id, name FROM companies ORDER BY id LIMIT 5")
    comps = cur.fetchall()
    for i, c in enumerate(comps or []):
        plan = ["enterprise", "professional", "starter"][min(i, 2)]
        lic_key = f"BP-{plan[:3].upper()}-2025-{uuid.uuid4().hex[:4].upper()}"
        cur.execute(
            """
            INSERT INTO licenses (license_key, company_id, plan_id, max_users, status, valid_from, valid_until, is_trial, created_by, created_at, updated_at)
            VALUES (%s, %s, %s, %s, 'active', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', FALSE, %s, NOW(), NOW())
            RETURNING id
            """,
            (lic_key, c["id"], plan_ids.get(plan, sp_starter), [300, 100, 30][min(i, 2)], admin_id),
        )
        lic_row = cur.fetchone()
        if lic_row:
            cur.execute("UPDATE companies SET license_id = %s WHERE id = %s", (lic_row["id"], c["id"]))

    # Unassigned license
    cur.execute(
        "INSERT INTO licenses (license_key, plan_id, max_users, status, is_trial, created_by, created_at, updated_at) VALUES (%s, %s, 25, 'unassigned', TRUE, %s, NOW(), NOW())",
        (f"BP-TRL-2025-{uuid.uuid4().hex[:4].upper()}", sp_starter, admin_id),
    )

    # Staff
    cur.execute("SELECT id, name FROM companies ORDER BY id LIMIT 3")
    comps = cur.fetchall()
    staff_data = [
        ("TN-001", "Arjun Mehta", "arjun@technova.in", "+91 98111 22334", "Sr. Developer", "Engineering", "active", "2023-04-10"),
        ("TN-002", "Priya Sharma", "priya@technova.in", "+91 98222 33445", "Product Manager", "Product", "active", "2022-08-15"),
        ("GL-001", "Rohit Patel", "rohit@greenleaf.co", "+91 87333 44556", "Operations Head", "Operations", "active", "2023-01-05"),
        ("ML-001", "Suresh Kumar", "suresh@meridian.in", "+91 65555 66778", "Fleet Manager", "Logistics", "active", "2024-02-01"),
    ]
    for i, (emp_id, name, email, phone, designation, dept, status, join_date) in enumerate(staff_data):
        comp_id = comps[min(i // 2, len(comps) - 1)]["id"] if comps else None
        cur.execute(
            """
            INSERT INTO staff (employee_id, name, email, phone, designation, department, status, joining_date, company_id, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s::date, %s, NOW(), NOW())
            """,
            (emp_id, name, email, phone, designation, dept, status, join_date, comp_id),
        )

    # Visitors
    cur.execute("SELECT id FROM companies LIMIT 1")
    cid = (cur.fetchone() or {}).get("id")
    if cid:
        cur.execute(
            """
            INSERT INTO visitors (company_id, visitor_name, visitor_company, purpose, host_name, status, badge_number, created_at, updated_at)
            VALUES (%s, 'Rajesh Khanna', 'Infosys', 'Client Meeting', 'Arjun Mehta', 'checked_in', 'V-0142', NOW(), NOW()),
                   (%s, 'Meera Iyer', 'Apollo Hospitals', 'Partnership Discussion', 'Dr. Kavitha Rao', 'expected', 'V-0143', NOW(), NOW())
            """,
            (cid, cid),
        )

    # Payments
    cur.execute("SELECT id FROM companies ORDER BY id LIMIT 2")
    comps = cur.fetchall()
    cur.execute("SELECT id FROM licenses WHERE company_id IS NOT NULL ORDER BY id LIMIT 2")
    lics = cur.fetchall()
    if comps and lics and sp_ent and sp_pro:
        cur.execute(
            """
            INSERT INTO payments (company_id, license_id, plan_id, gateway, amount, total_amount, currency, status, payment_method, razorpay_payment_id, paid_at, created_at, updated_at)
            VALUES (%s, %s, %s, 'razorpay', 149999, 149999, 'INR', 'captured', 'UPI', 'pay_Nk2x8Qs9TgZ', NOW(), NOW(), NOW()),
                   (%s, %s, %s, 'razorpay', 59999, 59999, 'INR', 'captured', 'Card', 'pay_Mj7w5Pr8SfY', NOW(), NOW(), NOW())
            """,
            (comps[0]["id"], lics[0]["id"], sp_ent, comps[1]["id"] if len(comps) > 1 else comps[0]["id"], lics[1]["id"] if len(lics) > 1 else lics[0]["id"], sp_pro),
        )

    # Notifications
    cur.execute("SELECT id FROM companies LIMIT 1")
    cid = (cur.fetchone() or {}).get("id")
    if cid:
        cur.execute(
            """
            INSERT INTO notifications (company_id, type, title, message, channel, priority, status, created_at, updated_at)
            VALUES (%s, 'license_expiry_reminder', 'License expiring in 35 days', 'Please renew', 'email', 'high', 'sent', NOW(), NOW()),
                   (%s, 'payment_confirmation', 'Payment received — ₹1,49,999', 'Thank you', 'email', 'normal', 'delivered', NOW(), NOW())
            """,
            (cid, cid),
        )
    print("Sample CRM data seeded.")


def sync_license_limits_from_plan(cur):
    """Sync license max_users and max_branches from their subscription plan."""
    try:
        cur.execute("""
            UPDATE licenses l
            SET max_users = COALESCE(sp.max_users, 30),
                max_branches = COALESCE(sp.max_branches, 1),
                updated_at = NOW()
            FROM subscription_plans sp
            WHERE sp.id = l.plan_id
        """)
        if cur.rowcount > 0:
            print(f"Synced {cur.rowcount} license(s) with plan limits.")
    except Exception as e:
        if "already exists" not in str(e).lower():
            print("Migration note (sync_license_limits):", e)


def main():
    create_database_if_not_exists()
    conn = get_connection()
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        if not schema_already_applied(cur):
            run_schema(cur)
            conn.commit()
        else:
            print("Schema already applied (users table exists).")
        run_migrations(cur)
        seed_subscription_plans(cur)
        seed_superadmin(cur)
        seed_crm_sample_data(cur)
        sync_license_limits_from_plan(cur)
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
    # Run RBAC migration (creates rbac tables, company admin: admin@technova.in / Admin@123)
    try:
        from scripts.rbac_migration import main as rbac_main
        rbac_main()
    except Exception as e:
        print(f"RBAC migration note: {e}")
    print("Init done.")


if __name__ == "__main__":
    main()
