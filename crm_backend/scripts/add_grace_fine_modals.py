"""Add fine_modal_templates, fine_modal_id to departments/staff, grace_config to payroll_settings.

Docker: docker compose run --rm crm_backend python scripts/add_grace_fine_modals.py
Local: python crm_backend/scripts/add_grace_fine_modals.py
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
os.chdir(ROOT)

try:
    from config.database import get_cursor
except ModuleNotFoundError as e:
    if "psycopg2" in str(e):
        print("psycopg2 not found. Use the same Python that has backend dependencies.")
    raise SystemExit(1) from e


def main():
    with get_cursor() as cur:
        # 1. Create fine_modal_templates table (grace rules + fine calculation template)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS fine_modal_templates (
                id                      BIGSERIAL PRIMARY KEY,
                company_id              BIGINT NOT NULL,
                name                    VARCHAR(255) NOT NULL,
                description             TEXT NULL,
                is_active               BOOLEAN NOT NULL DEFAULT TRUE,
                -- Grace config: LATE_LOGIN and EARLY_LOGOUT can have separate rules
                grace_config            JSONB NULL,
                -- Fine calculation: per_minute, fixed_per_occurrence
                fine_calculation_method VARCHAR(50) DEFAULT 'per_minute',
                fine_fixed_amount       DOUBLE PRECISION NULL,
                created_at              TIMESTAMP NULL DEFAULT NOW(),
                updated_at              TIMESTAMP NULL DEFAULT NOW()
            )
        """)
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_fine_modal_templates_company 
            ON fine_modal_templates(company_id)
        """)
        print("  OK: fine_modal_templates")

        # 2. Add fine_modal_id to departments
        cur.execute(
            "ALTER TABLE departments ADD COLUMN IF NOT EXISTS fine_modal_id BIGINT NULL"
        )
        print("  OK: departments.fine_modal_id")

        # 3. Add fine_modal_id to staff
        cur.execute(
            "ALTER TABLE staff ADD COLUMN IF NOT EXISTS fine_modal_id BIGINT NULL"
        )
        print("  OK: staff.fine_modal_id")

    print("Done. Fine modal templates and columns ready.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        if "OperationalError" in type(e).__name__ and "password" in str(e).lower():
            print("\nDatabase connection failed. Set credentials in crm_backend/.env")
        raise
