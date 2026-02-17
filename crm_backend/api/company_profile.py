"""Company Profile API - Company Admin can view/edit own company and upload logo (Cloudinary)."""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import get_current_company_admin
from services.cloudinary_service import upload_image, delete_image  # All file uploads go to Cloudinary

router = APIRouter(prefix="/company-profile", tags=["company-profile"])


class CompanyProfileUpdate(BaseModel):
    name: str | None = None
    email: str | None = None
    phone: str | None = None
    city: str | None = None
    state: str | None = None


@router.get("")
def get_my_company_profile(
    current_user: dict = Depends(get_current_company_admin),
):
    """Get current company details and branches for the logged-in company admin."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    with get_cursor() as cur:
        cur.execute(
            """
            SELECT c.id, c.name, c.email, c.phone, c.address_city, c.address_state,
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

    with get_cursor() as cur2:
        cur2.execute(
            "SELECT l.max_users, l.max_branches FROM licenses l WHERE l.company_id = %s LIMIT 1",
            (company_id,),
        )
        lic = cur2.fetchone()
        max_staff = lic.get("max_users") if lic else None
        max_branches = lic.get("max_branches") if lic else None
        cur2.execute(
            "SELECT COUNT(*) AS cnt FROM staff WHERE company_id = %s",
            (company_id,),
        )
        staff_count = int((cur2.fetchone() or {}).get("cnt", 0) or 0)
        cur2.execute(
            "SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s",
            (company_id,),
        )
        branches_count = int((cur2.fetchone() or {}).get("cnt", 0) or 0)
        cur2.execute(
            """
            SELECT id, branch_name, branch_code, is_head_office,
                   address_city, address_state, contact_number, status
            FROM branches
            WHERE company_id = %s
            ORDER BY is_head_office DESC NULLS LAST, branch_name
            """,
            (company_id,),
        )
        branch_rows = cur2.fetchall()

    branches = [
        {
            "id": r["id"],
            "branchName": r.get("branch_name") or "",
            "branchCode": r.get("branch_code") or "",
            "isHeadOffice": bool(r.get("is_head_office")),
            "addressCity": r.get("address_city"),
            "addressState": r.get("address_state"),
            "contactNumber": r.get("contact_number"),
            "status": (r.get("status") or "active").lower(),
        }
        for r in branch_rows
    ]

    return {
        "id": row["id"],
        "name": row["name"] or "",
        "email": row["email"] or "",
        "phone": row["phone"] or "",
        "city": row.get("address_city") or "",
        "state": row.get("address_state") or "",
        "subscriptionPlan": row.get("subscription_plan") or "",
        "subscriptionStatus": row.get("subscription_status") or "active",
        "subscriptionEndDate": (row.get("subscription_end_date") or "").__str__()[:10] if row.get("subscription_end_date") else "",
        "licenseKey": row.get("license_key") or "",
        "isActive": bool(row.get("is_active", True)),
        "logo": row.get("logo"),
        "staffCount": staff_count,
        "branchesCount": branches_count,
        "maxStaff": max_staff,
        "maxBranches": max_branches,
        "branches": branches,
    }


@router.patch("")
def update_my_company_profile(
    body: CompanyProfileUpdate,
    current_user: dict = Depends(get_current_company_admin),
):
    """Update current company details (name, email, phone, city, state). Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")

    updates = []
    vals = []
    if body.name is not None:
        updates.append("name = %s")
        vals.append(body.name.strip())
    if body.email is not None:
        updates.append("email = %s")
        vals.append(body.email.strip())
    if body.phone is not None:
        updates.append("phone = %s")
        vals.append(body.phone.strip() or None)
    if body.city is not None:
        updates.append("address_city = %s")
        vals.append(body.city.strip() or None)
    if body.state is not None:
        updates.append("address_state = %s")
        vals.append(body.state.strip() or None)

    if not updates:
        return get_my_company_profile(current_user=current_user)

    vals.append(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"UPDATE companies SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
            vals,
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")

    return get_my_company_profile(current_user=current_user)


@router.post("/logo")
async def upload_my_company_logo(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_company_admin),
):
    """Upload company logo to Cloudinary. Company Admin only. Stored in bizzpass/companies."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    data = await file.read()
    if len(data) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")
    url = upload_image(data, folder="bizzpass/companies", public_id_prefix=f"logo_{company_id}")
    if not url:
        raise HTTPException(status_code=500, detail="Cloudinary upload failed")
    with get_cursor() as cur:
        cur.execute(
            "UPDATE companies SET logo = %s, updated_at = NOW() WHERE id = %s RETURNING id",
            (url, company_id),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")
    return {"logo": url}


@router.delete("/logo")
def delete_my_company_logo(
    current_user: dict = Depends(get_current_company_admin),
):
    """Remove company logo (clear in DB and delete from Cloudinary). Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute("SELECT logo FROM companies WHERE id = %s", (company_id,))
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Company not found")
    old_logo = row.get("logo")
    if old_logo:
        delete_image(old_logo)
    with get_cursor() as cur:
        cur.execute(
            "UPDATE companies SET logo = NULL, updated_at = NOW() WHERE id = %s RETURNING id",
            (company_id,),
        )
        if cur.rowcount == 0:
            raise HTTPException(status_code=404, detail="Company not found")
    return {"logo": None}
