"""Branches API - list, create, update, delete. Company Admin only."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission, _audit_log

router = APIRouter(prefix="/branches", tags=["branches"])


class CreateBranchBody(BaseModel):
    branchName: str
    branchCode: str | None = None
    isHeadOffice: bool = False
    addressAptBuilding: str | None = None  # apt, suite, building name
    addressStreet: str | None = None  # street address
    addressCity: str | None = None
    addressState: str | None = None
    addressZip: str | None = None
    addressCountry: str | None = None
    contactNumber: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    attendanceRadiusM: float | None = None  # radius in meters for check-in


class UpdateBranchBody(BaseModel):
    branchName: str | None = None
    branchCode: str | None = None
    isHeadOffice: bool | None = None
    addressAptBuilding: str | None = None
    addressStreet: str | None = None
    addressCity: str | None = None
    addressState: str | None = None
    addressZip: str | None = None
    addressCountry: str | None = None
    contactNumber: str | None = None
    status: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    attendanceRadiusM: float | None = None


def _branch_row(row) -> dict:
    return {
        "id": row["id"],
        "branchName": row.get("branch_name") or "",
        "branchCode": row.get("branch_code") or "",
        "isHeadOffice": bool(row.get("is_head_office")),
        "addressAptBuilding": row.get("address_apt_building"),
        "addressStreet": row.get("address_street"),
        "addressCity": row.get("address_city"),
        "addressState": row.get("address_state"),
        "addressZip": row.get("address_zip"),
        "addressCountry": row.get("address_country"),
        "contactNumber": row.get("contact_number"),
        "status": (row.get("status") or "active").lower(),
        "latitude": row.get("geofence_latitude"),
        "longitude": row.get("geofence_longitude"),
        "attendanceRadiusM": row.get("geofence_radius"),
        "createdAt": _ts_str(row.get("created_at")),
    }


def _ts_str(ts):
    """Format timestamp for API (ISO string or None)."""
    if ts is None:
        return None
    return ts.isoformat() if hasattr(ts, "isoformat") else str(ts)


@router.get("")
def list_branches(
    current_user: dict = Depends(require_permission("branch.view")),
):
    """List branches for the company."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            """
            SELECT id, branch_name, branch_code, is_head_office,
                   address_apt_building, address_street, address_city, address_state, address_zip, address_country,
                   contact_number, status,
                   geofence_latitude, geofence_longitude, geofence_radius, created_at
            FROM branches
            WHERE company_id = %s
            ORDER BY (CASE WHEN status IS NULL OR LOWER(TRIM(status)) = 'active' THEN 0 ELSE 1 END),
                     is_head_office DESC NULLS LAST, branch_name
            """,
            (company_id,),
        )
        rows = cur.fetchall()
    return {"branches": [_branch_row(r) for r in rows]}


def _validate_branch_creation(current_user: dict, company_id: int) -> None:
    """Raise HTTPException if license inactive or branch limit reached."""
    with get_cursor() as cur:
        cur.execute(
            "SELECT l.status, l.max_branches FROM licenses l WHERE l.company_id = %s LIMIT 1",
            (company_id,),
        )
        lic = cur.fetchone()
    if not lic:
        raise HTTPException(status_code=400, detail="Company license not found.")
    if (lic.get("status") or "").lower() != "active":
        raise HTTPException(status_code=400, detail="License is not active. Cannot add branches.")
    max_branches = lic.get("max_branches")
    if max_branches is not None:  # NULL = unlimited
        with get_cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s AND (status IS NULL OR LOWER(TRIM(status)) = 'active')",
                (company_id,),
            )
            current = (cur.fetchone() or {}).get("cnt") or 0
        if current >= max_branches:
            raise HTTPException(
                status_code=400,
                detail=f"Branch limit reached ({current}/{max_branches}). Deactivate a branch to add another, or upgrade your plan.",
            )


@router.post("")
def create_branch(
    body: CreateBranchBody,
    current_user: dict = Depends(require_permission("branch.create")),
):
    """Create a branch for the company. Validates license and branch limit."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    _validate_branch_creation(current_user, company_id)
    name = (body.branchName or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="Branch name is required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM branches WHERE company_id = %s AND LOWER(TRIM(branch_name)) = LOWER(%s) LIMIT 1",
            (company_id, name),
        )
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Branch name already exists.")
    if body.isHeadOffice:
        with get_cursor() as cur:
            cur.execute(
                "SELECT id FROM branches WHERE company_id = %s AND is_head_office = true LIMIT 1",
                (company_id,),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="Another branch is already set as head office. Only one branch can be the head office.",
                )
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO branches (branch_name, branch_code, is_head_office, company_id,
                                 address_apt_building, address_street, address_city, address_state, address_zip, address_country,
                                 contact_number, status,
                                 geofence_latitude, geofence_longitude, geofence_radius, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'active', %s, %s, %s, NOW(), NOW())
            RETURNING id, branch_name, branch_code, is_head_office, address_apt_building, address_street, address_city, address_state, address_zip, address_country,
                      contact_number, status, geofence_latitude, geofence_longitude, geofence_radius, created_at
            """,
            (
                name,
                (body.branchCode or "").strip() or None,
                body.isHeadOffice,
                company_id,
                (body.addressAptBuilding or "").strip() or None,
                (body.addressStreet or "").strip() or None,
                (body.addressCity or "").strip() or None,
                (body.addressState or "").strip() or None,
                (body.addressZip or "").strip() or None,
                (body.addressCountry or "").strip() or None,
                (body.contactNumber or "").strip() or None,
                body.latitude,
                body.longitude,
                body.attendanceRadiusM,
            ),
        )
        row = cur.fetchone()
    _audit_log(current_user["id"], company_id, "branch.create", "branch", str(row["id"]))
    return _branch_row(row)


@router.get("/{branch_id}")
def get_branch(
    branch_id: int,
    current_user: dict = Depends(require_permission("branch.view")),
):
    """Get a single branch."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            """SELECT id, branch_name, branch_code, is_head_office,
                      address_apt_building, address_street, address_city, address_state, address_zip, address_country,
                      contact_number, status,
                      geofence_latitude, geofence_longitude, geofence_radius, created_at
               FROM branches WHERE id = %s AND company_id = %s""",
            (branch_id, company_id),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Branch not found")
    return _branch_row(row)


@router.patch("/{branch_id}")
def update_branch(
    branch_id: int,
    body: UpdateBranchBody,
    current_user: dict = Depends(require_permission("branch.edit")),
):
    """Update a branch."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=403, detail="Company context required")
    with get_cursor() as cur:
        cur.execute(
            "SELECT id FROM branches WHERE id = %s AND company_id = %s",
            (branch_id, company_id),
        )
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Branch not found")
        if body.branchName is not None:
            name = body.branchName.strip()
            cur.execute(
                "SELECT id FROM branches WHERE company_id = %s AND LOWER(TRIM(branch_name)) = LOWER(%s) AND id != %s LIMIT 1",
                (company_id, name, branch_id),
            )
            if cur.fetchone():
                raise HTTPException(status_code=400, detail="Branch name already exists.")
        if body.isHeadOffice is True:
            cur.execute(
                "SELECT id FROM branches WHERE company_id = %s AND is_head_office = true AND id != %s LIMIT 1",
                (company_id, branch_id),
            )
            if cur.fetchone():
                raise HTTPException(
                    status_code=400,
                    detail="Another branch is already set as head office. Only one branch can be the head office.",
                )
        updates = []
        vals = []
        if body.branchName is not None:
            updates.append("branch_name = %s")
            vals.append(body.branchName.strip())
        if body.branchCode is not None:
            updates.append("branch_code = %s")
            vals.append(body.branchCode.strip() or None)
        if body.isHeadOffice is not None:
            updates.append("is_head_office = %s")
            vals.append(body.isHeadOffice)
        if body.addressAptBuilding is not None:
            updates.append("address_apt_building = %s")
            vals.append(body.addressAptBuilding.strip() or None)
        if body.addressStreet is not None:
            updates.append("address_street = %s")
            vals.append(body.addressStreet.strip() or None)
        if body.addressCity is not None:
            updates.append("address_city = %s")
            vals.append(body.addressCity.strip() or None)
        if body.addressState is not None:
            updates.append("address_state = %s")
            vals.append(body.addressState.strip() or None)
        if body.addressZip is not None:
            updates.append("address_zip = %s")
            vals.append(body.addressZip.strip() or None)
        if body.addressCountry is not None:
            updates.append("address_country = %s")
            vals.append(body.addressCountry.strip() or None)
        if body.contactNumber is not None:
            updates.append("contact_number = %s")
            vals.append(body.contactNumber.strip() or None)
        if body.status is not None:
            new_status = body.status.strip().lower()
            updates.append("status = %s")
            vals.append(new_status)
            # When deactivating the head office branch, clear head office so another can be set
            if new_status == "inactive":
                updates.append("is_head_office = false")
        if body.latitude is not None:
            updates.append("geofence_latitude = %s")
            vals.append(body.latitude)
        if body.longitude is not None:
            updates.append("geofence_longitude = %s")
            vals.append(body.longitude)
        if body.attendanceRadiusM is not None:
            updates.append("geofence_radius = %s")
            vals.append(body.attendanceRadiusM)
        if updates:
            vals.append(branch_id)
            cur.execute(
                f"UPDATE branches SET {', '.join(updates)}, updated_at = NOW() WHERE id = %s",
                vals,
            )
    _audit_log(current_user["id"], company_id, "branch.edit", "branch", str(branch_id))
    return get_branch(branch_id, current_user)


# No DELETE endpoint: use PATCH with status='inactive' to deactivate branches.
# Branches are activated/deactivated only; rows are not deleted.
