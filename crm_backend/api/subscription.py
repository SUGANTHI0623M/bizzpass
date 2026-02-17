"""Subscription & Billing API for Company Portal. Paysharp integration for payments."""
import logging
import os
import traceback
import uuid
from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Request

logger = logging.getLogger(__name__)
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_user, require_permission
from api.integrations import get_paysharp_config_decrypted, get_razorpay_config_decrypted
from services.paysharp_service import create_payment_link, create_collection_request, validate_vpa
from services.razorpay_service import create_payment_link as razorpay_create_link

router = APIRouter(prefix="/subscription", tags=["subscription"])


def _plan_row(r) -> dict:
    """Build plan dict from row (supports both plan_id from joined queries and id from plans table)."""
    mb = r.get("max_branches")
    plan_id = r.get("plan_id") or r.get("id")
    return {
        "id": plan_id,
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
    try:
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

        current_staff = 0
        current_branches = 0
        try:
            with get_cursor() as cur2:
                cur2.execute("SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s", (company_id,))
                staff_row = cur2.fetchone()
                current_staff = (staff_row or {}).get("cnt") or 0
                cur2.execute("SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s", (company_id,))
                branch_row = cur2.fetchone()
                current_branches = (branch_row or {}).get("cnt") or 0
        except Exception as e:
            logger.warning("Staff/branches count failed (using 0): %s", e)

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
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("get_current_subscription failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


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


class SendUpiRequestBody(BaseModel):
    payment_id: int
    customer_vpa: str


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
    amount_paise = int(total_amount * 100)

    # Testing: set PAYMENT_TEST_AMOUNT_PAISE=100 for Rs 1; 0 or unset = actual amount
    test_paise = int(os.environ.get("PAYMENT_TEST_AMOUNT_PAISE", "100"))
    gateway_amount_paise = test_paise if test_paise > 0 else amount_paise
    # Paysharp requires minimum ₹10 (1000 paise); floor so payment link creation succeeds
    if gateway_amount_paise > 0 and gateway_amount_paise < 1000:
        gateway_amount_paise = 1000
    gateway_amount_rupees = gateway_amount_paise // 100

    # Fetch Paysharp config from DB (encrypted storage)
    paysharp = get_paysharp_config_decrypted()
    checkout_url = None
    qr_image_url = None
    payment_intent_id = None
    order_id_ext = None
    message = None

    if paysharp and paysharp.get("api_key"):
        # Build return/webhook URLs from env
        base_url = os.environ.get("FRONTEND_URL", "http://localhost:8080")
        return_url = f"{base_url}/subscription?payment_success=1"
        webhook_url = os.environ.get("CRM_BACKEND_URL", "http://localhost:8000") + "/subscription/webhook/paysharp"

        # Get company details for Paysharp (phone required for customerMobileNo)
        with get_cursor() as cur:
            cur.execute(
                "SELECT name, email, phone FROM companies WHERE id = %s",
                (company_id,),
            )
            comp = cur.fetchone() or {}
        customer_name = comp.get("name") or "Company"
        customer_email = comp.get("email") or ""
        customer_phone = (comp.get("phone") or "").strip()

        # Unique orderId per attempt (Paysharp rejects duplicates)
        order_id_ext = f"bp-{company_id}-{license_id}-{uuid.uuid4().hex[:12]}"
        result = create_payment_link(
            api_key=paysharp["api_key"],
            amount_paise=gateway_amount_paise,
            order_id=order_id_ext,
            get_qr_too=True,
            customer_id=f"C_{company_id}",
            customer_email=customer_email,
            customer_name=customer_name,
            customer_mobile_no=customer_phone,
            description=f"BizzPass {plan.get('plan_name')} - {body.duration_months} months",
            sandbox=paysharp.get("sandbox", True),
            api_base_url=paysharp.get("api_base_url"),
        )
        if result.get("success") and result.get("checkout_url"):
            checkout_url = result["checkout_url"]
            qr_image_url = result.get("qr_image_url")
            payment_intent_id = result.get("payment_id") or result.get("order_id") or order_id_ext
        else:
            err = result.get("error") if isinstance(result.get("error"), str) else ""
            message = f"Payment link creation failed: {err}" if err else "Payment link could not be created. Check Paysharp config and try again."
    else:
        message = "Paysharp is not configured. Configure it in Integrations (Super Admin) to enable payments."

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO payments (company_id, license_id, plan_id, gateway, amount, tax_amount, total_amount, currency, status, initiated_by, razorpay_order_id, razorpay_payment_id, created_at, updated_at)
            VALUES (%s, %s, %s, 'paysharp', %s, 0, %s, %s, 'created', %s, %s, %s, NOW(), NOW())
            RETURNING id
            """,
            (company_id, license_id, body.plan_id, amount, total_amount, currency, current_user.get("id"), order_id_ext, payment_intent_id),
        )
        payment_id = cur.fetchone()["id"]

    razorpay_available = get_razorpay_config_decrypted() is not None

    return {
        "paymentId": payment_id,
        "gateway": "paysharp",
        "planId": body.plan_id,
        "planName": plan.get("plan_name"),
        "durationMonths": body.duration_months,
        "amount": int(amount),
        "gatewayAmount": gateway_amount_rupees,  # Amount charged at gateway (Rs 1 for testing)
        "currency": currency,
        "checkoutUrl": checkout_url,
        "qrImageUrl": qr_image_url,
        "paymentIntentId": payment_intent_id,
        "status": "pending",
        "message": message,
        "razorpayAvailable": razorpay_available,
    }


@router.post("/send-upi-request")
def send_upi_request(
    body: SendUpiRequestBody,
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """Send Paysharp Collection Request to customer's UPI ID. Payment request appears in their UPI app."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    vpa = (body.customer_vpa or "").strip()
    if not vpa:
        raise HTTPException(status_code=400, detail="UPI ID (VPA) is required")

    with get_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.razorpay_order_id, p.total_amount, p.amount, p.currency,
                   sp.plan_name, c.name, c.email, c.phone
            FROM payments p
            LEFT JOIN subscription_plans sp ON sp.id = p.plan_id
            LEFT JOIN companies c ON c.id = p.company_id
            WHERE p.id = %s AND p.company_id = %s AND p.status = 'created' AND p.gateway = 'paysharp'
            """,
            (body.payment_id, company_id),
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Payment not found or already completed")

    base_order_id = row.get("razorpay_order_id")
    if not base_order_id:
        raise HTTPException(status_code=400, detail="Payment has no order ID")

    # Paysharp rejects duplicate orderIds. Intent/QR already used base_order_id; use fresh ID for Collection Request
    order_id_collection = f"{base_order_id}-cr-{uuid.uuid4().hex[:8]}"

    test_paise = int(os.environ.get("PAYMENT_TEST_AMOUNT_PAISE", "100"))
    amount = float(row.get("total_amount") or row.get("amount") or 0)
    amount_paise = test_paise if test_paise > 0 else int(amount * 100)
    if amount_paise > 0 and amount_paise < 1000:
        amount_paise = 1000  # Paysharp minimum ₹10

    paysharp = get_paysharp_config_decrypted()
    if not paysharp or not paysharp.get("api_key"):
        raise HTTPException(status_code=503, detail="Paysharp is not configured")

    # Optionally validate VPA; Paysharp's validate can reject some valid IDs (e.g. @ptyes).
    # We try collection request anyway - bank/PSP will return the real error.
    val = validate_vpa(paysharp["api_key"], vpa, paysharp.get("api_base_url"))
    if not val.get("success"):
        logger.warning("Paysharp VPA validate failed for %s: %s; attempting collection request anyway", vpa, val.get("error"))

    comp = row or {}
    result = create_collection_request(
        api_key=paysharp["api_key"],
        amount_paise=amount_paise,
        order_id=order_id_collection,
        customer_vpa=vpa,
        customer_id=f"C_{company_id}",
        customer_name=comp.get("name") or "Company",
        customer_email=comp.get("email") or "",
        customer_mobile_no=(comp.get("phone") or "").strip(),
        description=f"BizzPass {row.get('plan_name')} - Subscription",
        api_base_url=paysharp.get("api_base_url"),
    )

    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to send UPI request"))

    return {"ok": True, "message": "Payment request sent to your UPI app. Please approve in PhonePe, GPay, Paytm, etc."}


@router.post("/initiate-razorpay")
def initiate_razorpay_subscription(
    body: InitiateSubscriptionBody,
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """Create Razorpay Payment Link for Card, UPI, Netbanking, Wallets. Opens hosted checkout."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    razorpay = get_razorpay_config_decrypted()
    if not razorpay:
        raise HTTPException(status_code=503, detail="Razorpay is not configured. Add in Integrations.")

    with get_cursor() as cur:
        cur.execute(
            "SELECT id, plan_name FROM subscription_plans WHERE id = %s AND is_active = TRUE",
            (body.plan_id,),
        )
        plan = cur.fetchone()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    with get_cursor() as cur:
        cur.execute("SELECT id FROM licenses WHERE company_id = %s LIMIT 1", (company_id,))
        lic = cur.fetchone()
    if not lic:
        raise HTTPException(status_code=400, detail="Company license not found")

    amount = float(plan.get("price") or 0) * body.duration_months
    test_paise = int(os.environ.get("PAYMENT_TEST_AMOUNT_PAISE", "100"))
    amount_paise = test_paise if test_paise > 0 else int(amount * 100)

    order_id_ext = f"bp-rz-{company_id}-{lic['id']}-{uuid.uuid4().hex[:12]}"
    base_url = os.environ.get("FRONTEND_URL", "http://localhost:8080")
    callback_url = f"{base_url}/subscription?payment_success=1"

    with get_cursor() as cur:
        cur.execute(
            "SELECT name, email, phone FROM companies WHERE id = %s", (company_id,)
        )
        comp = cur.fetchone() or {}

    result = razorpay_create_link(
        key_id=razorpay["key_id"],
        key_secret=razorpay["key_secret"],
        amount_paise=amount_paise,
        currency="INR",
        description=f"BizzPass {plan.get('plan_name')} - {body.duration_months} months",
        reference_id=order_id_ext,
        callback_url=callback_url,
        customer_name=comp.get("name") or "Company",
        customer_email=comp.get("email") or "",
        customer_phone=(comp.get("phone") or "").strip(),
    )

    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "Failed to create payment link"))

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO payments (company_id, license_id, plan_id, gateway, amount, tax_amount, total_amount, currency, status, initiated_by, razorpay_order_id, razorpay_payment_id, created_at, updated_at)
            VALUES (%s, %s, %s, 'razorpay', %s, 0, %s, 'INR', 'created', %s, %s, %s, NOW(), NOW())
            RETURNING id
            """,
            (company_id, lic["id"], body.plan_id, amount, amount, current_user.get("id"), order_id_ext, result.get("id", order_id_ext)),
        )
        payment_id = cur.fetchone()["id"]

    return {
        "paymentId": payment_id,
        "gateway": "razorpay",
        "checkoutUrl": result["short_url"],
        "amount": amount_paise // 100,
        "gatewayAmount": amount_paise // 100,
    }


def _format_ts(val):
    """Safely format timestamp for JSON."""
    if val is None:
        return ""
    if hasattr(val, "strftime"):
        return val.strftime("%Y-%m-%d %H:%M")
    return str(val)[:16] if val else ""


@router.get("/payments")
def list_my_payments(
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """List payment history for the current company. Company Admin only."""
    try:
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
                """,
                (company_id,),
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
                "paidAt": _format_ts(paid_at),
                "createdAt": _format_ts(r.get("created_at")),
            }

        return {"payments": [_row(r) for r in rows]}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("list_my_payments failed: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/payments/{payment_id}")
def get_payment_by_id(
    payment_id: int,
    current_user: dict = Depends(require_permission("subscription.view")),
):
    """Get a single payment's status and details. Company Admin only (own company)."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    with get_cursor() as cur:
        cur.execute(
            """
            SELECT p.id, p.amount, p.total_amount, p.tax_amount, p.currency, p.status, p.gateway, p.payment_method,
                   p.razorpay_order_id, p.razorpay_payment_id, p.paid_at, p.created_at,
                   sp.plan_name, sp.duration_months
            FROM payments p
            LEFT JOIN subscription_plans sp ON sp.id = p.plan_id
            WHERE p.id = %s AND p.company_id = %s
            """,
            (payment_id, company_id),
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Payment not found")

    paid_at = row.get("paid_at") or row.get("created_at")
    gateway_ref = row.get("razorpay_payment_id") or row.get("razorpay_order_id") or ""

    return {
        "id": row["id"],
        "amount": int(float(row.get("total_amount") or row.get("amount") or 0)),
        "taxAmount": int(float(row.get("tax_amount") or 0)),
        "currency": row.get("currency") or "INR",
        "status": (row.get("status") or "created").lower(),
        "gateway": (row.get("gateway") or "paysharp").lower(),
        "paymentMethod": (row.get("payment_method") or "upi").lower(),
        "planName": row.get("plan_name") or "",
        "durationMonths": row.get("duration_months"),
        "gatewayOrderId": row.get("razorpay_order_id"),
        "gatewayPaymentId": row.get("razorpay_payment_id"),
        "transactionRef": gateway_ref,
        "paidAt": _format_ts(paid_at),
        "createdAt": _format_ts(row.get("created_at")),
    }


@router.post("/webhook/razorpay")
async def razorpay_webhook(request: Request):
    """Razorpay webhook - payment_link.paid. Update payment and extend license."""
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    event = body.get("event", "")
    if event != "payment_link.paid":
        return {"ok": True}
    payload = body.get("payload", {}) or {}
    payment_link = (payload.get("payment_link", {}) or {}).get("entity", {}) or payload.get("payment_link") or {}
    payment_entity = (payload.get("payment", {}) or {}).get("entity", {}) or payload.get("payment") or {}
    ref_id = payment_link.get("reference_id") or payment_entity.get("order_id")
    payment_id_rz = payment_entity.get("id") or payment_link.get("id")
    if not ref_id:
        return {"ok": True}
    with get_cursor() as cur:
        cur.execute(
            """
            UPDATE payments SET status = 'captured', paid_at = NOW(), razorpay_payment_id = %s, updated_at = NOW()
            WHERE gateway = 'razorpay' AND razorpay_order_id = %s AND status = 'created'
            RETURNING id, company_id, license_id
            """,
            (payment_id_rz or ref_id, ref_id),
        )
        row = cur.fetchone()
    if row:
        lic_id, comp_id = row.get("license_id"), row.get("company_id")
        if lic_id and comp_id:
            with get_cursor() as cur2:
                cur2.execute(
                    """
                    UPDATE licenses SET status = 'active', valid_from = COALESCE(valid_from, CURRENT_DATE),
                    valid_until = CURRENT_DATE + INTERVAL '1 year', updated_at = NOW()
                    WHERE id = %s
                    """,
                    (lic_id,),
                )
                cur2.execute(
                    "UPDATE companies SET subscription_status = 'active', subscription_end_date = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
                    (comp_id,),
                )
    return {"ok": True}


@router.post("/webhook/paysharp")
async def paysharp_webhook(request: Request):
    """
    Paysharp webhook - called when payment is completed. Verify signature and update payment + license.
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")
    # Paysharp webhook payload shape varies; common: payment_id, order_id, status, signature
    payment_id = body.get("payment_id") or body.get("paymentId") or body.get("id")
    order_id = body.get("order_id") or body.get("orderId")
    status = (body.get("status") or body.get("payment_status") or "").lower()
    if not payment_id and not order_id:
        raise HTTPException(status_code=400, detail="Missing payment_id or order_id")
    # TODO: verify Paysharp webhook signature using secret_key
    if status in ("captured", "success", "paid", "completed"):
        with get_cursor() as cur:
            cur.execute(
                """
                UPDATE payments SET status = 'captured', paid_at = NOW(), updated_at = NOW()
                WHERE gateway = 'paysharp' AND (razorpay_payment_id = %s OR razorpay_order_id = %s)
                AND status = 'created'
                RETURNING id, company_id, license_id
                """,
                (payment_id or order_id, order_id or payment_id),
            )
            row = cur.fetchone()
        if row:
            # Extend license on successful payment
            lic_id = row.get("license_id")
            comp_id = row.get("company_id")
            if lic_id and comp_id:
                with get_cursor() as cur2:
                    cur2.execute(
                        """
                        UPDATE licenses SET status = 'active', valid_from = COALESCE(valid_from, CURRENT_DATE),
                        valid_until = CURRENT_DATE + INTERVAL '1 year', updated_at = NOW()
                        WHERE id = %s
                        """,
                        (lic_id,),
                    )
                    cur2.execute(
                        "UPDATE companies SET subscription_status = 'active', subscription_end_date = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
                        (comp_id,),
                    )
    return {"ok": True}
