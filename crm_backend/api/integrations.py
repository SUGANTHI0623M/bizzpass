"""Platform integrations API - Paysharp, Email (Super Admin only). Credentials stored encrypted."""
import json
import os

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_super_admin
from services.encryption import encrypt_value, decrypt_value, mask_secret

router = APIRouter(prefix="/integrations", tags=["integrations"])


def get_paysharp_config_decrypted():
    """Get decrypted Paysharp config for internal use (subscription service). Returns dict or None.
    Always reads from platform_integrations (DB) first. Env vars used only as fallback when DB has no config."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT config_encrypted FROM platform_integrations WHERE integration_key = %s",
            ("paysharp",),
        )
        row = cur.fetchone()

    if row and row.get("config_encrypted"):
        dec = decrypt_value(row["config_encrypted"])
        if dec:
            try:
                cfg = json.loads(dec)
                # API Token (secret_key) is the Bearer token; api_key fallback for backward compat
                bearer = (cfg.get("secret_key") or cfg.get("api_key") or cfg.get("token") or "").strip()
                if bearer:
                    return {
                        "api_key": bearer,
                        "secret_key": (cfg.get("secret_key") or "").strip() or None,
                        "merchant_id": (cfg.get("merchant_id") or "").strip() or None,
                        "sandbox": cfg.get("sandbox", True),
                        "api_base_url": (cfg.get("api_base_url") or "").strip() or None,
                    }
            except Exception:
                pass

    # Fallback: env vars (for local dev before integration is configured)
    api_key = os.environ.get("PAYSHARP_API_KEY", "").strip()
    secret = os.environ.get("PAYSHARP_SECRET", "").strip()
    token = os.environ.get("PAYSHARP_TOKEN", "").strip()
    if api_key or token:
        bearer = token or secret or api_key
        return {
            "api_key": bearer,
            "secret_key": secret or None,
            "merchant_id": os.environ.get("PAYSHARP_MERCHANT_ID", "").strip() or None,
            "sandbox": os.environ.get("PAYSHARP_SANDBOX", "false").lower() in ("1", "true", "yes"),
            "api_base_url": os.environ.get("PAYSHARP_API_BASE", "").strip() or None,
        }
    return None


def get_razorpay_config_decrypted():
    """Get decrypted Razorpay config. DB first, then env fallback."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT config_encrypted FROM platform_integrations WHERE integration_key = %s",
            ("razorpay",),
        )
        row = cur.fetchone()
    if row and row.get("config_encrypted"):
        dec = decrypt_value(row["config_encrypted"])
        if dec:
            try:
                cfg = json.loads(dec)
                key_id = (cfg.get("key_id") or "").strip()
                key_secret = (cfg.get("key_secret") or "").strip()
                if key_id and key_secret:
                    return {"key_id": key_id, "key_secret": key_secret}
            except Exception:
                pass
    key_id = os.environ.get("RAZORPAY_KEY_ID", "").strip()
    key_secret = os.environ.get("RAZORPAY_KEY_SECRET", "").strip()
    if key_id and key_secret:
        return {"key_id": key_id, "key_secret": key_secret}
    return None


def _ensure_table(cur):
    """Create platform_integrations if not exists."""
    cur.execute("""
        CREATE TABLE IF NOT EXISTS platform_integrations (
            id BIGSERIAL PRIMARY KEY,
            integration_key VARCHAR(64) NOT NULL UNIQUE,
            config_encrypted TEXT NULL,
            config_meta JSONB NULL,
            updated_by BIGINT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """)
    cur.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_platform_integrations_key ON platform_integrations(integration_key)"
    )


class PaysharpConfigBody(BaseModel):
    api_key: str  # Required for backward compat; API Token (secret_key) is primary Bearer
    secret_key: str | None = None  # API Token - primary Bearer credential; omit to keep existing
    merchant_id: str | None = None
    sandbox: bool = True
    api_base_url: str | None = None


class PaysharpConfigResponse(BaseModel):
    configured: bool
    api_key_masked: str | None = None
    api_key: str | None = None  # Full key when reveal=true
    secret_key: str | None = None  # Full secret when reveal=true
    merchant_id: str | None = None
    sandbox: bool = True
    api_base_url: str | None = None


@router.get("/paysharp", response_model=PaysharpConfigResponse)
def get_paysharp_config(
    reveal: bool = False,
    current_user: dict = Depends(get_current_super_admin),
):
    """Get Paysharp config. Super Admin only. Use ?reveal=true to include full api_key and secret_key in response."""
    with get_cursor() as cur:
        _ensure_table(cur)
        cur.execute(
            "SELECT config_encrypted, config_meta FROM platform_integrations WHERE integration_key = %s",
            ("paysharp",),
        )
        row = cur.fetchone()
    if not row or not row.get("config_encrypted"):
        return PaysharpConfigResponse(configured=False)
    api_enc = row.get("config_encrypted")
    dec = decrypt_value(api_enc)
    if not dec:
        return PaysharpConfigResponse(configured=False)
    try:
        cfg = json.loads(dec)
        api_key_val = cfg.get("api_key", "")
        return PaysharpConfigResponse(
            configured=True,
            api_key_masked=mask_secret(api_key_val, 4),
            api_key=api_key_val if reveal else None,
            secret_key=(cfg.get("secret_key") or "") if reveal else None,
            merchant_id=cfg.get("merchant_id"),
            sandbox=cfg.get("sandbox", True),
            api_base_url=cfg.get("api_base_url"),
        )
    except Exception:
        return PaysharpConfigResponse(configured=True, api_key_masked="***")


def _is_placeholder_secret(val: str | None) -> bool:
    if not val or not val.strip():
        return True
    s = val.strip()
    return s == "••••••••" or all(c == "•" for c in s)


class PayPalConfigBody(BaseModel):
    client_id: str
    client_secret: str


def get_paypal_config_decrypted():
    """Get decrypted PayPal config from DB."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT config_encrypted FROM platform_integrations WHERE integration_key = %s",
            ("paypal",),
        )
        row = cur.fetchone()
    if row and row.get("config_encrypted"):
        dec = decrypt_value(row["config_encrypted"])
        if dec:
            try:
                cfg = json.loads(dec)
                client_id = (cfg.get("client_id") or "").strip()
                client_secret = (cfg.get("client_secret") or "").strip()
                if client_id and client_secret:
                    return {"client_id": client_id, "client_secret": client_secret}
            except Exception:
                pass
    return None


@router.get("/paypal")
def get_paypal_config(
    reveal: bool = False,
    current_user: dict = Depends(get_current_super_admin),
):
    """Get PayPal config status. Use ?reveal=true to get full client_id and client_secret in response."""
    with get_cursor() as cur:
        _ensure_table(cur)
        cur.execute(
            "SELECT config_encrypted FROM platform_integrations WHERE integration_key = %s",
            ("paypal",),
        )
        row = cur.fetchone()
    if not row or not row.get("config_encrypted"):
        return {"configured": False}
    dec = decrypt_value(row["config_encrypted"])
    if not dec:
        return {"configured": False}
    try:
        cfg = json.loads(dec)
        client_id = cfg.get("client_id") or ""
        client_secret = cfg.get("client_secret") or ""
        if not client_id:
            return {"configured": False}
        result = {
            "configured": True,
            "client_id_masked": mask_secret(client_id, 4) if client_id else None,
            "client_id": client_id if reveal else None,
            "client_secret": client_secret if reveal else None,
        }
        return result
    except Exception:
        return {"configured": False}


@router.put("/paypal")
def save_paypal_config(
    body: PayPalConfigBody,
    current_user: dict = Depends(get_current_super_admin),
):
    """Save PayPal config (encrypted in DB). For PayPal Checkout payments."""
    client_id = (body.client_id or "").strip()
    client_secret = (body.client_secret or "").strip()
    if not client_id or not client_secret:
        raise HTTPException(status_code=400, detail="Client ID and Client Secret are required")
    cfg = json.dumps({"client_id": client_id, "client_secret": client_secret})
    encrypted = encrypt_value(cfg)
    if not encrypted:
        raise HTTPException(status_code=500, detail="Failed to encrypt credentials")
    with get_cursor() as cur:
        _ensure_table(cur)
        cur.execute(
            """
            INSERT INTO platform_integrations (integration_key, config_encrypted, config_meta, updated_by, updated_at)
            VALUES (%s, %s, '{}'::jsonb, %s, NOW())
            ON CONFLICT (integration_key) DO UPDATE SET
                config_encrypted = EXCLUDED.config_encrypted,
                updated_by = EXCLUDED.updated_by,
                updated_at = NOW()
            """,
            ("paypal", encrypted, current_user.get("id")),
        )
    return {"ok": True, "message": "PayPal configuration saved"}


@router.put("/paysharp")
def save_paysharp_config(
    body: PaysharpConfigBody,
    current_user: dict = Depends(get_current_super_admin),
):
    """Save Paysharp config (encrypted in DB). Super Admin only. API Token (secret_key) is primary Bearer. Omit to keep existing."""
    api_key = (body.api_key or "").strip()
    secret_key = (body.secret_key or "").strip() if body.secret_key else ""
    if _is_placeholder_secret(secret_key):
        secret_key = None  # keep existing
    existing = get_paysharp_config_decrypted()
    if secret_key is None:
        if existing:
            secret_key = existing.get("secret_key") or ""
        else:
            raise HTTPException(status_code=400, detail="API Token is required for initial setup")
    # API Token (secret_key) is primary; api_key can be same or from API Key field
    if not api_key and secret_key:
        api_key = secret_key
    if not api_key:
        raise HTTPException(status_code=400, detail="API Key or API Token is required")
    cfg = {
        "api_key": api_key,
        "secret_key": secret_key or "",
        "merchant_id": (body.merchant_id or "").strip() or None,
        "sandbox": body.sandbox,
        "api_base_url": (body.api_base_url or "").strip() or None,
    }
    plain = json.dumps(cfg)
    encrypted = encrypt_value(plain)
    if not encrypted:
        raise HTTPException(status_code=500, detail="Failed to encrypt credentials")
    with get_cursor() as cur:
        _ensure_table(cur)
        meta = {"sandbox": body.sandbox}
        cur.execute(
            """
            INSERT INTO platform_integrations (integration_key, config_encrypted, config_meta, updated_by, updated_at)
            VALUES (%s, %s, %s::jsonb, %s, NOW())
            ON CONFLICT (integration_key) DO UPDATE SET
                config_encrypted = EXCLUDED.config_encrypted,
                config_meta = EXCLUDED.config_meta,
                updated_by = EXCLUDED.updated_by,
                updated_at = NOW()
            """,
            ("paysharp", encrypted, '{"sandbox": ' + str(body.sandbox).lower() + "}", current_user.get("id")),
        )
    return {"ok": True, "message": "Paysharp configuration saved securely"}
