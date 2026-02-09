"""Subscription & Billing API for Company Portal. Current subscription, available plans, initiate payment (PaySharp placeholder)."""
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission

router = APIRouter(prefix="/subscription", tags=["subscription"])


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


@router.get("/current")
def get_current_subscription(
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """Return current company subscription: license, plan, expiry, usage. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id AS license_id, l.license_key, l.status AS license_status,
                   l.valid_from, l.valid_until, l.max_users, l.max_branches,
                   sp.id AS plan_id, sp.plan_code, sp.plan_name, sp.description,
                   sp.price, sp.currency, sp.duration_months, sp.max_users AS plan_max_users,
                   sp.max_branches AS plan_max_branches, sp.features
            FROM licenses l
            JOIN subscription_plans sp ON sp.id = l.plan_id
            WHERE l.company_id = %s
            LIMIT 1
            """,
            (company_id,),
        )
        row = cur.fetchone()

    if not row:
        return {
            "hasSubscription": False,
            "licenseId": None,
            "licenseKey": None,
            "licenseStatus": None,
            "plan": None,
            "validFrom": None,
            "validUntil": None,
            "currentStaff": 0,
            "currentBranches": 0,
            "maxStaff": None,
            "maxBranches": None,
            "daysRemaining": None,
        }

    valid_until = row.get("valid_until")
    today = date.today()
    days_remaining = None
    if valid_until:
        delta = (valid_until - today).days
        days_remaining = max(0, delta) if delta is not None else None

    status = (row.get("license_status") or "").lower()
    if status == "active" and valid_until and today > valid_until:
        status = "expired"

    with get_cursor() as cur2:
        cur2.execute("SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s", (company_id,))
        staff_row = cur2.fetchone()
        cur2.execute("SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s", (company_id,))
        branch_row = cur2.fetchone()

    current_staff = (staff_row or {}).get("cnt") or 0
    current_branches = (branch_row or {}).get("cnt") or 0

    plan = _plan_row(row)
    return {
        "hasSubscription": True,
        "licenseId": row["license_id"],
        "licenseKey": row.get("license_key"),
        "licenseStatus": status,
        "plan": plan,
        "validFrom": row.get("valid_from").isoformat() if row.get("valid_from") else None,
        "validUntil": valid_until.isoformat() if valid_until else None,
        "currentStaff": current_staff,
        "currentBranches": current_branches,
        "maxStaff": row.get("max_users"),
        "maxBranches": row.get("max_branches"),
        "daysRemaining": days_remaining,
    }


@router.get("/plans")
def list_plans_for_subscription(
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """List active subscription plans (for company to choose when subscribing/renewing). Company Admin only."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT id, plan_code, plan_name, description, price, currency, duration_months,
                   max_users, max_branches, features, trial_days, is_active
            FROM subscription_plans
            WHERE is_active = TRUE
            ORDER BY price ASC
            """
        )
        rows = cur.fetchall()
    return {"plans": [_plan_row(r) for r in rows]}


class InitiateSubscriptionBody(BaseModel):
    plan_id: int
    duration_months: int = 12


@router.post("/initiate")
def initiate_subscription(
    body: InitiateSubscriptionBody,
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """
    Start a subscription/renewal for the given plan. Creates a pending payment record and returns
    PaySharp checkout URL when key is configured. Company Admin only.
    """
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    if body.duration_months < 1 or body.duration_months > 24:
        raise HTTPException(status_code=400, detail="duration_months must be between 1 and 24")

    with get_cursor() as cur:
        cur.execute(
            "SELECT id, plan_name, price, currency FROM subscription_plans WHERE id = %s AND is_active = TRUE",
            (body.plan_id,),
        )
        plan = cur.fetchone()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM licenses WHERE company_id = %s LIMIT 1",
            (company_id,),
        )
        lic = cur.fetchone()
    if not lic:
        raise HTTPException(status_code=400, detail="Company license not found. Contact support.")

    license_id = lic["id"]
    amount = float(plan["price"] or 0) * body.duration_months
    total_amount = amount
    currency = plan.get("currency") or "INR"

    # PaySharp placeholder: check for key in env/settings; if absent return pending without URL
    import os
    paysharp_secret = os.environ.get("PAYSHARP_SECRET_KEY") or os.environ.get("PAYSHARP_SECRET")
    checkout_url = None
    payment_intent_id = None
    message = None
    if not paysharp_secret:
        message = "PaySharp is not configured. Add PAYSHARP_SECRET_KEY to enable payments. Your subscription request has been recorded."

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO payments (company_id, license_id, plan_id, gateway, amount, tax_amount, total_amount, currency, status, initiated_by, created_at, updated_at)
            VALUES (%s, %s, %s, 'paysharp', %s, 0, %s, %s, 'created', %s, NOW(), NOW())
            RETURNING id
            """,
            (company_id, license_id, body.plan_id, amount, total_amount, currency, current_user.get("id")),
        )
        payment_id = cur.fetchone()["id"]

    return {
        "paymentId": payment_id,
        "gateway": "paysharp",
        "planId": body.plan_id,
        "planName": plan.get("plan_name"),
        "durationMonths": body.duration_months,
        "amount": int(amount),
        "currency": currency,
        "checkoutUrl": checkout_url,
        "paymentIntentId": payment_intent_id,
        "status": "pending",
        "message": message,
    }


@router.get("/payments")
def list_my_payments(
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """List payment history for the current company. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    with get_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.amount, p.total_amount, p.currency, p.status, p.gateway, p.payment_method,
                   p.paid_at, p.created_at, sp.plan_name
            FROM payments p
            LEFT JOIN subscription_plans sp ON sp.id = p.plan_id
            WHERE p.company_id = %s
            ORDER BY p.created_at DESC
            LIMIT 50
            """
        )
        rows = cur.fetchall()

    def _row(r):
        paid_at = r.get("paid_at") or r.get("created_at")
        return {
            "id": r["id"],
            "amount": int(float(r.get("total_amount") or r.get("amount") or 0)),
            "currency": r.get("currency") or "INR",
            "status": (r.get("status") or "created").lower(),
            "gateway": (r.get("gateway") or "paysharp").lower(),
            "planName": r.get("plan_name") or "",
            "paidAt": paid_at.strftime("%Y-%m-%d %H:%M") if paid_at and hasattr(paid_at, "strftime") else (str(paid_at)[:16] if paid_at else ""),
            "createdAt": (r.get("created_at").strftime("%Y-%m-%d %H:%M") if r.get("created_at") and hasattr(r["created_at"], "strftime") else (str(r.get("created_at"))[:16] if r.get("created_at") else "")),
        }

    return {"payments": [_row(r) for r in rows]}
