"""
Fix companies that have no license - assign auto-created license so company admin can log in.
Run: python scripts/fix_companies_without_license.py
"""
import os
import sys
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

from config.database import get_connection
from psycopg2.extras import RealDictCursor


def main():
    conn = get_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    try:
        cur.execute("""
            SELECT c.id, c.name, c.subscription_plan
            FROM companies c
            LEFT JOIN licenses l ON l.company_id = c.id
            WHERE l.id IS NULL
        """)
        companies = cur.fetchall()
        if not companies:
            print("All companies already have licenses.")
            return

        cur.execute("SELECT id FROM users WHERE is_super_admin = TRUE OR role = 'super_admin' LIMIT 1")
        admin = cur.fetchone()
        admin_id = admin["id"] if admin else 1

        for c in companies:
            plan = (c.get("subscription_plan") or "Starter").lower().replace(" ", "_")
            if plan == "pro":
                plan = "professional"
            cur.execute(
                "SELECT id, max_users, max_branches FROM subscription_plans WHERE (plan_code = %s OR plan_name ILIKE %s) AND is_active LIMIT 1",
                (plan, "%" + (c.get("subscription_plan") or "Starter") + "%"),
            )
            sp = cur.fetchone()
            if not sp:
                cur.execute("SELECT id, max_users, max_branches FROM subscription_plans WHERE is_active LIMIT 1")
                sp = cur.fetchone()
            if not sp:
                print(f"  Skip company {c['id']} ({c['name']}): no subscription plan found")
                continue

            max_users = sp.get("max_users") or 30
            max_branches = sp.get("max_branches") or 1
            license_key = f"BP-{plan[:3].upper()}-{str(uuid.uuid4())[:8].upper()}"
            cur.execute(
                """
                INSERT INTO licenses (license_key, plan_id, max_users, max_branches, is_trial, created_by, status)
                VALUES (%s, %s, %s, %s, FALSE, %s, 'unassigned')
                RETURNING id
                """,
                (license_key, sp["id"], max_users, max_branches, admin_id),
            )
            lic = cur.fetchone()
            cur.execute(
                "UPDATE licenses SET company_id = %s, status = 'active', valid_from = CURRENT_DATE, valid_until = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
                (c["id"], lic["id"]),
            )
            cur.execute(
                "UPDATE companies SET license_id = %s, subscription_end_date = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
                (lic["id"], c["id"]),
            )
            print(f"  Fixed company {c['id']} ({c['name']}) - license {license_key}")

        conn.commit()
        print(f"Fixed {len(companies)} company(ies).")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
