"""
RBAC migration: create roles, permissions, and link users to companies.
Run from crm_backend: python scripts/rbac_migration.py
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

import bcrypt
from psycopg2.extras import RealDictCursor

from config.database import get_connection, get_cursor
from config.settings import settings

# Phase 1 permissions
PERMISSIONS = [
    ("user.view", "user", "View users"),
    ("user.create", "user", "Create users"),
    ("user.edit", "user", "Edit users"),
    ("user.deactivate", "user", "Deactivate users"),
    ("role.view", "user", "View roles"),
    ("role.create", "user", "Create roles"),
    ("role.edit", "user", "Edit roles"),
    ("attendance.view", "attendance", "View attendance"),
    ("attendance.mark", "attendance", "Mark attendance"),
    ("attendance.edit", "attendance", "Edit attendance"),
    ("attendance.approve", "attendance", "Approve attendance"),
    ("attendance.report", "attendance", "Attendance reports"),
    ("leave.view", "leave", "View leave"),
    ("leave.apply", "leave", "Apply leave"),
    ("leave.approve", "leave", "Approve leave"),
    ("leave.report", "leave", "Leave reports"),
    ("payroll.view", "payroll", "View payroll"),
    ("payroll.generate", "payroll", "Generate payroll"),
    ("payslip.download", "payroll", "Download payslip"),
    ("task.view", "task", "View tasks"),
    ("task.create", "task", "Create tasks"),
    ("task.assign", "task", "Assign tasks"),
    ("task.update", "task", "Update tasks"),
    ("task.complete", "task", "Complete tasks"),
    ("visitor.create", "visitor", "Register visitor"),
    ("visitor.verify", "visitor", "Verify visitor"),
    ("visitor.checkin", "visitor", "Check in visitor"),
    ("visitor.checkout", "visitor", "Check out visitor"),
    ("visitor.view", "visitor", "View visitors"),
    ("subscription.view", "subscription", "View subscription"),
    ("invoice.download", "subscription", "Download invoice"),
    ("settings.view", "settings", "View settings"),
    ("settings.edit", "settings", "Edit settings"),
    ("report.view", "report", "View reports"),
    ("report.export", "report", "Export reports"),
    ("audit.view", "audit", "View audit logs"),
    ("branch.view", "branch", "View branches"),
    ("branch.create", "branch", "Create branch"),
    ("branch.edit", "branch", "Edit branch"),
    ("branch.delete", "branch", "Delete branch"),
    ("department.view", "department", "View departments"),
    ("department.create", "department", "Create department"),
    ("department.edit", "department", "Edit department"),
    ("department.delete", "department", "Delete department"),
]

# Default roles and their permissions
ROLE_PERMISSIONS = {
    "COMPANY_ADMIN": [],  # All permissions
    "HR": [
        "user.view", "user.create", "user.edit", "user.deactivate", "role.view", "role.create", "role.edit",
        "branch.view", "branch.create", "branch.edit", "branch.delete",
        "department.view", "department.create", "department.edit", "department.delete",
        "attendance.view", "attendance.mark", "attendance.edit", "attendance.approve", "attendance.report",
        "leave.view", "leave.apply", "leave.approve", "leave.report",
        "payroll.view", "payroll.generate", "payslip.download",
        "task.view", "task.create", "task.assign", "task.update", "task.complete",
        "visitor.view", "visitor.create", "visitor.verify", "visitor.checkin", "visitor.checkout",
        "report.view", "report.export", "subscription.view", "invoice.download", "settings.view", "settings.edit", "audit.view",
    ],
    "MANAGER": [
        "user.view", "attendance.view", "attendance.approve", "attendance.report",
        "leave.view", "leave.apply", "leave.approve", "leave.report",
        "task.view", "task.create", "task.assign", "task.update", "task.complete",
        "visitor.view", "report.view", "report.export", "subscription.view", "settings.view", "audit.view",
    ],
    "EMPLOYEE": [
        "attendance.view", "attendance.mark",
        "leave.view", "leave.apply",
        "task.view", "task.update", "task.complete",
        "payslip.download", "settings.view",
    ],
    "RECEPTION": [
        "visitor.create", "visitor.verify", "visitor.checkin", "visitor.checkout", "visitor.view",
        "attendance.view", "settings.view",
    ],
    "SECURITY": [
        "visitor.verify", "visitor.checkin", "visitor.checkout", "visitor.view",
        "attendance.view",
    ],
}

COMPANY_ADMIN_PASSWORD = "Admin@123"


def run_migration(cur):
    """Create RBAC tables and alter users."""
    # Add company_id_bigint to users for CRM companies
    cur.execute(
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS company_id_bigint BIGINT NULL"
    )
    cur.execute(
        "CREATE INDEX IF NOT EXISTS idx_users_company_id_bigint ON users(company_id_bigint)"
    )
    cur.execute(
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS rbac_role_id BIGINT NULL"
    )

    # RBAC permissions (global)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS rbac_permissions (
            id BIGSERIAL PRIMARY KEY,
            code VARCHAR(80) NOT NULL UNIQUE,
            module VARCHAR(50) NOT NULL,
            description VARCHAR(255) NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """)

    # RBAC roles (company-scoped templates; company_id NULL = system template)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS rbac_roles (
            id BIGSERIAL PRIMARY KEY,
            code VARCHAR(50) NOT NULL,
            name VARCHAR(100) NOT NULL,
            company_id BIGINT NULL,
            description VARCHAR(255) NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """)
    cur.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS idx_rbac_roles_system_code
        ON rbac_roles(code) WHERE company_id IS NULL
    """)

    # Role-permission mapping
    cur.execute("""
        CREATE TABLE IF NOT EXISTS rbac_role_permissions (
            role_id BIGINT NOT NULL REFERENCES rbac_roles(id) ON DELETE CASCADE,
            permission_id BIGINT NOT NULL REFERENCES rbac_permissions(id) ON DELETE CASCADE,
            PRIMARY KEY (role_id, permission_id)
        )
    """)

    # Audit logs
    cur.execute("""
        CREATE TABLE IF NOT EXISTS audit_logs (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NULL,
            company_id BIGINT NULL,
            action VARCHAR(80) NOT NULL,
            entity_type VARCHAR(50) NULL,
            entity_id VARCHAR(50) NULL,
            details JSONB NULL,
            ip_address VARCHAR(45) NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """)
    cur.execute(
        "CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)"
    )
    cur.execute(
        "CREATE INDEX IF NOT EXISTS idx_audit_logs_company_id ON audit_logs(company_id)"
    )
    cur.execute(
        "CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at)"
    )

    print("RBAC migration: tables created.")


def seed_permissions(cur):
    """Seed permissions. Inserts any missing (ON CONFLICT DO NOTHING)."""
    for code, module, desc in PERMISSIONS:
        cur.execute(
            """
            INSERT INTO rbac_permissions (code, module, description)
            VALUES (%s, %s, %s) ON CONFLICT (code) DO NOTHING
            """,
            (code, module, desc),
        )
    # Ensure COMPANY_ADMIN has all permissions (including newly added)
    cur.execute("SELECT id FROM rbac_roles WHERE code = 'COMPANY_ADMIN' AND company_id IS NULL LIMIT 1")
    admin_role = cur.fetchone()
    if admin_role:
        cur.execute("SELECT id FROM rbac_permissions")
        all_pids = [r["id"] for r in cur.fetchall()]
        for pid in all_pids:
            cur.execute(
                "INSERT INTO rbac_role_permissions (role_id, permission_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                (admin_role["id"], pid),
            )
    print("Permissions seeded.")


def seed_roles(cur):
    """Seed default roles and permissions."""
    cur.execute("SELECT COUNT(*) AS n FROM rbac_roles WHERE company_id IS NULL")
    if (cur.fetchone() or {}).get("n", 0) or 0 > 0:
        print("Default roles already seeded.")
        return

    perm_map = {}
    cur.execute("SELECT id, code FROM rbac_permissions")
    for row in cur.fetchall():
        perm_map[row["code"]] = row["id"]

    all_perms = list(perm_map.values())

    roles_data = [
        ("COMPANY_ADMIN", "Company Admin", "Full access inside company"),
        ("HR", "HR", "HRMS operations"),
        ("MANAGER", "Manager", "Team oversight"),
        ("EMPLOYEE", "Employee", "Self actions"),
        ("RECEPTION", "Reception", "Visitor handling"),
        ("SECURITY", "Security", "QR scanning"),
    ]
    for code, name, desc in roles_data:
        cur.execute(
            "SELECT id FROM rbac_roles WHERE code = %s AND company_id IS NULL",
            (code,),
        )
        row = cur.fetchone()
        if not row:
            cur.execute(
                """
                INSERT INTO rbac_roles (code, name, company_id, description)
                VALUES (%s, %s, NULL, %s)
                RETURNING id
                """,
                (code, name, desc),
            )
            row = cur.fetchone()
        if row:
            role_id = row["id"]
            perms = ROLE_PERMISSIONS.get(code, [])
            perm_ids = [perm_map[p] for p in perms if p in perm_map]
            if code == "COMPANY_ADMIN":
                perm_ids = all_perms
            for pid in perm_ids:
                cur.execute(
                    """
                    INSERT INTO rbac_role_permissions (role_id, permission_id)
                    VALUES (%s, %s) ON CONFLICT DO NOTHING
                    """,
                    (role_id, pid),
                )
    print("Default roles and permissions seeded.")


def seed_company_admin(cur):
    """Create a test company admin user for first company."""
    cur.execute(
        "SELECT id FROM users WHERE email ILIKE %s AND company_id_bigint IS NOT NULL",
        ("admin@technova.in",),
    )
    if cur.fetchone():
        print("Company admin already exists.")
        return

    cur.execute("SELECT id FROM companies WHERE name ILIKE %s LIMIT 1", ("%technova%",))
    comp = cur.fetchone()
    if not comp:
        cur.execute("SELECT id FROM companies ORDER BY id LIMIT 1")
        comp = cur.fetchone()
    if not comp:
        print("No company found, skipping company admin seed.")
        return

    cur.execute(
        "SELECT id FROM rbac_roles WHERE code = %s AND company_id IS NULL",
        ("COMPANY_ADMIN",),
    )
    role_row = cur.fetchone()
    if not role_row:
        print("COMPANY_ADMIN role not found.")
        return

    hashed = bcrypt.hashpw(
        COMPANY_ADMIN_PASSWORD.encode("utf-8"),
        bcrypt.gensalt(rounds=12),
    ).decode("utf-8")

    cur.execute(
        """
        INSERT INTO users (name, email, password, role, company_id_bigint, rbac_role_id, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, 'company_admin', %s, %s, TRUE, NOW(), NOW())
        """,
        ("Company Admin", "admin@technova.in", hashed, comp["id"], role_row["id"]),
    )
    print("Company admin created: admin@technova.in / Admin@123 (for first company)")


def main():
    conn = get_connection()
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        run_migration(cur)
        seed_permissions(cur)
        seed_roles(cur)
        seed_company_admin(cur)
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
    print("RBAC migration done.")


if __name__ == "__main__":
    main()
