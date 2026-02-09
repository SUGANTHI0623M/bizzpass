"""
Standalone DB init: only needs psycopg2-binary and bcrypt.
  pip install psycopg2-binary bcrypt
  python crm_backend/scripts/init_db_standalone.py
Uses env vars DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD or docker-compose defaults.
"""
import os
import re
import sys
from pathlib import Path

# No config/settings - only psycopg2 and bcrypt
import psycopg2
from psycopg2.extras import RealDictCursor

ROOT = Path(__file__).resolve().parent.parent
REPO_ROOT = ROOT.parent

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ.get("DB_NAME", "bizzpass")
DB_USER = os.environ.get("DB_USER", "dev")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "dev1234")

SUPERADMIN_EMAIL = "shadmin@gmail.com"
SUPERADMIN_PASSWORD = "#sh123"
SUPERADMIN_NAME = "Super Admin"


def connect(db_name=None):
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=db_name or DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        cursor_factory=RealDictCursor,
    )


def create_database_if_not_exists():
    conn = connect("postgres")
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_NAME,))
    if cur.fetchone():
        print(f"Database '{DB_NAME}' already exists.")
    else:
        cur.execute(f'CREATE DATABASE "{DB_NAME}"')
        print(f"Created database '{DB_NAME}'.")
    cur.close()
    conn.close()


def schema_already_applied(cur):
    cur.execute(
        "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users'"
    )
    return cur.fetchone() is not None


def run_schema(cur):
    schema_path = REPO_ROOT / "postgres_schema.sql"
    if not schema_path.exists():
        raise FileNotFoundError(f"Schema file not found: {schema_path}")
    sql = schema_path.read_text(encoding="utf-8")
    sql = sql.replace("CREATE TABLE ", "CREATE TABLE IF NOT EXISTS ")
    sql = sql.replace("CREATE INDEX ", "CREATE INDEX IF NOT EXISTS ")
    sql = sql.replace("CREATE INDEX IF NOT EXISTS IF NOT EXISTS ", "CREATE INDEX IF NOT EXISTS ")
    # Remove block comments /* ... */ (single-line or multi-line)
    sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    parts = re.split(r";\s*\n", sql)
    for p in parts:
        # Strip full-line comments so we don't skip statements that start with comment
        lines = [line for line in p.split("\n") if line.strip() and not line.strip().startswith("--")]
        stmt = "\n".join(lines).strip()
        if not stmt or stmt == ";":
            continue
        if not stmt.endswith(";"):
            stmt += ";"
        try:
            cur.execute(stmt)
        except Exception as e:
            if "already exists" in str(e).lower():
                continue
            raise
    print("Schema applied.")


def seed_superadmin(cur):
    try:
        import bcrypt
    except ImportError:
        print("Install bcrypt: pip install bcrypt")
        sys.exit(1)
    cur.execute("SELECT id FROM users WHERE LOWER(email) = LOWER(%s)", (SUPERADMIN_EMAIL,))
    if cur.fetchone():
        print("Superadmin user already exists.")
        return
    hashed = bcrypt.hashpw(
        SUPERADMIN_PASSWORD.encode("utf-8"),
        bcrypt.gensalt(rounds=12),
    ).decode("utf-8")
    cur.execute(
        """
        INSERT INTO users (name, email, password, role, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, 'super_admin', TRUE, NOW(), NOW())
        RETURNING id
        """,
        (SUPERADMIN_NAME, SUPERADMIN_EMAIL.lower(), hashed),
    )
    row = cur.fetchone()
    try:
        cur.execute(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN NOT NULL DEFAULT FALSE"
        )
        cur.execute("UPDATE users SET is_super_admin = TRUE WHERE id = %s", (row["id"],))
    except Exception:
        pass
    print("Superadmin user created: shadmin@gmail.com / #sh123")


def main():
    create_database_if_not_exists()
    conn = connect()
    conn.autocommit = False
    cur = conn.cursor()
    try:
        if not schema_already_applied(cur):
            run_schema(cur)
            conn.commit()
        else:
            print("Schema already applied (users table exists).")
        seed_superadmin(cur)
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()
    print("Init done.")


if __name__ == "__main__":
    main()
