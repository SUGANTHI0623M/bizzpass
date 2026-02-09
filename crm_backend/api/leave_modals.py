"""Leave Modals API. Company-scoped CRUD for leave templates (modals)."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/leave-modals", tags=["leave-modals"])


class CreateLeaveModalBody(BaseModel):
    name: str
    description: str | None = None
    leaveTypes: list | None = None  # JSON array of leave type configs
    isActive: bool = True


class UpdateLeaveModalBody(BaseModel):
    name: str | None = None
    description: str | None = None
    leaveTypes: list | None = None
    isActive: bool | None = None


def _row_to_dict(row) -> dict:
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "description": row.get("description") or "",
        "leaveTypes": row.get("leave_types") or [],
        "isActive": bool(row.get("is_active", True)),
    }


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_leave_modals(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List leave modals. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"modals": []}
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, description, leave_types, is_active
            FROM leave_modals
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()
    return {"modals": [_row_to_dict(r) for r in rows]}


@router.post("")
def create_leave_modal(
    body: CreateLeaveModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create leave modal. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    now = datetime.utcnow()
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO leave_modals (
                company_id, name, description, leave_types, is_active, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, description, leave_types, is_active
            """,
            (
                company_id,
                name,
                (body.description or "").strip() or None,
                body.leaveTypes if body.leaveTypes is not None else [],
                body.isActive,
                now,
                now,
            ),
        )
        row = cur.fetchone()
    return _row_to_dict(row)


@router.patch("/{modal_id}")
def update_leave_modal(
    modal_id: int,
    body: UpdateLeaveModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update leave modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    updates = []
    params = []

    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.description is not None:
        updates.append("description = %s")
        params.append(body.description.strip() or None)
    if body.leaveTypes is not None:
        updates.append("leave_types = %s")
        params.append(body.leaveTypes)
    if body.isActive is not None:
        updates.append("is_active = %s")
        params.append(body.isActive)

    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    updates.append("updated_at = %s")
    params.append(datetime.utcnow())
    params.append(modal_id)
    if company_id:
        params.append(company_id)

    where = " AND company_id = %s" if company_id else ""
    with get_cursor() as cur:
        cur.execute(
            f"""
            UPDATE leave_modals
            SET {", ".join(updates)}
            WHERE id = %s{where}
            RETURNING id, name, description, leave_types, is_active
            """,
            params,
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Leave modal not found")
    return _row_to_dict(row)


@router.delete("/{modal_id}")
def delete_leave_modal(
    modal_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete leave modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM leave_modals WHERE id = %s AND company_id = %s RETURNING id",
                (modal_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM leave_modals WHERE id = %s RETURNING id",
                (modal_id,),
            )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Leave modal not found")
    return {"ok": True}
