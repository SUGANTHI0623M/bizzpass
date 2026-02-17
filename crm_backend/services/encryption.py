"""Encryption for confidential integration credentials (Paysharp API key, etc.)."""
import base64
import os
from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


def _get_fernet_key() -> bytes:
    """Derive Fernet key from env or generate fallback for dev. In prod, set INTEGRATION_ENCRYPTION_KEY (32-byte key, base64url)."""
    key_b64 = os.environ.get("INTEGRATION_ENCRYPTION_KEY", "").strip()
    if key_b64:
        try:
            # Fernet needs 32 bytes, url-safe base64 encoded (44 chars)
            decoded = base64.urlsafe_b64decode(key_b64 + "=="[: (4 - len(key_b64) % 4) % 4])
            if len(decoded) >= 32:
                return base64.urlsafe_b64encode(decoded[:32])
        except Exception:
            pass
    # Fallback: derive from JWT_SECRET (use INTEGRATION_ENCRYPTION_KEY in production)
    secret = os.environ.get("JWT_SECRET", "bizzpass-dev-secret").encode()
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=b"bizzpass_integrations", iterations=100000)
    return base64.urlsafe_b64encode(kdf.derive(secret))


def encrypt_value(plain: str) -> str | None:
    """Encrypt a string. Returns base64-encoded ciphertext or None on error."""
    if not plain or not isinstance(plain, str):
        return None
    try:
        f = Fernet(_get_fernet_key())
        return f.encrypt(plain.encode()).decode()
    except Exception:
        return None


def decrypt_value(cipher: str) -> str | None:
    """Decrypt a base64-encoded ciphertext. Returns plaintext or None on error."""
    if not cipher or not isinstance(cipher, str):
        return None
    try:
        f = Fernet(_get_fernet_key())
        return f.decrypt(cipher.encode()).decode()
    except InvalidToken:
        return None
    except Exception:
        return None


def mask_secret(s: str, visible: int = 4) -> str:
    """Mask a secret for display: show last N chars, rest as ***"""
    if not s or len(s) <= visible:
        return "***" if s else ""
    return "***" + s[-visible:]
