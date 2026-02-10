r"""Create or reset company admin login (email + password) for an existing company.
Use this when a company was created before admin login was automated, or to reset the password.

Usage:
  python scripts/create_or_reset_company_admin.py <company_email_or_name> <password> [login_email]

Examples:
  python scripts/create_or_reset_company_admin.py "suganthi2306m@gmail.com" "MySecurePass123"
  python scripts/create_or_reset_company_admin.py "Cisco" "MySecurePass123"
  python scripts/create_or_reset_company_admin.py "cude" "BizzPass@123" ss@gmail.com

The first argument is matched against:
  - company email (exact, case-insensitive), or
  - company name (case-insensitive contains).
If one company is found, we create or update the user for that company.
Optional third argument: login email to use (e.g. ss@gmail.com). If omitted, company's email is used.
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

import bcrypt
import psycopg2
from psycopg2.extras import RealDictCursor

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ.get("DB_NAME", "bizzpass")
DB_USER = os.environ.get("DB_USER", "dev")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "dev1234")


def main():
    if len(sys.argv) < 3:
        print("Usage: python create_or_reset_company_admin.py <company_email_or_name> <password> [login_email]")
        print("Example: python create_or_reset_company_admin.py \"cude\" \"BizzPass@123\" ss@gmail.com")
        sys.exit(1)

    identifier = sys.argv[1].strip()
    password = sys.argv[2]
    login_email = sys.argv[3].strip() if len(sys.argv) > 3 else None
    if not identifier or not password:
        print("Company identifier and password are required.")
        sys.exit(1)

    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        cursor_factory=RealDictCursor,
    )
    cur = conn.cursor()

    # Find company by email or name
    cur.execute(
        "SELECT id, name, email FROM companies WHERE LOWER(TRIM(email)) = LOWER(%s) LIMIT 1",
        (identifier,),
    )
    company = cur.fetchone()
    if not company:
        cur.execute(
            "SELECT id, name, email FROM companies WHERE name ILIKE %s LIMIT 1",
            (f"%{identifier}%",),
        )
        company = cur.fetchone()
    if not company:
        print(f"No company found for: {identifier}")
        cur.close()
        conn.close()
        sys.exit(1)

    company_id = company["id"]
    company_email = (company["email"] or "").strip()
    company_name = (company["name"] or "").strip() or "Company Admin"
    # Use optional login_email if provided; otherwise company email (must be set)
    user_email = (login_email or company_email).strip()
    if not user_email:
        print("Company has no email set. Set company email first, or pass login email as third argument.")
        cur.close()
        conn.close()
        sys.exit(1)

    # Get COMPANY_ADMIN role id if exists
    cur.execute(
        "SELECT id FROM rbac_roles WHERE code = %s AND company_id IS NULL LIMIT 1",
        ("COMPANY_ADMIN",),
    )
    role_row = cur.fetchone()
    rbac_role_id = role_row["id"] if role_row else None

    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")

    # Find existing user by login email and this company
    cur.execute(
        """
        SELECT id FROM users WHERE LOWER(email) = LOWER(%s) AND company_id_bigint = %s LIMIT 1
        """,
        (user_email, company_id),
    )
    existing = cur.fetchone()

    if existing:
        cur.execute(
            "UPDATE users SET password = %s, updated_at = NOW() WHERE id = %s",
            (hashed, existing["id"]),
        )
        print(f"Password updated for company admin: {user_email}")
    else:
        # Also check if user exists with this email for another company (e.g. wrong company) - still update for our company
        cur.execute(
            """
            INSERT INTO users (name, email, password, role, company_id_bigint, rbac_role_id, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, 'company_admin', %s, %s, TRUE, NOW(), NOW())
            """,
            (company_name, user_email, hashed, company_id, rbac_role_id),
        )
        print(f"Company admin created for: {company_name} ({user_email})")

    conn.commit()
    cur.close()
    conn.close()

    print(f"  Email:    {user_email}")
    print(f"  Password: (the one you passed on the command line)")
    print("  They can log in at the company portal with this email and password.")


if __name__ == "__main__":
    main()
