"""
Provision a separate PostgreSQL database for each company.
Called when a company is created. Does not affect existing CRM features;
all CRM APIs continue to use the main database.
"""
from pathlib import Path

import psycopg2
from psycopg2.extras import RealDictCursor

from config.settings import settings


# Database name prefix for company DBs: bizzpass_c_<company_id>
# Only digits allowed in company_id (from API), so safe for identifier.
DB_NAME_PREFIX = "bizzpass_c_"


def _company_db_name(company_id: int) -> str:
    """Return the database name for a company (safe, no user input)."""
    if not isinstance(company_id, int) or company_id < 1:
        raise ValueError("company_id must be a positive integer")
    return f"{DB_NAME_PREFIX}{company_id}"


def _get_connection_to_db(db_name: str):
    """Connect to a specific database (no cursor factory for DDL)."""
    return psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname=db_name,
        user=settings.db_user,
        password=settings.db_password,
    )


def _load_tenant_schema_sql() -> str:
    """Load tenant_schema.sql from the schema package."""
    schema_dir = Path(__file__).resolve().parent.parent / "schema"
    path = schema_dir / "tenant_schema.sql"
    if not path.exists():
        raise FileNotFoundError(f"Tenant schema not found: {path}")
    return path.read_text(encoding="utf-8")


def _split_sql_statements(sql: str) -> list[str]:
    """Split SQL into single statements (by semicolon at line end), skip comments and empty."""
    statements = []
    current = []
    for line in sql.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("--"):
            continue
        current.append(line)
        if stripped.endswith(";"):
            stmt = "\n".join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
    if current:
        stmt = "\n".join(current).strip()
        if stmt:
            statements.append(stmt)
    return statements


def create_company_database(company_id: int) -> str:
    """
    Create a new database for the company and run the tenant schema.
    Requires the DB user to have CREATEDB privilege (e.g. in Docker: postgres user or dev with CREATEDB).

    :param company_id: Company ID (from main DB companies table).
    :return: The name of the created database (e.g. bizzpass_c_123).
    :raises RuntimeError: If database creation or schema application fails.
    """
    db_name = _company_db_name(company_id)

    # Connect to default 'postgres' DB to run CREATE DATABASE (must be outside transaction)
    conn_main = psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname="postgres",
        user=settings.db_user,
        password=settings.db_password,
    )
    conn_main.autocommit = True
    try:
        cur = conn_main.cursor()
        # Avoid error if DB already exists (e.g. retry)
        cur.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_name,),
        )
        if cur.fetchone():
            cur.close()
            return db_name
        # PostgreSQL identifiers: use parameter for safety; CREATE DATABASE doesn't support %s for name
        # So we use a safe name built from integer only
        cur.execute(f'CREATE DATABASE "{db_name}"')
        cur.close()
    finally:
        conn_main.close()

    # Apply tenant schema on the new database (one statement at a time)
    sql = _load_tenant_schema_sql()
    statements = _split_sql_statements(sql)
    conn_tenant = _get_connection_to_db(db_name)
    try:
        conn_tenant.autocommit = True
        cur = conn_tenant.cursor()
        for stmt in statements:
            if stmt.strip():
                cur.execute(stmt)
        cur.close()
    except Exception as e:
        conn_tenant.close()
        raise RuntimeError(f"Failed to apply tenant schema to {db_name}: {e}") from e
    finally:
        conn_tenant.close()

    return db_name
