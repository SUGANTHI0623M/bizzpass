"""Application settings loaded from environment."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """CRM backend settings."""

    # Database (defaults match docker-compose postgres)
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "bizzpass"
    db_user: str = "dev"
    db_password: str = "dev1234"

    # Auth
    jwt_secret: str = "bizzpass-crm-secret-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 30

    # Integrations - encryption key for Paysharp/Email secrets (32 bytes base64)
    integration_encryption_key: str = ""

    # Cloudinary
    cloudinary_cloud_name: str = "dyi7xoqhy"
    cloudinary_api_key: str = "587679965546116"
    cloudinary_api_secret: str = "SnmyCwCyL1rjiMMGlmOeR7kHttI"

    @property
    def database_url(self) -> str:
        """PostgreSQL URL for async/sync usage (no driver in path for psycopg2)."""
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def database_url_default_db(self) -> str:
        """Connect to default 'postgres' DB for creating bizzpass if needed."""
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/postgres"
        )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
