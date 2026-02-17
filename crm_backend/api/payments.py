"""Payments API - list transactions."""
from fastapi import APIRouter, Depends
from config.database import get_cursor
from api.auth import get_current_super_admin

router = APIRouter(prefix="/payments", tags=["payments"])


def _payment_row(row) -> dict:
    paid_at = row.get("paid_at") or row.get("created_at")
    gateway_payment_id = (
        row.get("razorpay_payment_id")
        or row.get("razorpay_order_id")
        or ""
    )
    return {
        "id": row["id"],
        "company": row.get("company_name") or "",
        "companyEmail": row.get("company_email") or "",
        "amount": int(float(row.get("total_amount") or row.get("amount") or 0)),
        "currency": row.get("currency") or "INR",
        "status": (row.get("status") or "created").lower(),
        "gateway": (row.get("gateway") or "paysharp").lower(),
        "method": (row.get("payment_method") or "upi").upper(),
        "razorpayId": gateway_payment_id,
        "gatewayPaymentId": gateway_payment_id,
        "paidAt": paid_at.strftime("%Y-%m-%d %H:%M") if paid_at and hasattr(paid_at, "strftime") else (str(paid_at)[:16] if paid_at else ""),
        "createdAt": (row.get("created_at").strftime("%Y-%m-%d %H:%M") if row.get("created_at") and hasattr(row.get("created_at"), "strftime") else (str(row.get("created_at", ""))[:16] if row.get("created_at") else "")),
        "plan": row.get("plan_name") or "",
    }


@router.get("")
def list_payments(
    search: str | None = None,
    current_user: dict = Depends(get_current_super_admin),
):
    """List all payments from all companies. Super Admin only."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.amount, p.total_amount, p.currency, p.status, p.gateway, p.payment_method,
                   p.razorpay_payment_id, p.razorpay_order_id,
                   p.paid_at, p.created_at,
                   c.name AS company_name, c.email AS company_email,
                   sp.plan_name
            FROM payments p
            JOIN companies c ON c.id = p.company_id
            LEFT JOIN subscription_plans sp ON sp.id = p.plan_id
            ORDER BY p.created_at DESC
            """
        )
        rows = cur.fetchall()

    payments = [_payment_row(r) for r in rows]
    if search:
        s = search.lower()
        payments = [
            p
            for p in payments
            if (p["company"] or "").lower().find(s) >= 0
            or (p["companyEmail"] or "").lower().find(s) >= 0
            or (p["razorpayId"] or "").lower().find(s) >= 0
            or (p["plan"] or "").lower().find(s) >= 0
        ]
    return {"payments": payments}
