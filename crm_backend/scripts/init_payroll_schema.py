"""
Initialize Payroll Schema - Run this script to add payroll tables to existing tenant databases
"""
import sys
import os

# Add parent directory to path to import config
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

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
    conn = psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname='postgres',
        user=settings.db_user,
        password=settings.db_password,
    )
    
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
    
    if not databases:
        print("No tenant databases found (bizzpass_c_*)")
        return
    
    print(f"Found {len(databases)} tenant database(s):")
    for db in databases:
        print(f"  - {db}")
    print()
    
    # Confirm
    response = input("Initialize payroll schema for all these databases? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
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
