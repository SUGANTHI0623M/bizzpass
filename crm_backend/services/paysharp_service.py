"""Paysharp payment gateway integration. Creates payment links for subscription billing."""
import logging
import os
import httpx
from typing import Optional

logger = logging.getLogger(__name__)


# Per Paysharp UPI dashboard: Base URL is https://api.paysharp.in/v1/upi
# Endpoints: /order/intent (Intent Url), /order/request (Collection Request), /order/qrcode (QR)
PAYSHARP_API_BASE = "https://api.paysharp.in/v1/upi"
PAYSHARP_SANDBOX_BASE = "https://api.paysharp.in/v1/upi"

# Paysharp enforces minimum ₹10 per transaction
PAYSHARP_MIN_AMOUNT_PAISE = 1000


def create_payment_link(
    api_key: str,
    amount_paise: int,
    currency: str = "INR",
    order_id: str = "",
    customer_id: str = "",
    customer_email: str = "",
    customer_name: str = "",
    customer_mobile_no: str = "",
    description: str = "",
    sandbox: bool = True,
    return_url: str = "",
    webhook_url: str = "",
    api_base_url: str | None = None,
    get_qr_too: bool = False,
) -> dict:
    """
    Create a Paysharp UPI payment link via Intent Url API. Returns {checkout_url, order_id, payment_id} or {error}.
    Amount in paise (e.g. 10000 = ₹100); converted to rupees for Paysharp API.
    Payload format per Postman collection: orderId, amount (rupees), customerId, customerName, customerEmail, remarks.
    """
    if api_base_url and api_base_url.strip():
        base = api_base_url.strip().rstrip("/")
        if not base.endswith("/upi"):
            base = f"{base.rstrip('/')}/upi"
    else:
        base = (
            os.environ.get("PAYSHARP_SANDBOX_BASE") or PAYSHARP_SANDBOX_BASE
            if sandbox
            else os.environ.get("PAYSHARP_API_BASE") or PAYSHARP_API_BASE
        )
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    # Paysharp Intent Url API format (per Postman): amount in rupees, camelCase keys
    # Paysharp requires minimum ₹10; floor to avoid "Amount should be greater than or equal to 10"
    amount_paise_effective = max(amount_paise or 0, PAYSHARP_MIN_AMOUNT_PAISE)
    amount_rupees = round(amount_paise_effective / 100) if amount_paise_effective else 10
    payload = {
        "orderId": order_id or "",
        "amount": amount_rupees,
        "customerId": customer_id or "guest",
        "customerName": customer_name or "",
        "customerMobileNo": (customer_mobile_no or "").strip(),
        "customerEmail": customer_email or "",
        "remarks": description or "BizzPass Subscription",
    }

    # Intent Url API - UPI deep link for paying
    endpoint = f"{base}/order/intent"
    try:
        with httpx.Client(timeout=30) as client:
            resp = client.post(endpoint, headers=headers, json=payload)
            data = resp.json() if resp.text else {}
            if resp.status_code in (200, 201):
                url = (
                    data.get("intent_url")
                    or data.get("intentUrl")
                    or data.get("payment_url")
                    or data.get("checkout_url")
                    or data.get("url")
                    or data.get("link")
                    or (data.get("data", {}) or {}).get("intent_url")
                    or (data.get("data", {}) or {}).get("intentUrl")
                    or (data.get("data", {}) or {}).get("url")
                )
                if url:
                    out = {
                        "success": True,
                        "checkout_url": url,
                        "order_id": data.get("orderId") or data.get("order_id") or data.get("id") or order_id,
                        "payment_id": data.get("paymentId") or data.get("payment_id") or data.get("id"),
                    }
                    # Also fetch QR code from Paysharp if requested (for native QR display)
                    if get_qr_too:
                        qr_resp = client.post(f"{base}/order/qrcode", headers=headers, json=payload)
                        qr_data = qr_resp.json() if qr_resp.text else {}
                        if qr_resp.status_code in (200, 201):
                            qr_url = (
                                qr_data.get("qr_code")
                                or qr_data.get("qrCode")
                                or qr_data.get("qr_url")
                                or qr_data.get("qrUrl")
                                or qr_data.get("url")
                                or qr_data.get("image_url")
                                or (qr_data.get("data", {}) or {}).get("qr_code")
                                or (qr_data.get("data", {}) or {}).get("qrCode")
                                or (qr_data.get("data", {}) or {}).get("url")
                            )
                            if qr_url:
                                out["qr_image_url"] = qr_url
                    return out
                # 200 but no URL - log full response and treat as error
                logger.warning("Paysharp 200 OK but no payment URL in response: %s", data)
                err_from_body = data.get("message") or data.get("error") or data.get("detail") or str(data)
                return {"success": False, "error": err_from_body or "Paysharp returned no payment URL"}
            logger.warning(
                "Paysharp API error: status=%s, response=%s",
                resp.status_code,
                data or resp.text[:500] if resp.text else "",
            )
            err_msg = data.get("message") or data.get("error") or data.get("detail") or data.get("msg")
            if isinstance(err_msg, list):
                err_msg = err_msg[0].get("msg", str(err_msg)) if err_msg else resp.text
            err_str = err_msg or resp.text or f"HTTP {resp.status_code}"

            # Provide actionable guidance for common Paysharp errors
            if resp.status_code in (401, 403) or "access denied" in (err_str or "").lower():
                hint = (
                    " Check: (1) API key is correct and from Paysharp merchant dashboard, "
                    "(2) Use Production token for Production environment, (3) Whitelist your server IP in Paysharp Settings."
                )
                err_str = f"{err_str}{hint}" if err_str else f"Access denied (HTTP {resp.status_code}){hint}"

            return {"success": False, "error": err_str}
    except httpx.TimeoutException:
        return {"success": False, "error": "Paysharp request timed out"}
    except Exception as e:
        err = str(e)
        if "Errno -2" in err or "Name or service not known" in err:
            err = (
                "DNS resolution failed. Ensure Docker can reach the internet (add dns: [8.8.8.8] in docker-compose) "
                "or set API Base URL in Integrations if your Paysharp URL differs."
            )
        return {"success": False, "error": err}


def validate_vpa(api_key: str, customer_vpa: str, api_base_url: str | None = None) -> dict:
    """
    Validate UPI ID (VPA) via Paysharp. Returns {success: bool, error?: str}.
    Call before Collection Request to catch invalid VPAs early.
    """
    if api_base_url and api_base_url.strip():
        base = api_base_url.strip().rstrip("/")
        if not base.endswith("/upi"):
            base = f"{base.rstrip('/')}/upi"
    else:
        base = PAYSHARP_API_BASE

    vpa = (customer_vpa or "").strip()
    if not vpa:
        return {"success": False, "error": "UPI ID (VPA) is required"}

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    endpoint = f"{base}/vpa/validate"
    try:
        with httpx.Client(timeout=15) as client:
            resp = client.post(endpoint, headers=headers, json={"customerVPA": vpa})
            data = resp.json() if resp.text else {}
            if resp.status_code in (200, 201):
                return {"success": True}
            err = data.get("message") or data.get("error") or data.get("detail") or resp.text
            return {"success": False, "error": err or f"HTTP {resp.status_code}"}
    except Exception as e:
        return {"success": False, "error": str(e)}


def create_collection_request(
    api_key: str,
    amount_paise: int,
    order_id: str,
    customer_vpa: str,
    customer_id: str = "",
    customer_name: str = "",
    customer_email: str = "",
    customer_mobile_no: str = "",
    description: str = "",
    api_base_url: str | None = None,
) -> dict:
    """
    Send payment request to customer's UPI ID (VPA). Uses Paysharp Collection Request API.
    Customer receives request in their UPI app (PhonePe, GPay, etc.).
    """
    if api_base_url and api_base_url.strip():
        base = api_base_url.strip().rstrip("/")
        if not base.endswith("/upi"):
            base = f"{base.rstrip('/')}/upi"
    else:
        base = PAYSHARP_API_BASE

    vpa = (customer_vpa or "").strip()
    if not vpa:
        return {"success": False, "error": "UPI ID (VPA) is required"}

    # Basic format check: UPI ID must be name@provider (e.g. name@paytm, 99xx@ybl)
    if "@" not in vpa or len(vpa.split("@")) != 2:
        return {
            "success": False,
            "error": "Invalid UPI ID format. Use format: name@bank (e.g. name@paytm, 99xxxx@ybl for PhonePe, name@okaxis for GPay)",
        }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    # Paysharp requires minimum ₹10
    amount_paise_effective = max(amount_paise or 0, PAYSHARP_MIN_AMOUNT_PAISE)
    amount_rupees = round(amount_paise_effective / 100) if amount_paise_effective else 10
    payload = {
        "orderId": order_id,
        "amount": amount_rupees,
        "customerVPA": vpa,
        "customerId": customer_id or "guest",
        "customerName": customer_name or "",
        "customerMobileNo": (customer_mobile_no or "").strip(),
        "customerEmail": customer_email or "",
        "remarks": description or "BizzPass Subscription",
    }

    endpoint = f"{base}/order/request"
    vpa_hint = " Use format: name@bank (e.g. name@paytm, 99xxxx@ybl for PhonePe, name@okaxis for GPay)."
    try:
        with httpx.Client(timeout=30) as client:
            resp = client.post(endpoint, headers=headers, json=payload)
            data = resp.json() if resp.text else {}
            if resp.status_code in (200, 201):
                return {"success": True, "message": "Payment request sent to your UPI app"}
            err_msg = data.get("message") or data.get("error") or data.get("detail") or resp.text
            if err_msg:
                if "invalid" in err_msg.lower() and "vpa" in err_msg.lower():
                    err_msg = f"{err_msg}.{vpa_hint}"
                elif "bank" in err_msg.lower() and "server" in err_msg.lower():
                    err_msg = f"{err_msg} Try again in a few moments or use the QR code / UPI link above to pay directly."
            return {"success": False, "error": err_msg or f"HTTP {resp.status_code}"}
    except Exception as e:
        return {"success": False, "error": str(e)}
