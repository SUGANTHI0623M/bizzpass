"""Shift Modals API. Company-scoped CRUD for shift modals."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/shift-modals", tags=["shift-modals"])


class CreateShiftModalBody(BaseModel):
    name: str
    startTime: str  # e.g. "10:00"
    endTime: str    # e.g. "19:00"
    graceMinutes: int = 10
    graceUnit: str = "Minutes"
    isActive: bool = True


class UpdateShiftModalBody(BaseModel):
    name: str | None = None
    startTime: str | None = None
    endTime: str | None = None
    graceMinutes: int | None = None
    graceUnit: str | None = None
    isActive: bool | None = None


def _shift_row(row) -> dict:
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "startTime": row.get("start_time") or "",
        "endTime": row.get("end_time") or "",
        "graceMinutes": int(row.get("grace_minutes") or 0),
        "graceUnit": row.get("grace_unit") or "Minutes",
        "isActive": bool(row.get("is_active", True)),
    }


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_shift_modals(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List shift modals. Super Admin: all. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, start_time, end_time, grace_minutes, grace_unit, is_active
            FROM shift_modals
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()

    return {"modals": [_shift_row(r) for r in rows]}


@router.post("")
def create_shift_modal(
    body: CreateShiftModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create shift modal. Company Admin: requires company_id."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Shift name is required")

    now = datetime.utcnow()
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO shift_modals (
                company_id, name, start_time, end_time,
                grace_minutes, grace_unit, is_active, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, start_time, end_time, grace_minutes, grace_unit, is_active
            """,
            (
                company_id,
                name,
                body.startTime.strip(),
                body.endTime.strip(),
                body.graceMinutes,
                body.graceUnit or "Minutes",
                body.isActive,
                now,
                now,
            ),
        )
        row = cur.fetchone()

    return _shift_row(row)


@router.patch("/{modal_id}")
def update_shift_modal(
    modal_id: int,
    body: UpdateShiftModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update shift modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    updates = []
    params = []

    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.startTime is not None:
        updates.append("start_time = %s")
        params.append(body.startTime.strip())
    if body.endTime is not None:
        updates.append("end_time = %s")
        params.append(body.endTime.strip())
    if body.graceMinutes is not None:
        updates.append("grace_minutes = %s")
        params.append(body.graceMinutes)
    if body.graceUnit is not None:
        updates.append("grace_unit = %s")
        params.append(body.graceUnit)
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
            UPDATE shift_modals
            SET {", ".join(updates)}
            WHERE id = %s{where}
            RETURNING id, name, start_time, end_time, grace_minutes, grace_unit, is_active
            """,
            params,
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Shift modal not found")

    return _shift_row(row)


@router.delete("/{modal_id}")
def delete_shift_modal(
    modal_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete shift modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM shift_modals WHERE id = %s AND company_id = %s RETURNING id",
                (modal_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM shift_modals WHERE id = %s RETURNING id",
                (modal_id,),
            )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Shift modal not found")

    return {"ok": True}
