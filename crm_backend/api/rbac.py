"""RBAC: permission checks. Super Admin bypasses all."""
from fastapi import HTTPException, Depends
from typing import Annotated

from api.auth import get_current_user


def require_permission(permission: str):
    """Dependency: require specific permission. Super Admin bypasses."""

    def _check(current_user: Annotated[dict, Depends(get_current_user)]) -> dict:
        role = (current_user.get("role") or "").lower()
        if role == "super_admin":
            return current_user
        perms = current_user.get("permissions") or []
        if permission in perms:
            return current_user
        raise HTTPException(status_code=403, detail=f"Permission required: {permission}")

    return _check


def require_company_admin(current_user: Annotated[dict, Depends(get_current_user)]) -> dict:
    """Dependency: require company-scoped user (admin or RBAC). Super Admin bypasses."""
    role = (current_user.get("role") or "").lower()
    if role == "super_admin":
        return current_user
    if current_user.get("company_id") is None:
        raise HTTPException(status_code=403, detail="Company context required")
    return current_user
