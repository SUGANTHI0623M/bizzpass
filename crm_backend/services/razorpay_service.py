"""Razorpay payment gateway - Payment Links for Card, UPI, Netbanking, Wallets."""
import logging
import base64
import httpx

logger = logging.getLogger(__name__)

RAZORPAY_API = "https://api.razorpay.com/v1"


def create_payment_link(
    key_id: str,
    key_secret: str,
    amount_paise: int,
    currency: str = "INR",
    description: str = "",
    reference_id: str = "",
    callback_url: str = "",
    customer_name: str = "",
    customer_email: str = "",
    customer_phone: str = "",
) -> dict:
    """
    Create Razorpay Payment Link. Supports Card, UPI, Netbanking, Wallets.
    Returns {short_url, id} or {error}.
    Amount in paise (100 = ₹1 for INR).
    """
    if not key_id or not key_secret:
        return {"success": False, "error": "Razorpay credentials required"}

    auth = base64.b64encode(f"{key_id}:{key_secret}".encode()).decode()
    headers = {
        "Authorization": f"Basic {auth}",
        "Content-Type": "application/json",
    }
    payload = {
        "amount": amount_paise,
        "currency": currency,
        "description": description or "BizzPass Subscription",
        "reference_id": reference_id or "",
        "callback_url": callback_url or "",
        "callback_method": "get" if callback_url else None,
    }
    if customer_name or customer_email or customer_phone:
        payload["customer"] = {
            "name": customer_name or "",
            "email": customer_email or "",
            "contact": (customer_phone or "").strip() or None,
        }
    payload = {k: v for k, v in payload.items() if v is not None and v != ""}

    try:
        with httpx.Client(timeout=30) as client:
            resp = client.post(f"{RAZORPAY_API}/payment_links", headers=headers, json=payload)
            data = resp.json() if resp.text else {}
            if resp.status_code in (200, 201):
                url = data.get("short_url") or data.get("url")
                if url:
                    return {
                        "success": True,
                        "short_url": url,
                        "id": data.get("id"),
                    }
                return {"success": False, "error": "No payment URL in response"}
            err = data.get("error", {})
            err_desc = err.get("description", err.get("reason", str(data))) if isinstance(err, dict) else str(err)
            return {"success": False, "error": err_desc or f"HTTP {resp.status_code}"}
    except Exception as e:
        return {"success": False, "error": str(e)}
