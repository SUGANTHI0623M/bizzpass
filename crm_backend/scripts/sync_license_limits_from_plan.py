"""
Sync license max_users and max_branches from their subscription plan.
Run: python scripts/sync_license_limits_from_plan.py
"""
import os
import sys
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
            SELECT l.id, l.license_key, l.company_id, l.max_users, l.max_branches,
                   sp.max_users AS plan_max_users, sp.max_branches AS plan_max_branches
            FROM licenses l
            JOIN subscription_plans sp ON sp.id = l.plan_id
        """)
        licenses = cur.fetchall()
        updated = 0
        for lic in licenses:
            plan_users = lic.get("plan_max_users") or 30
            plan_branches = lic.get("plan_max_branches") or 1
            cur.execute(
                "UPDATE licenses SET max_users = %s, max_branches = %s, updated_at = NOW() WHERE id = %s",
                (plan_users, plan_branches if plan_branches is not None else 1, lic["id"]),
            )
            if cur.rowcount > 0:
                updated += 1
                print(f"  Updated license {lic['license_key']}: max_users={plan_users}, max_branches={plan_branches or 1}")
        conn.commit()
        print(f"Synced {updated} license(s) with plan limits.")
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
