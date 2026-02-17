"""
Ensure designations table exists. Run from crm_backend:
  python scripts/ensure_designations_table.py
Uses same DB config as the app. Safe to run multiple times (IF NOT EXISTS).
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

from config.database import get_cursor


def main():
    with get_cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS designations (
                id BIGSERIAL PRIMARY KEY,
                company_id BIGINT NOT NULL,
                name VARCHAR(255) NOT NULL,
                active BOOLEAN NOT NULL DEFAULT true,
                created_at TIMESTAMP NULL DEFAULT NOW(),
                updated_at TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute(
            "CREATE INDEX IF NOT EXISTS idx_designations_company_id ON designations(company_id)"
        )
    print("Designations table is ready.")


if __name__ == "__main__":
    main()
