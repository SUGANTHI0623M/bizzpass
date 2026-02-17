"""Add template columns to departments table so department templates can be saved and loaded.

Docker (recommended):
  From project root: docker compose run --rm crm_backend python scripts/add_department_template_columns.py

Local (needs crm_backend/.env or DB_* env vars):
  From project root: python crm_backend/scripts/add_department_template_columns.py
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
# Load .env from crm_backend when run from project root
os.chdir(ROOT)

try:
    from config.database import get_cursor
except ModuleNotFoundError as e:
    if "psycopg2" in str(e):
        print("psycopg2 not found. Use the same Python that has backend dependencies, e.g.:")
        print("  pip install -r crm_backend/requirements.txt")
        print("  C:\\Python312\\python.exe crm_backend/scripts/add_department_template_columns.py")
        print("Or activate your backend venv, then run this script again.")
    raise SystemExit(1) from e


def main():
    columns = [
        "attendance_modal_id",
        "overtime_template_id",
        "leave_modal_id",
        "shift_modal_id",
        "holiday_modal_id",
        "salary_modal_id",
        "fine_modal_id",
    ]
    with get_cursor() as cur:
        for col in columns:
            try:
                cur.execute(f"ALTER TABLE departments ADD COLUMN IF NOT EXISTS {col} BIGINT NULL")
                print(f"  OK: departments.{col}")
            except Exception as e:
                print(f"  Skip: {col} - {e}")
    print("Done. Department templates will now save and load.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        if "OperationalError" in type(e).__name__ and "password authentication failed" in str(e):
            print("\nDatabase connection failed. Set credentials in crm_backend/.env (copy from .env.example):")
            print("  DB_USER=your_postgres_user")
            print("  DB_PASSWORD=your_postgres_password")
            print("  DB_HOST=localhost  DB_PORT=5432  DB_NAME=bizzpass\n")
        raise
