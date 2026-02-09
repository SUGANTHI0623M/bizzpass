"""Database connection and session."""
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from config.settings import settings


def get_connection(db_name: str | None = None):
    """Return a connection to PostgreSQL. Use db_name=None for settings.db_name."""
    name = db_name or settings.db_name
    return psycopg2.connect(
        host=settings.db_host,
        port=settings.db_port,
        dbname=name,
        user=settings.db_user,
        password=settings.db_password,
        cursor_factory=RealDictCursor,
    )


@contextmanager
def get_cursor(db_name: str | None = None, commit: bool = True):
    """Context manager for a connection and cursor. Commits on exit if commit=True."""
    conn = get_connection(db_name=db_name)
    try:
        cur = conn.cursor()
        yield cur
        if commit:
            conn.commit()
    finally:
        cur.close()
        conn.close()
