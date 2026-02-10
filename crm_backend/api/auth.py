"""Auth routes: login (superadmin and company admin), JWT."""
from datetime import datetime, timedelta
from typing import Annotated

import bcrypt
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from pydantic import BaseModel

from config.settings import settings
from config.database import get_cursor

router = APIRouter(prefix="/auth", tags=["auth"])
security = HTTPBearer(auto_error=False)


class LoginRequest(BaseModel):
    """identifier: license key, email, or phone. Accept 'identifier' or 'email' for compatibility."""
    identifier: str | None = None
    email: str | None = None
    password: str


class LoginResponse(BaseModel):
    token: str
    user: dict


def verify_password(plain: str, hashed: str) -> bool:
    if not hashed:
        return False
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


def create_token(
    user_id: int,
    email: str,
    role: str,
    company_id: int | None = None,
    permissions: list[str] | None = None,
) -> str:
    expire = datetime.utcnow() + timedelta(days=settings.jwt_expire_days)
    payload = {"sub": str(user_id), "email": email, "role": role, "exp": expire}
    if company_id is not None:
        payload["company_id"] = company_id
    if permissions:
        payload["permissions"] = permissions
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest):
    """Login with license key, email, or phone + password. Super Admin bypasses RBAC. Company Admin requires valid license."""
    identifier = (body.identifier or body.email or "").strip()
    if not identifier or not body.password:
        raise HTTPException(status_code=400, detail="License key, email or phone, and password are required")

    row = None
    # 1) Try license key -> resolve to company admin user
    with get_cursor() as cur:
        cur.execute(
            "SELECT company_id FROM licenses WHERE license_key = %s AND company_id IS NOT NULL LIMIT 1",
            (identifier,),
        )
        lic = cur.fetchone()
        if lic:
            company_id_bigint = lic["company_id"]
            cur.execute(
                """
                SELECT id, name, email, password, role, is_super_admin, company_id_bigint, rbac_role_id
                FROM users
                WHERE company_id_bigint = %s AND is_active IS NOT DISTINCT FROM TRUE
                ORDER BY id
                LIMIT 1
                """,
                (company_id_bigint,),
            )
            row = cur.fetchone()

    # 2) Try email
    if not row:
        with get_cursor() as cur:
            cur.execute(
                """
                SELECT id, name, email, password, role, is_super_admin, company_id_bigint, rbac_role_id
                FROM users
                WHERE LOWER(email) = LOWER(%s) AND is_active IS NOT DISTINCT FROM TRUE
                """,
                (identifier,),
            )
            row = cur.fetchone()

    # 3) Try phone
    if not row:
        with get_cursor() as cur:
            cur.execute(
                """
                SELECT id, name, email, password, role, is_super_admin, company_id_bigint, rbac_role_id
                FROM users
                WHERE TRIM(COALESCE(phone, '')) = %s AND is_active IS NOT DISTINCT FROM TRUE
                """,
                (identifier.strip(),),
            )
            row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=401, detail="Invalid license key, email or phone, or password")

    hashed = row.get("password") or ""
    if not verify_password(body.password, hashed):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    user_id = row["id"]
    role_raw = (row.get("role") or "").lower()
    is_super_admin = bool(row.get("is_super_admin"))
    company_id_bigint = row.get("company_id_bigint")

    # Super Admin path — unchanged, bypasses RBAC
    if is_super_admin or (("super" in role_raw or role_raw == "super_admin") and not company_id_bigint):
        role = "super_admin"
        token = create_token(user_id, row["email"], role)
        user = {
            "id": user_id,
            "name": row.get("name") or "Super Admin",
            "email": row.get("email"),
            "role": role,
            "company_id": None,
            "permissions": None,
        }
        try:
            with get_cursor() as cur:
                cur.execute("UPDATE users SET last_login = NOW() WHERE id = %s", (user_id,))
        except Exception:
            pass
        _audit_log(user_id, None, "login", "user", str(user_id))
        return LoginResponse(token=token, user=user)

    # Company Admin / RBAC user path
    if not company_id_bigint:
        raise HTTPException(status_code=403, detail="Access denied. Contact your administrator.")

    # Validate license for company
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.status, l.valid_until, c.name AS company_name
            FROM licenses l
            JOIN companies c ON c.id = l.company_id
            WHERE c.id = %s
            """,
            (company_id_bigint,),
        )
        lic = cur.fetchone()

    if not lic:
        raise HTTPException(status_code=403, detail="Company license not found. Contact support.")

    status = (lic.get("status") or "").lower()
    if status in ("expired", "revoked", "suspended"):
        raise HTTPException(
            status_code=403,
            detail="License is expired or suspended. Please renew your subscription.",
        )

    valid_until = lic.get("valid_until")
    if valid_until and datetime.now().date() > valid_until:
        raise HTTPException(status_code=403, detail="License has expired. Please renew.")

    # Fetch permissions for user's role
    rbac_role_id = row.get("rbac_role_id")
    permissions: list[str] = []
    if rbac_role_id:
        with get_cursor() as cur:
            cur.execute(
                """
                SELECT p.code
                FROM rbac_permissions p
                JOIN rbac_role_permissions rp ON rp.permission_id = p.id
                WHERE rp.role_id = %s
                """,
                (rbac_role_id,),
            )
            permissions = [r["code"] for r in cur.fetchall()]

    role = role_raw or "company_admin"
    token = create_token(
        user_id, row["email"], role,
        company_id=company_id_bigint,
        permissions=permissions if permissions else None,
    )
    user = {
        "id": user_id,
        "name": row.get("name") or "Admin",
        "email": row.get("email"),
        "role": role,
        "company_id": company_id_bigint,
        "company_name": lic.get("company_name"),
        "permissions": permissions,
    }
    try:
        with get_cursor() as cur:
            cur.execute("UPDATE users SET last_login = NOW() WHERE id = %s", (user_id,))
    except Exception:
        pass
    _audit_log(user_id, company_id_bigint, "login", "user", str(user_id))
    return LoginResponse(token=token, user=user)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> dict:
    """Validate JWT and return user payload. Use as FastAPI Depends()."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        user = {
            "id": int(payload["sub"]),
            "email": payload.get("email"),
            "role": payload.get("role", "super_admin"),
        }
        if "company_id" in payload:
            user["company_id"] = payload["company_id"]
        if "permissions" in payload:
            user["permissions"] = payload["permissions"]
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


@router.get("/me")
def get_me(current_user: dict = Depends(get_current_user)):
    """Return current user info from JWT. Used by both Super Admin and Company Admin."""
    return {"user": current_user}


def get_current_super_admin(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Require Super Admin role. Use for CRM-only routes. Company Admin gets 403."""
    role = (current_user.get("role") or "").lower()
    if role == "super_admin" and not current_user.get("company_id"):
        return current_user
    raise HTTPException(
        status_code=403,
        detail="This portal is for Super Administrators only. Use the Company Portal for company access.",
    )


def get_current_company_admin(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Require Company Admin role. Use for company-specific routes."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(
            status_code=403,
            detail="This requires a company admin account.",
        )
    return current_user


def require_permission(permission: str):
    """Dependency factory: require specific RBAC permission. Super Admin bypasses."""

    def _check(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        role = (current_user.get("role") or "").lower()
        if role == "super_admin" and not current_user.get("company_id"):
            return current_user
        perms = current_user.get("permissions") or []
        if permission in perms:
            return current_user
        raise HTTPException(status_code=403, detail=f"Permission required: {permission}")

    return _check


def require_any_permission(*permissions: str):
    """Dependency factory: require at least one of the given RBAC permissions. Super Admin bypasses."""

    def _check(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        role = (current_user.get("role") or "").lower()
        if role == "super_admin" and not current_user.get("company_id"):
            return current_user
        perms = current_user.get("permissions") or []
        if any(p in perms for p in permissions):
            return current_user
        raise HTTPException(status_code=403, detail=f"One of these permissions required: {', '.join(permissions)}")

    return _check


def _audit_log(user_id: int | None, company_id: int | None, action: str, entity_type: str | None = None, entity_id: str | None = None):
    """Write to audit_logs if table exists."""
    try:
        with get_cursor() as cur:
            cur.execute(
                """
                INSERT INTO audit_logs (user_id, company_id, action, entity_type, entity_id, created_at)
                VALUES (%s, %s, %s, %s, %s, NOW())
                """,
                (user_id, company_id, action, entity_type, entity_id),
            )
    except Exception:
        pass
