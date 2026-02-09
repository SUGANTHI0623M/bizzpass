"""Dashboard API - aggregated stats."""
from fastapi import APIRouter, Depends
from config.database import get_cursor
from api.auth import get_current_super_admin

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("")
def get_dashboard(
    current_user: dict = Depends(get_current_super_admin),
):
    """Get dashboard overview stats."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT
                (SELECT COUNT(*) FROM companies WHERE is_active = TRUE) AS active_companies,
                (SELECT COUNT(*) FROM companies) AS total_companies,
                (SELECT COUNT(*) FROM licenses WHERE status = 'active') AS active_licenses,
                (SELECT COUNT(*) FROM licenses WHERE status = 'expired') AS expired_licenses,
                (SELECT COUNT(*) FROM licenses WHERE status IN ('suspended', 'revoked')) AS suspended_licenses,
                (SELECT COUNT(*) FROM licenses WHERE status = 'unassigned') AS unassigned_licenses,
                (SELECT COALESCE(SUM(total_amount), 0) FROM payments WHERE status = 'captured') AS total_revenue,
                (SELECT COUNT(*) FROM payments) AS payment_count,
                (SELECT COUNT(*) FROM staff) AS total_staff
            """
        )
        row = cur.fetchone() or {}

    return {
        "activeCompanies": int(row.get("active_companies", 0) or 0),
        "totalCompanies": int(row.get("total_companies", 0) or 0),
        "activeLicenses": int(row.get("active_licenses", 0) or 0),
        "expiredLicenses": int(row.get("expired_licenses", 0) or 0),
        "suspendedLicenses": int(row.get("suspended_licenses", 0) or 0),
        "unassignedLicenses": int(row.get("unassigned_licenses", 0) or 0),
        "totalRevenue": int(float(row.get("total_revenue", 0) or 0)),
        "paymentCount": int(row.get("payment_count", 0) or 0),
        "totalStaff": int(row.get("total_staff", 0) or 0),
    }


@router.get("/companies")
def get_dashboard_companies(
    current_user: dict = Depends(get_current_super_admin),
):
    """Get companies list for dashboard."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT id, name, email, phone, address_city, address_state, subscription_plan, "
            "subscription_status, subscription_end_date, is_active FROM companies ORDER BY name"
        )
        rows = cur.fetchall()
    companies = []
    for r in rows:
        with get_cursor() as c2:
            c2.execute("SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s", (r["id"],))
            sc = (c2.fetchone() or {}).get("cnt", 0) or 0
        with get_cursor() as c2:
            c2.execute("SELECT license_key FROM licenses WHERE company_id = %s", (r["id"],))
            lk = (c2.fetchone() or {}).get("license_key", "")
        companies.append({
            "id": r["id"],
            "name": r.get("name", ""),
            "email": r.get("email", ""),
            "phone": r.get("phone", ""),
            "city": r.get("address_city", ""),
            "state": r.get("address_state", ""),
            "subscriptionPlan": r.get("subscription_plan", ""),
            "subscriptionStatus": r.get("subscription_status", ""),
            "subscriptionEndDate": str(r.get("subscription_end_date") or "")[:10],
            "licenseKey": lk,
            "isActive": bool(r.get("is_active", True)),
            "staffCount": int(sc),
            "branches": 0,
        })
    return {"companies": companies}


@router.get("/licenses")
def get_dashboard_licenses(
    current_user: dict = Depends(get_current_super_admin),
):
    """Get licenses summary for dashboard."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT l.id, l.license_key, l.status, l.valid_until, l.is_trial,
                   sp.plan_name, c.name AS company_name
            FROM licenses l
            JOIN subscription_plans sp ON sp.id = l.plan_id
            LEFT JOIN companies c ON c.id = l.company_id
            """
        )
        rows = cur.fetchall()
    return {
        "licenses": [
            {
                "id": r["id"],
                "licenseKey": r.get("license_key", ""),
                "company": r.get("company_name"),
                "plan": r.get("plan_name", ""),
                "status": r.get("status", ""),
                "validUntil": str(r.get("valid_until") or "")[:10],
                "isTrial": bool(r.get("is_trial", False)),
            }
            for r in rows
        ]
    }


@router.get("/payments")
def get_dashboard_payments(
    current_user: dict = Depends(get_current_super_admin),
):
    """Get payments for dashboard."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.total_amount, p.status, p.paid_at, p.created_at,
                   c.name AS company_name, sp.plan_name
            FROM payments p
            JOIN companies c ON c.id = p.company_id
            LEFT JOIN subscription_plans sp ON sp.id = p.plan_id
            ORDER BY p.created_at DESC LIMIT 100
            """
        )
        rows = cur.fetchall()
    def _paid_at_str(r):
        p = r.get("paid_at") or r.get("created_at")
        if p and hasattr(p, "strftime"):
            return p.strftime("%Y-%m-%d %H:%M")
        return str(p)[:16] if p else ""

    return {
        "payments": [
            {
                "id": r["id"],
                "company": r.get("company_name", ""),
                "amount": int(float(r.get("total_amount") or 0)),
                "status": r.get("status", ""),
                "paidAt": _paid_at_str(r),
                "plan": r.get("plan_name", ""),
            }
            for r in rows
        ]
    }
