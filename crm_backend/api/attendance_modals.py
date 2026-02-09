"""Attendance Modals API. Company-scoped CRUD for attendance modals (stored in attendance_templates)."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/attendance-modals", tags=["attendance-modals"])


class CreateAttendanceModalBody(BaseModel):
    name: str
    description: str | None = None
    isActive: bool = True
    requireGeolocation: bool = False
    requireSelfie: bool = False
    allowAttendanceOnHolidays: bool = False
    allowAttendanceOnWeeklyOff: bool = False
    allowLateEntry: bool = True
    allowEarlyExit: bool = True
    allowOvertime: bool = True


class UpdateAttendanceModalBody(BaseModel):
    name: str | None = None
    description: str | None = None
    isActive: bool | None = None
    requireGeolocation: bool | None = None
    requireSelfie: bool | None = None
    allowAttendanceOnHolidays: bool | None = None
    allowAttendanceOnWeeklyOff: bool | None = None
    allowLateEntry: bool | None = None
    allowEarlyExit: bool | None = None
    allowOvertime: bool | None = None


def _modal_row(row) -> dict:
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "description": row.get("description") or "",
        "isActive": bool(row.get("is_active")),
        "requireGeolocation": bool(row.get("require_geolocation")),
        "requireSelfie": bool(row.get("require_selfie")),
        "allowAttendanceOnHolidays": bool(row.get("allow_attendance_on_holidays")),
        "allowAttendanceOnWeeklyOff": bool(row.get("allow_attendance_on_weekly_off")),
        "allowLateEntry": bool(row.get("allow_late_entry")),
        "allowEarlyExit": bool(row.get("allow_early_exit")),
        "allowOvertime": bool(row.get("allow_overtime")),
    }


def _company_filter(company_id) -> tuple[str, list]:
    """Return (WHERE clause, params) for company scoping."""
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_attendance_modals(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List attendance modals. Super Admin: all. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, description, is_active,
                   require_geolocation, require_selfie,
                   allow_attendance_on_holidays, allow_attendance_on_weekly_off,
                   allow_late_entry, allow_early_exit, allow_overtime
            FROM attendance_templates
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()

    return {"modals": [_modal_row(r) for r in rows]}


@router.post("")
def create_attendance_modal(
    body: CreateAttendanceModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create attendance modal. Company Admin: requires company_id."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    now = datetime.utcnow()
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO attendance_templates (
                company_id, name, description, is_active,
                require_geolocation, require_selfie,
                allow_attendance_on_holidays, allow_attendance_on_weekly_off,
                allow_late_entry, allow_early_exit, allow_overtime,
                created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, description, is_active,
                      require_geolocation, require_selfie,
                      allow_attendance_on_holidays, allow_attendance_on_weekly_off,
                      allow_late_entry, allow_early_exit, allow_overtime
            """,
            (
                company_id,
                body.name.strip(),
                body.description or None,
                body.isActive,
                body.requireGeolocation,
                body.requireSelfie,
                body.allowAttendanceOnHolidays,
                body.allowAttendanceOnWeeklyOff,
                body.allowLateEntry,
                body.allowEarlyExit,
                body.allowOvertime,
                now,
                now,
            ),
        )
        row = cur.fetchone()

    return _modal_row(row)


@router.patch("/{modal_id}")
def update_attendance_modal(
    modal_id: int,
    body: UpdateAttendanceModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update attendance modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    updates = []
    params = []

    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.description is not None:
        updates.append("description = %s")
        params.append(body.description or None)
    if body.isActive is not None:
        updates.append("is_active = %s")
        params.append(body.isActive)
    if body.requireGeolocation is not None:
        updates.append("require_geolocation = %s")
        params.append(body.requireGeolocation)
    if body.requireSelfie is not None:
        updates.append("require_selfie = %s")
        params.append(body.requireSelfie)
    if body.allowAttendanceOnHolidays is not None:
        updates.append("allow_attendance_on_holidays = %s")
        params.append(body.allowAttendanceOnHolidays)
    if body.allowAttendanceOnWeeklyOff is not None:
        updates.append("allow_attendance_on_weekly_off = %s")
        params.append(body.allowAttendanceOnWeeklyOff)
    if body.allowLateEntry is not None:
        updates.append("allow_late_entry = %s")
        params.append(body.allowLateEntry)
    if body.allowEarlyExit is not None:
        updates.append("allow_early_exit = %s")
        params.append(body.allowEarlyExit)
    if body.allowOvertime is not None:
        updates.append("allow_overtime = %s")
        params.append(body.allowOvertime)

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
            UPDATE attendance_templates
            SET {", ".join(updates)}
            WHERE id = %s{where}
            RETURNING id, name, description, is_active,
                      require_geolocation, require_selfie,
                      allow_attendance_on_holidays, allow_attendance_on_weekly_off,
                      allow_late_entry, allow_early_exit, allow_overtime
            """,
            params,
        )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Attendance modal not found")

    return _modal_row(row)


@router.delete("/{modal_id}")
def delete_attendance_modal(
    modal_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete attendance modal. Company Admin: must own the modal."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM attendance_templates WHERE id = %s AND company_id = %s RETURNING id",
                (modal_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM attendance_templates WHERE id = %s RETURNING id",
                (modal_id,),
            )
        row = cur.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Attendance modal not found")

    return {"ok": True}
