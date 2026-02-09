r"""Reset superadmin password to #sh123. Run when login fails.
  python scripts/reset_superadmin_password.py
  Or: .\scripts\reset_password_in_docker.ps1 (from project root)
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

EMAIL = "shadmin@gmail.com"
NEW_PASSWORD = "#sh123"


def main():
    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
        user=DB_USER, password=DB_PASSWORD,
        cursor_factory=RealDictCursor,
    )
    hashed = bcrypt.hashpw(NEW_PASSWORD.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")
    cur = conn.cursor()
    cur.execute(
        "UPDATE users SET password = %s, updated_at = NOW() WHERE LOWER(email) = LOWER(%s) RETURNING id",
        (hashed, EMAIL),
    )
    row = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    if row:
        print(f"Password reset for {EMAIL}. You can now login with: {NEW_PASSWORD}")
    else:
        print("User not found. Run init_db first to create superadmin.")


if __name__ == "__main__":
    main()
