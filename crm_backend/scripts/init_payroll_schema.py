"""
Initialize Payroll Schema - Run this script to add payroll tables to existing tenant databases.
Uses DB_HOST, DB_PORT, DB_USER, DB_PASSWORD from environment or .env in crm_backend.

To avoid local Postgres credentials (e.g. "password authentication failed for user dev"):
  Run inside the backend container (uses same DB as the API):
    docker-compose exec crm_backend python scripts/init_payroll_schema.py
  If no bizzpass_c_* databases exist, the script will offer to init the default DB (e.g. bizzpass).
"""
import sys
import os

# Add parent directory to path and load .env from crm_backend before importing config
_script_dir = os.path.dirname(os.path.abspath(__file__))
_crm_backend_root = os.path.dirname(_script_dir)
sys.path.insert(0, _crm_backend_root)

# Load .env from crm_backend so DB_* match app / Docker
_env_file = os.path.join(_crm_backend_root, ".env")
if os.path.isfile(_env_file):
    from dotenv import load_dotenv
    load_dotenv(_env_file)

from config.database import get_cursor
from config.settings import settings
import psycopg2


def init_payroll_schema(db_name: str):
    """Initialize payroll schema for a tenant database"""
    print(f"Initializing payroll schema for {db_name}...")
    
    # Read the schema file
    schema_file = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        'schema',
        'payroll_schema.sql'
    )
    
    with open(schema_file, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
    
    try:
        with get_cursor(db_name=db_name, commit=True) as cur:
            # Execute the entire schema
            cur.execute(schema_sql)
            print(f"✓ Payroll schema initialized successfully for {db_name}")

            # Migration: overtime calculation method and values (for Salary Components > Overtime tab)
            for col, typ in [
                ("overtime_calculation_method", "VARCHAR(40) DEFAULT 'fixed_amount'"),
                ("overtime_fixed_amount_per_hour", "DOUBLE PRECISION NULL"),
                ("overtime_gross_pay_multiplier", "DOUBLE PRECISION NULL"),
                ("overtime_basic_pay_multiplier", "DOUBLE PRECISION NULL"),
            ]:
                try:
                    cur.execute(f"ALTER TABLE payroll_settings ADD COLUMN IF NOT EXISTS {col} {typ}")
                except Exception as e:
                    if "already exists" not in str(e).lower():
                        print(f"  Migration note (payroll_settings.{col}): {e}")

            # Migration: overtime_templates table (multiple customizable templates per company)
            try:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS overtime_templates (
                        id BIGSERIAL PRIMARY KEY,
                        company_id VARCHAR(24) NOT NULL,
                        name VARCHAR(255) NOT NULL,
                        company_type VARCHAR(50) DEFAULT 'custom',
                        is_default BOOLEAN DEFAULT FALSE,
                        config JSONB NOT NULL DEFAULT '{}',
                        created_at TIMESTAMP DEFAULT NOW(),
                        updated_at TIMESTAMP DEFAULT NOW()
                    )
                """)
                cur.execute("CREATE INDEX IF NOT EXISTS idx_overtime_templates_company ON overtime_templates(company_id)")
            except Exception as e:
                if "already exists" not in str(e).lower():
                    print(f"  Migration note (overtime_templates): {e}")

            # Migration: grace_config on payroll_settings (company-level default grace rules)
            try:
                cur.execute("ALTER TABLE payroll_settings ADD COLUMN IF NOT EXISTS grace_config JSONB NULL")
            except Exception as e:
                if "already exists" not in str(e).lower():
                    print(f"  Migration note (payroll_settings.grace_config): {e}")

            # Migration: salary_modal_components overrides (type, calculation type, value, statutory, taxable per template)
            for col, typ in [
                ("type_override", "VARCHAR(20) NULL"),
                ("calculation_type_override", "VARCHAR(50) NULL"),
                ("calculation_value_override", "DOUBLE PRECISION NULL"),
                ("is_taxable_override", "BOOLEAN NULL"),
                ("is_statutory_override", "BOOLEAN NULL"),
            ]:
                try:
                    cur.execute(f"ALTER TABLE salary_modal_components ADD COLUMN IF NOT EXISTS {col} {typ}")
                except Exception as e:
                    if "already exists" not in str(e).lower():
                        print(f"  Migration note (salary_modal_components.{col}): {e}")

            # Seed default salary components
            print(f"  Seeding default salary components...")
            seed_default_components(cur, db_name)
            print(f"✓ Default components seeded")

    except Exception as e:
        print(f"✗ Error initializing payroll schema for {db_name}: {e}")
        raise


def seed_default_components(cur, db_name: str):
    """Seed default salary components (common earnings and deductions)"""
    
    # Default Earning Components
    default_earnings = [
        {
            'name': 'basic_salary',
            'display_name': 'Basic Salary',
            'type': 'earning',
            'category': 'fixed',
            'calculation_type': 'percentage_of_gross',
            'calculation_value': 50.0,
            'is_taxable': True,
            'is_statutory': False,
            'priority_order': 1,
        },
        {
            'name': 'hra',
            'display_name': 'House Rent Allowance (HRA)',
            'type': 'earning',
            'category': 'fixed',
            'calculation_type': 'percentage_of_basic',
            'calculation_value': 40.0,
            'is_taxable': True,
            'is_statutory': False,
            'priority_order': 2,
        },
        {
            'name': 'special_allowance',
            'display_name': 'Special Allowance',
            'type': 'earning',
            'category': 'fixed',
            'calculation_type': 'percentage_of_gross',
            'calculation_value': 10.0,
            'is_taxable': True,
            'is_statutory': False,
            'priority_order': 3,
        },
        {
            'name': 'transport_allowance',
            'display_name': 'Transport Allowance',
            'type': 'earning',
            'category': 'fixed',
            'calculation_type': 'fixed_amount',
            'calculation_value': 1600.0,
            'is_taxable': False,
            'is_statutory': False,
            'max_value': 3200.0,
            'priority_order': 4,
        },
        {
            'name': 'medical_allowance',
            'display_name': 'Medical Allowance',
            'type': 'earning',
            'category': 'fixed',
            'calculation_type': 'fixed_amount',
            'calculation_value': 1250.0,
            'is_taxable': True,
            'is_statutory': False,
            'max_value': 15000.0,
            'priority_order': 5,
        },
    ]
    
    # Default Deduction Components
    default_deductions = [
        {
            'name': 'provident_fund',
            'display_name': 'Provident Fund (PF)',
            'type': 'deduction',
            'category': 'statutory',
            'calculation_type': 'percentage_of_basic',
            'calculation_value': 12.0,
            'is_taxable': False,
            'is_statutory': True,
            'max_value': 1800.0,
            'priority_order': 1,
        },
        {
            'name': 'esi',
            'display_name': 'Employee State Insurance (ESI)',
            'type': 'deduction',
            'category': 'statutory',
            'calculation_type': 'percentage_of_gross',
            'calculation_value': 0.75,
            'is_taxable': False,
            'is_statutory': True,
            'priority_order': 2,
        },
        {
            'name': 'professional_tax',
            'display_name': 'Professional Tax (PT)',
            'type': 'deduction',
            'category': 'statutory',
            'calculation_type': 'fixed_amount',
            'calculation_value': 200.0,
            'is_taxable': False,
            'is_statutory': True,
            'max_value': 2500.0,
            'priority_order': 3,
        },
        {
            'name': 'tds',
            'display_name': 'Tax Deducted at Source (TDS)',
            'type': 'deduction',
            'category': 'statutory',
            'calculation_type': 'formula',
            'calculation_value': 0.0,
            'is_taxable': False,
            'is_statutory': True,
            'priority_order': 4,
        },
    ]
    
    # Insert earnings
    for comp in default_earnings:
        cur.execute("""
            INSERT INTO salary_components (
                company_id, name, display_name, type, category,
                calculation_type, calculation_value, is_taxable, is_statutory,
                priority_order, min_value, max_value, is_active
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE
            )
            ON CONFLICT DO NOTHING
        """, (
            'default',  # Will be updated per company
            comp['name'],
            comp['display_name'],
            comp['type'],
            comp['category'],
            comp['calculation_type'],
            comp['calculation_value'],
            comp['is_taxable'],
            comp['is_statutory'],
            comp['priority_order'],
            comp.get('min_value'),
            comp.get('max_value'),
        ))
    
    # Insert deductions
    for comp in default_deductions:
        cur.execute("""
            INSERT INTO salary_components (
                company_id, name, display_name, type, category,
                calculation_type, calculation_value, is_taxable, is_statutory,
                priority_order, max_value, is_active
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE
            )
            ON CONFLICT DO NOTHING
        """, (
            'default',
            comp['name'],
            comp['display_name'],
            comp['type'],
            comp['category'],
            comp['calculation_type'],
            comp['calculation_value'],
            comp['is_taxable'],
            comp['is_statutory'],
            comp['priority_order'],
            comp.get('max_value'),
        ))


def get_all_tenant_databases():
    """Get list of all tenant databases (bizzpass_c_*)"""
    try:
        conn = psycopg2.connect(
            host=settings.db_host,
            port=settings.db_port,
            dbname='postgres',
            user=settings.db_user,
            password=settings.db_password,
        )
    except psycopg2.OperationalError as e:
        print(f"Database connection failed: {e}")
        print("  Check that Postgres is running and credentials are correct.")
        print("  When using Docker: start postgres (e.g. docker-compose up -d postgres), then from host use DB_HOST=localhost.")
        print("  Set DB_USER and DB_PASSWORD in crm_backend/.env to match your Postgres (e.g. dev / dev1234 from docker-compose).")
        raise SystemExit(1) from e

    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT datname FROM pg_database 
            WHERE datname LIKE 'bizzpass_c_%'
            ORDER BY datname
        """)
        databases = [row[0] for row in cur.fetchall()]
        return databases
    finally:
        conn.close()


def main():
    """Main function to initialize payroll schema for all tenant databases"""
    print("=" * 70)
    print("PAYROLL SCHEMA INITIALIZATION")
    print("=" * 70)
    print()
    
    # Get all tenant databases
    print("Fetching tenant databases...")
    databases = get_all_tenant_databases()
    
    already_confirmed = False
    if not databases:
        default_db = settings.db_name or "bizzpass"
        print(f"No tenant databases found (bizzpass_c_*).")
        print(f"You can initialize the default database '{default_db}' instead (e.g. when using Docker with a single DB).")
        response = input(f"Initialize payroll schema for '{default_db}'? (yes/no): ").strip().lower()
        if response not in ("yes", "y"):
            return
        databases = [default_db]
        already_confirmed = True
        print()
    else:
        print(f"Found {len(databases)} tenant database(s):")
        for db in databases:
            print(f"  - {db}")
        print()
        response = input("Initialize payroll schema for all these databases? (yes/no): ").strip().lower()
        if response not in ("yes", "y"):
            print("Aborted.")
            return
    
    print()
    print("Initializing...")
    print()
    
    success_count = 0
    error_count = 0
    
    for db_name in databases:
        try:
            init_payroll_schema(db_name)
            success_count += 1
        except Exception as e:
            print(f"Failed to initialize {db_name}: {e}")
            error_count += 1
        print()
    
    print("=" * 70)
    print(f"SUMMARY: {success_count} succeeded, {error_count} failed")
    print("=" * 70)


if __name__ == "__main__":
    main()
