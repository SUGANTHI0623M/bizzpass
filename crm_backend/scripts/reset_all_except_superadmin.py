"""
Reset database: delete all companies, licenses, staff, branches, and per-company data.
Keeps: super admin user, subscription plans, system rbac_roles.
Drops all per-company databases (bizzpass_c_*).

Run: python scripts/reset_all_except_superadmin.py
From Docker: docker compose exec crm_backend python /app/scripts/reset_all_except_superadmin.py
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

import psycopg2
from psycopg2.extras import RealDictCursor

from config.settings import settings


def drop_company_databases():
    """Drop all bizzpass_c_* databases."""
    conn = psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname="postgres",
        user=settings.db_user,
        password=settings.db_password,
    )
    conn.autocommit = True
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT datname FROM pg_database WHERE datname LIKE 'bizzpass_c_%'"
        )
        dbs = [r[0] for r in cur.fetchall()]
        for db in dbs:
            cur.execute(f'DROP DATABASE IF EXISTS "{db}"')
            print(f"  Dropped database: {db}")
        if not dbs:
            print("  No company databases to drop.")
    finally:
        cur.close()
        conn.close()


def reset_main_database():
    """Delete all company-related data, keep super admin and plans."""
    conn = psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname=settings.db_name,
        user=settings.db_user,
        password=settings.db_password,
    )
    conn.autocommit = False
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        # Delete in order to respect foreign keys (child tables first)
        tables_to_truncate = [
            "invoices",
            "payments",
            "license_audit_logs",
            "notifications",
            "visitors",
            "staff",
            "branches",
            "departments",
            "attendance_templates",
            "shift_modals",
            "leave_modals",
            "office_holidays",
            "attendances",
            "audit_logs",
            "otps",
        ]
        for tbl in tables_to_truncate:
            try:
                cur.execute(f"DELETE FROM {tbl}")
                if cur.rowcount > 0:
                    print(f"  Deleted {cur.rowcount} rows from {tbl}")
            except Exception as e:
                if "does not exist" not in str(e).lower():
                    print(f"  {tbl}: {e}")

        # Delete company-scoped rbac_roles (keep system roles)
        try:
            cur.execute("DELETE FROM rbac_roles WHERE company_id IS NOT NULL")
            if cur.rowcount > 0:
                print(f"  Deleted {cur.rowcount} company rbac_roles")
        except Exception as e:
            if "does not exist" not in str(e).lower():
                print(f"  rbac_roles: {e}")

        # Delete licenses
        cur.execute("DELETE FROM licenses")
        print(f"  Deleted {cur.rowcount} licenses")

        # Delete companies
        cur.execute("DELETE FROM companies")
        print(f"  Deleted {cur.rowcount} companies")

        # Delete non-super-admin users (keep super admin)
        cur.execute(
            """
            DELETE FROM users
            WHERE NOT (role = 'super_admin' OR is_super_admin = TRUE)
            """
        )
        print(f"  Deleted {cur.rowcount} non-super-admin users")

        conn.commit()
        print("Main database reset complete. Super admin and subscription plans kept.")
    except Exception as e:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def main():
    print("Resetting database (keeping super admin only)...")
    print("1. Dropping company databases (bizzpass_c_*)...")
    drop_company_databases()
    print("2. Clearing main database...")
    reset_main_database()
    print("Done. You can create companies from scratch.")


if __name__ == "__main__":
    main()
