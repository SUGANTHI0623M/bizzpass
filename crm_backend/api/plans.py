"""Subscription plans API - full CRUD, search, filter."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_super_admin

router = APIRouter(prefix="/plans", tags=["plans"])


def _plan_row(r) -> dict:
    mb = r.get("max_branches")
    return {
        "id": r["id"],
        "planCode": r.get("plan_code", ""),
        "planName": r.get("plan_name", ""),
        "description": r.get("description") or "",
        "price": int(float(r.get("price", 0))),
        "currency": r.get("currency", "INR"),
        "durationMonths": r.get("duration_months", 12),
        "maxUsers": r.get("max_users", 0),
        "maxBranches": str(mb) if mb is not None else "Unlimited",
        "features": r.get("features") if isinstance(r.get("features"), list) else [],
        "trialDays": r.get("trial_days", 0),
        "isActive": bool(r.get("is_active", True)),
    }


class PlanCreate(BaseModel):
    plan_code: str
    plan_name: str
    description: str | None = None
    price: float
    currency: str = "INR"
    duration_months: int = 12
    max_users: int = 30
    max_branches: int | None = None
    features: list[str] | None = None
    trial_days: int = 0
    is_active: bool = True


class PlanUpdate(BaseModel):
    plan_name: str | None = None
    description: str | None = None
    price: float | None = None
    currency: str | None = None
    duration_months: int | None = None
    max_users: int | None = None
    max_branches: int | None = None
    features: list[str] | None = None
    trial_days: int | None = None
    is_active: bool | None = None


# create_plan is registered in main.py as POST /plans/create so it always works
def create_plan(
    body: PlanCreate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Create a new subscription plan."""
    plan_code = (body.plan_code or "").strip().lower().replace(" ", "_") or "plan"
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM subscription_plans WHERE plan_code = %s",
            (plan_code,),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Plan code already exists")
        cur.execute(
            """
            INSERT INTO subscription_plans (
                plan_code, plan_name, description, price, currency, duration_months,
                max_users, max_branches, features, trial_days, is_active, created_at, updated_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            RETURNING id, plan_code, plan_name, description, price, currency, duration_months,
                      max_users, max_branches, features, trial_days, is_active
            """,
            (
                plan_code,
                (body.plan_name or "").strip() or plan_code.title(),
                (body.description or "").strip() or None,
                body.price,
                body.currency or "INR",
                body.duration_months,
                body.max_users,
                body.max_branches,
                body.features,
                body.trial_days,
                body.is_active,
            ),
        )
        row = cur.fetchone()
    return _plan_row(row)


@router.get("")
@router.get("/")
def list_plans(
    search: str | None = None,
    active_only: bool = True,
    current_user: dict = Depends(get_current_super_admin),
):
    """List subscription plans with optional search and active filter."""
    with get_cursor() as cur:
        sql = """
            SELECT id, plan_code, plan_name, description, price, currency, duration_months,
                   max_users, max_branches, features, trial_days, is_active
            FROM subscription_plans
            WHERE 1=1
        """
        params = []
        if active_only:
            sql += " AND is_active = TRUE"
        sql += " ORDER BY price ASC"
        cur.execute(sql, params)
        rows = cur.fetchall()

    plans = [_plan_row(r) for r in rows]
    if search and search.strip():
        s = search.lower()
        plans = [
            p
            for p in plans
            if s in (p.get("planCode") or "").lower() or s in (p.get("planName") or "").lower()
        ]
    return {"plans": plans}


@router.get("/{plan_id}")
def get_plan(
    plan_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Get a single plan by ID."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT id, plan_code, plan_name, description, price, currency, duration_months,
                   max_users, max_branches, features, trial_days, is_active
            FROM subscription_plans
            WHERE id = %s
            """,
            (plan_id,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Plan not found")
    return _plan_row(row)


@router.patch("/{plan_id}")
def update_plan(
    plan_id: int,
    body: PlanUpdate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Update a subscription plan."""
    updates = []
    vals = []
    if body.plan_name is not None:
        updates.append("plan_name = %s")
        vals.append(body.plan_name.strip())
    if body.description is not None:
        updates.append("description = %s")
        vals.append(body.description.strip() or None)
    if body.price is not None:
        updates.append("price = %s")
        vals.append(body.price)
    if body.currency is not None:
        updates.append("currency = %s")
        vals.append(body.currency)
    if body.duration_months is not None:
        updates.append("duration_months = %s")
        vals.append(body.duration_months)
    if body.max_users is not None:
        updates.append("max_users = %s")
        vals.append(body.max_users)
    if body.max_branches is not None:
        updates.append("max_branches = %s")
        vals.append(body.max_branches)
    if body.features is not None:
        updates.append("features = %s")
        vals.append(body.features)
    if body.trial_days is not None:
        updates.append("trial_days = %s")
        vals.append(body.trial_days)
    if body.is_active is not None:
        updates.append("is_active = %s")
        vals.append(body.is_active)
    if not updates:
        return get_plan(plan_id, current_user)
    vals.append(plan_id)
    with get_cursor() as cur:
        cur.execute(
            f"UPDATE subscription_plans SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
            vals,
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Plan not found")
    return get_plan(plan_id, current_user)


@router.delete("/{plan_id}")
def delete_plan(
    plan_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Deactivate a plan (soft delete: set is_active = false)."""
    with get_cursor() as cur:
        cur.execute(
            "UPDATE subscription_plans SET is_active = FALSE, updated_at = NOW() WHERE id = %s",
            (plan_id,),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Plan not found")
    return {"ok": True}
