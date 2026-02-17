"""Licenses API - list, create, manage."""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_super_admin

router = APIRouter(prefix="/licenses", tags=["licenses"])


class LicenseCreate(BaseModel):
    subscription_plan: str  # starter, professional, enterprise, basic
    max_users: int | None = None  # If None, use plan's max_users
    max_branches: int | None = None  # If None, use plan's max_branches
    is_trial: bool = False
    notes: str | None = None


def _license_row(row, company_name: str | None) -> dict:
    return {
        "id": row["id"],
        "licenseKey": row["license_key"],
        "company": company_name,
        "plan": row.get("plan_name") or row.get("plan_code", "").title(),
        "maxUsers": row.get("max_users", 0),
        "maxBranches": row.get("max_branches") if row.get("max_branches") is not None else 1,
        "status": row.get("status", "unassigned"),
        "validFrom": (row.get("valid_from") or "").__str__()[:10] if row.get("valid_from") else None,
        "validUntil": (row.get("valid_until") or "").__str__()[:10] if row.get("valid_until") else None,
        "isTrial": bool(row.get("is_trial", False)),
    }


@router.get("")
def list_licenses(
    search: str | None = None,
    tab: str = "all",
    current_user: dict = Depends(get_current_super_admin),
):
    """List licenses with optional search and filter."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.license_key, l.company_id, l.max_users, l.max_branches,
                   l.status, l.valid_from, l.valid_until, l.is_trial,
                   sp.plan_name, sp.plan_code,
                   c.name AS company_name
            FROM licenses l
            JOIN subscription_plans sp ON sp.id = l.plan_id
            LEFT JOIN companies c ON c.id = l.company_id
            ORDER BY l.created_at DESC
            """
        )
        rows = cur.fetchall()

    licenses = []
    for r in rows:
        licenses.append(_license_row(r, (r.get("company_name") or "").strip() or None))

    if search:
        s = search.lower()
        licenses = [
            l
            for l in licenses
            if (l["licenseKey"] or "").lower().find(s) >= 0 or ((l["company"] or "") or "").lower().find(s) >= 0
        ]
    if tab == "active":
        licenses = [l for l in licenses if l["status"] == "active"]
    elif tab == "expired":
        licenses = [l for l in licenses if l["status"] == "expired"]
    elif tab == "unassigned":
        licenses = [l for l in licenses if l["status"] == "unassigned"]
    elif tab == "suspended":
        licenses = [l for l in licenses if l["status"] in ("suspended", "revoked")]

    return {"licenses": licenses}


@router.post("")
def create_license(
    body: LicenseCreate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Create a new license."""
    plan_code = body.subscription_plan.lower().replace(" ", "_").strip()
    if plan_code == "pro":
        plan_code = "professional"
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, plan_name, max_users, max_branches FROM subscription_plans WHERE (plan_code = %s OR plan_name ILIKE %s) AND is_active LIMIT 1",
            (plan_code, "%" + body.subscription_plan + "%"),
        )
        plan = cur.fetchone()
    if not plan:
        raise HTTPException(status_code=400, detail=f"Plan '{body.subscription_plan}' not found")

    # Use plan's max_users/max_branches when not explicitly provided
    max_users = body.max_users if body.max_users is not None else (plan.get("max_users") or 30)
    max_branches = body.max_branches if body.max_branches is not None else (plan.get("max_branches") or 1)

    import uuid
    license_key = f"BP-{plan_code[:3].upper()}-{str(uuid.uuid4())[:8].upper()}"

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO licenses (license_key, plan_id, max_users, max_branches, is_trial, notes, created_by, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'unassigned')
            RETURNING id, license_key, plan_id, max_users, max_branches, status, valid_from, valid_until, is_trial
            """,
            (license_key, plan["id"], max_users, max_branches, body.is_trial, body.notes or "", current_user["id"]),
        )
        row = cur.fetchone()

    return _license_row({**dict(row), "plan_name": plan["plan_name"], "plan_code": plan_code}, None)


@router.get("/{license_id}")
def get_license(
    license_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Get a single license by ID."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.license_key, l.company_id, l.max_users, l.max_branches,
                   l.status, l.valid_from, l.valid_until, l.is_trial,
                   sp.plan_name, sp.plan_code,
                   c.name AS company_name
            FROM licenses l
            JOIN subscription_plans sp ON sp.id = l.plan_id
            LEFT JOIN companies c ON c.id = l.company_id
            WHERE l.id = %s
            """,
            (license_id,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="License not found")
    return _license_row(row, (row.get("company_name") or "").strip() or None)


class LicenseUpdate(BaseModel):
    max_users: int | None = None
    max_branches: int | None = None
    status: str | None = None  # active / suspended / revoked / unassigned
    notes: str | None = None


@router.patch("/{license_id}")
def update_license(
    license_id: int,
    body: LicenseUpdate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Update a license (max_users, max_branches, status, notes)."""
    updates = []
    vals = []
    if body.max_users is not None:
        updates.append("max_users = %s")
        vals.append(body.max_users)
    if body.max_branches is not None:
        updates.append("max_branches = %s")
        vals.append(body.max_branches)
    if body.notes is not None:
        updates.append("notes = %s")
        vals.append(body.notes)
    if body.status is not None:
        status = body.status.lower()
        if status not in ("active", "suspended", "revoked", "unassigned", "expired"):
            raise HTTPException(status_code=400, detail="Invalid status")
        updates.append("status = %s")
        vals.append(status)
        if status == "suspended":
            updates.append("suspended_at = NOW()")
        elif status == "revoked":
            updates.append("revoked_at = NOW()")
    if not updates:
        return get_license(license_id, current_user)
    vals.append(license_id)
    with get_cursor() as cur:
        cur.execute(
            f"UPDATE licenses SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
            vals,
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="License not found")
    return get_license(license_id, current_user)


@router.delete("/{license_id}")
def delete_license(
    license_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Revoke a license (set status to revoked). Does not remove from DB."""
    with get_cursor() as cur:
        cur.execute(
            "UPDATE licenses SET status = 'revoked', revoked_at = NOW(), updated_at = NOW() WHERE id = %s",
            (license_id,),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="License not found")
    return {"ok": True}
