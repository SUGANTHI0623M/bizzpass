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
    addressCity: str | None = None
    addressState: str | None = None
    contactNumber: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    attendanceRadiusM: float | None = None  # radius in meters for check-in


class UpdateBranchBody(BaseModel):
    branchName: str | None = None
    branchCode: str | None = None
    isHeadOffice: bool | None = None
    addressCity: str | None = None
    addressState: str | None = None
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
        "addressCity": row.get("address_city"),
        "addressState": row.get("address_state"),
        "contactNumber": row.get("contact_number"),
        "status": (row.get("status") or "active").lower(),
        "latitude": row.get("geofence_latitude"),
        "longitude": row.get("geofence_longitude"),
        "attendanceRadiusM": row.get("geofence_radius"),
    }


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
                   address_city, address_state, contact_number, status
            FROM branches
            WHERE company_id = %s
            ORDER BY is_head_office DESC NULLS LAST, branch_name
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
            cur.execute("SELECT COUNT(*) AS cnt FROM branches WHERE company_id = %s", (company_id,))
            current = (cur.fetchone() or {}).get("cnt") or 0
        if current >= max_branches:
            raise HTTPException(
                status_code=400,
                detail=f"Branch limit reached ({current}/{max_branches}). Delete a branch to add another, or upgrade your plan.",
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
            """
            INSERT INTO branches (branch_name, branch_code, is_head_office, company_id,
                                 address_city, address_state, contact_number, status,
                                 geofence_latitude, geofence_longitude, geofence_radius, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'active', %s, %s, %s, NOW(), NOW())
            RETURNING id, branch_name, branch_code, is_head_office, address_city, address_state, contact_number, status,
                      geofence_latitude, geofence_longitude, geofence_radius
            """,
            (
                name,
                (body.branchCode or "").strip() or None,
                body.isHeadOffice,
                company_id,
                (body.addressCity or "").strip() or None,
                (body.addressState or "").strip() or None,
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
            "SELECT id, branch_name, branch_code, is_head_office, address_city, address_state, contact_number, status FROM branches WHERE id = %s AND company_id = %s",
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
        if body.addressCity is not None:
            updates.append("address_city = %s")
            vals.append(body.addressCity.strip() or None)
        if body.addressState is not None:
            updates.append("address_state = %s")
            vals.append(body.addressState.strip() or None)
        if body.contactNumber is not None:
            updates.append("contact_number = %s")
            vals.append(body.contactNumber.strip() or None)
        if body.status is not None:
            updates.append("status = %s")
            vals.append(body.status.lower())
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


@router.delete("/{branch_id}")
def delete_branch(
    branch_id: int,
    current_user: dict = Depends(require_permission("branch.delete")),
):
    """Delete a branch. Fails if any staff is assigned to it."""
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
        cur.execute(
            "SELECT COUNT(*) AS cnt FROM staff WHERE (branch_id = %s OR branch_id = %s) AND company_id = %s",
            (str(branch_id), branch_id, company_id),
        )
        cnt = (cur.fetchone() or {}).get("cnt") or 0
        if cnt > 0:
            raise HTTPException(
                status_code=400,
                detail=f"Cannot delete: {cnt} staff assigned to this branch. Reassign them first.",
            )
        cur.execute("DELETE FROM branches WHERE id = %s AND company_id = %s", (branch_id, company_id))
    _audit_log(current_user["id"], company_id, "branch.delete", "branch", str(branch_id))
    return {"ok": True}
