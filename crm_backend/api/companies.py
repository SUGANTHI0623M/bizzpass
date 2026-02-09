"""Companies CRUD API with logo upload via Cloudinary."""
from typing import Annotated

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_super_admin
from services.cloudinary_service import upload_image
from services.company_db_provisioning import create_company_database

router = APIRouter(prefix="/companies", tags=["companies"])

# Default password for new company admin when not provided (user should change after first login)
DEFAULT_COMPANY_ADMIN_PASSWORD = "BizzPass@123"


class CompanyCreate(BaseModel):
    name: str
    email: str
    phone: str | None = None
    city: str | None = None
    state: str | None = None
    subscription_plan: str = "Starter"
    license_key: str  # Required: unassigned license key to link to this company
    is_active: bool = True
    admin_password: str | None = None  # Optional; if omitted, default is used and returned in response


class CompanyUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    city: str | None = None
    state: str | None = None
    subscription_plan: str | None = None
    is_active: bool | None = None


def _company_row_to_dict(
    row,
    staff_count: int = 0,
    branches: int = 0,
    max_staff: int | None = None,
    max_branches: int | None = None,
) -> dict:
    """Map DB row to frontend Company shape. max_staff/max_branches from license (plan limits)."""
    return {
        "id": row["id"],
        "name": row["name"] or "",
        "email": row["email"] or "",
        "phone": row["phone"] or "",
        "city": row.get("address_city") or row.get("city") or "",
        "state": row.get("address_state") or row.get("state") or "",
        "subscriptionPlan": row.get("subscription_plan") or "Starter",
        "subscriptionStatus": row.get("subscription_status") or "active",
        "subscriptionEndDate": (row.get("subscription_end_date") or "").__str__()[:10] if row.get("subscription_end_date") else "",
        "licenseKey": row.get("license_key") or "",
        "isActive": bool(row.get("is_active", True)),
        "staffCount": staff_count,
        "branches": branches,
        "maxStaff": max_staff,
        "maxBranches": max_branches,
        "logo": row.get("logo"),
    }


@router.get("")
def list_companies(
    search: str | None = None,
    tab: str = "all",
    current_user: dict = Depends(get_current_super_admin),
):
    """List companies with optional search and filter."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT c.id, c.mongo_id, c.name, c.email, c.phone, c.address_city, c.address_state,
                   c.subscription_plan, c.subscription_status, c.subscription_end_date,
                   c.is_active, c.logo,
                   (SELECT l.license_key FROM licenses l WHERE l.company_id = c.id LIMIT 1) AS license_key
            FROM companies c
            ORDER BY c.name
            """
        )
        rows = cur.fetchall()

    companies = []
    for r in rows:
        with get_cursor() as cur2:
            cur2.execute(
                "SELECT l.max_users, l.max_branches FROM licenses l WHERE l.company_id = %s LIMIT 1",
                (r["id"],),
            )
            lic = cur2.fetchone()
            max_staff = lic.get("max_users") if lic else None
            max_branches = lic.get("max_branches") if lic else None
            cur2.execute(
                """
                SELECT COUNT(*) AS cnt FROM staff
                WHERE company_id = %s OR business_id = %s OR (business_id = %s AND %s IS NOT NULL)
                """,
                (r["id"], str(r["id"]), r.get("mongo_id") or "", r.get("mongo_id")),
            )
            staff_count = int((cur2.fetchone() or {}).get("cnt", 0) or 0)
            cur2.execute(
                """
                SELECT COUNT(*) AS cnt FROM branches
                WHERE company_id = %s OR business_id = %s OR business_id = %s
                """,
                (r["id"], str(r["id"]), r.get("mongo_id") or str(r["id"])),
            )
            branches = int((cur2.fetchone() or {}).get("cnt", 0) or 0)
        d = _company_row_to_dict(r, staff_count, branches, max_staff, max_branches)
        d["address_city"] = r.get("address_city")
        d["address_state"] = r.get("address_state")
        companies.append(d)

    if search and search.strip():
        s = search.lower()
        companies = [
            c
            for c in companies
            if (c["name"] or "").lower().find(s) >= 0 or (c["city"] or "").lower().find(s) >= 0
        ]
    if tab == "active":
        companies = [c for c in companies if c["isActive"]]
    elif tab == "inactive":
        companies = [c for c in companies if not c["isActive"]]
    elif tab == "expiring":
        companies = [c for c in companies if c["subscriptionStatus"] == "expiring_soon"]

    return {"companies": companies}


@router.get("/{company_id}")
def get_company(
    company_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Get single company by ID."""
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT c.id, c.mongo_id, c.name, c.email, c.phone, c.address_city, c.address_state,
                   c.subscription_plan, c.subscription_status, c.subscription_end_date,
                   c.is_active, c.logo,
                   (SELECT l.license_key FROM licenses l WHERE l.company_id = c.id LIMIT 1) AS license_key
            FROM companies c
            WHERE c.id = %s
            """,
            (company_id,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Company not found")

    mongo_id = row.get("mongo_id")
    with get_cursor() as cur:
        cur.execute(
            "SELECT l.max_users, l.max_branches FROM licenses l WHERE l.company_id = %s LIMIT 1",
            (company_id,),
        )
        lic = cur.fetchone()
        max_staff = lic.get("max_users") if lic else None
        max_branches = lic.get("max_branches") if lic else None
        cur.execute(
            """
            SELECT COUNT(*) AS cnt FROM staff
            WHERE company_id = %s OR business_id = %s OR (business_id = %s AND %s IS NOT NULL)
            """,
            (company_id, str(company_id), mongo_id or "", mongo_id),
        )
        staff_count = int((cur.fetchone() or {}).get("cnt", 0) or 0)
        cur.execute(
            """
            SELECT COUNT(*) AS cnt FROM branches
            WHERE company_id = %s OR business_id = %s OR business_id = %s
            """,
            (company_id, str(company_id), mongo_id or str(company_id)),
        )
        branches = int((cur.fetchone() or {}).get("cnt", 0) or 0)

    return _company_row_to_dict(row, staff_count, branches, max_staff, max_branches)


@router.post("")
def create_company(
    body: CompanyCreate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Create a new company. Rejects duplicate email or phone."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM companies WHERE LOWER(TRIM(email)) = LOWER(TRIM(%s)) LIMIT 1",
            (body.email,),
        )
        if cur.fetchone():
            raise HTTPException(
                status_code=400,
                detail="Company with this email already exists.",
            )
        if body.phone and body.phone.strip():
            cur.execute(
                "SELECT id FROM companies WHERE TRIM(phone) = TRIM(%s) LIMIT 1",
                (body.phone,),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="Company with this phone number already exists.",
                )

    license_key_trimmed = (body.license_key or "").strip()
    if not license_key_trimmed:
        raise HTTPException(status_code=400, detail="License key is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM licenses WHERE license_key = %s AND company_id IS NULL",
            (license_key_trimmed,),
        )
        lic = cur.fetchone()
        if not lic:
            raise HTTPException(status_code=400, detail="License key not found or already assigned to another company")
    license_id = lic["id"]

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO companies (
                name, email, phone, address_city, address_state,
                subscription_plan, subscription_status, subscription_end_date,
                is_active, license_id, created_at, updated_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, 'active', NULL, %s, %s, NOW(), NOW())
            RETURNING id, name, email, phone, address_city, address_state,
                      subscription_plan, subscription_status, subscription_end_date,
                      is_active
            """,
            (
                body.name,
                body.email,
                body.phone or "",
                body.city or "",
                body.state or "",
                body.subscription_plan,
                body.is_active,
                license_id,
            ),
        )
        row = cur.fetchone()

    new_id = row["id"]

    # Create a separate database for this company with all required tables (does not affect existing features)
    try:
        db_name = create_company_database(new_id)
        with get_cursor() as cur:
            cur.execute(
                "UPDATE companies SET db_name = %s WHERE id = %s",
                (db_name, new_id),
            )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Company created but failed to provision company database. Please ensure the DB user has CREATEDB privilege. Error: {e!s}",
        ) from e

    with get_cursor() as cur:
        cur.execute(
            "UPDATE licenses SET company_id = %s, status = 'active', valid_from = CURRENT_DATE, valid_until = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
            (new_id, license_id),
        )
        cur.execute(
            "UPDATE companies SET license_id = %s, subscription_end_date = CURRENT_DATE + INTERVAL '1 year' WHERE id = %s",
            (license_id, new_id),
        )
        cur.execute("SELECT license_key, max_users, max_branches FROM licenses WHERE id = %s", (license_id,))
        lic_row = cur.fetchone()
    license_key = (lic_row or {}).get("license_key", license_key_trimmed)
    max_staff = lic_row.get("max_users") if lic_row else None
    max_branches = lic_row.get("max_branches") if lic_row else None

    # Create company admin user so they can log in (email = company email, company_id_bigint = new_id)
    admin_password = (body.admin_password or "").strip() or DEFAULT_COMPANY_ADMIN_PASSWORD
    used_default_password = not (body.admin_password and body.admin_password.strip())
    hashed = bcrypt.hashpw(admin_password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")
    rbac_role_id = None
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM rbac_roles WHERE code = %s AND company_id IS NULL LIMIT 1",
            ("COMPANY_ADMIN",),
        )
        r = cur.fetchone()
        if r:
            rbac_role_id = r["id"]
        cur.execute(
            """
            INSERT INTO users (name, email, password, role, company_id_bigint, rbac_role_id, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, 'company_admin', %s, %s, TRUE, NOW(), NOW())
            """,
            (body.name.strip() or "Company Admin", body.email.strip(), hashed, new_id, rbac_role_id),
        )

    result = _company_row_to_dict(
        {**dict(row), "license_key": license_key},
        staff_count=0,
        branches=0,
        max_staff=max_staff,
        max_branches=max_branches,
    )
    if used_default_password:
        result["adminLogin"] = {
            "email": body.email.strip(),
            "temporaryPassword": DEFAULT_COMPANY_ADMIN_PASSWORD,
            "message": "Company admin can log in with this email and temporary password. Change after first login.",
        }
    return result


@router.patch("/{company_id}")
def update_company(
    company_id: int,
    body: CompanyUpdate,
    current_user: dict = Depends(get_current_super_admin),
):
    """Update a company. Rejects duplicate email or phone from other companies."""
    with get_cursor() as cur:
        if body.email is not None and body.email.strip():
            cur.execute(
                "SELECT id FROM companies WHERE LOWER(TRIM(email)) = LOWER(TRIM(%s)) AND id != %s LIMIT 1",
                (body.email, company_id),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="Company with this email already exists.",
                )
        if body.phone is not None and body.phone.strip():
            cur.execute(
                "SELECT id FROM companies WHERE TRIM(phone) = TRIM(%s) AND id != %s LIMIT 1",
                (body.phone, company_id),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="Company with this phone number already exists.",
                )

    updates = []
    vals = []
    if body.name is not None:
        updates.append("name = %s")
        vals.append(body.name)
    if body.email is not None:
        updates.append("email = %s")
        vals.append(body.email)
    if body.phone is not None:
        updates.append("phone = %s")
        vals.append(body.phone)
    if body.city is not None:
        updates.append("address_city = %s")
        vals.append(body.city)
    if body.state is not None:
        updates.append("address_state = %s")
        vals.append(body.state)
    if body.subscription_plan is not None:
        updates.append("subscription_plan = %s")
        vals.append(body.subscription_plan)
    if body.is_active is not None:
        updates.append("is_active = %s")
        vals.append(body.is_active)
    if not updates:
        return get_company(company_id, current_user)

    vals.append(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"UPDATE companies SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
            vals,
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")

    return get_company(company_id, current_user)


@router.post("/{company_id}/logo")
async def upload_company_logo(
    company_id: int,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_super_admin),
):
    """Upload company logo to Cloudinary."""
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    data = await file.read()
    if len(data) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")
    url = upload_image(data, folder="bizzpass/companies", public_id_prefix=f"logo_{company_id}")
    if not url:
        raise HTTPException(status_code=500, detail="Upload failed")
    with get_cursor() as cur:
        cur.execute(
            "UPDATE companies SET logo = %s, updated_at = NOW() WHERE id = %s RETURNING id",
            (url, company_id),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")
    return {"logo": url}


@router.delete("/{company_id}")
def delete_company(
    company_id: int,
    current_user: dict = Depends(get_current_super_admin),
):
    """Soft-deactivate a company (set is_active = false)."""
    with get_cursor() as cur:
        cur.execute(
            "UPDATE companies SET is_active = FALSE, updated_at = NOW() WHERE id = %s",
            (company_id,),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")
    return {"ok": True}
