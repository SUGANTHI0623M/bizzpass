"""Attendance API. Super Admin sees all; Company Admin sees own company only."""
from datetime import date

from fastapi import APIRouter, Depends
from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/attendance", tags=["attendance"])


def _attendance_row(row) -> dict:
    punch_in = row.get("punch_in")
    punch_out = row.get("punch_out")
    return {
        "id": row["id"],
        "employee": row.get("employee_name") or "",
        "company": row.get("company_name") or "",
        "punchIn": punch_in.strftime("%H:%M") if punch_in and hasattr(punch_in, "strftime") else (str(punch_in)[11:16] if punch_in else None),
        "punchOut": punch_out.strftime("%H:%M") if punch_out and hasattr(punch_out, "strftime") else (str(punch_out)[11:16] if punch_out else None),
        "status": (row.get("status") or "absent").lower(),
        "workHours": float(row.get("work_hours") or 0),
        "lateMinutes": int(row.get("late_minutes") or 0),
    }


@router.get("/today")
def get_today_attendance(
    current_user: dict = Depends(require_permission("attendance.view")),
):
    """Get today's attendance. Super Admin: all. Company Admin: own company only."""
    today = date.today()
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                """
                SELECT a.id, a.punch_in, a.punch_out, a.status, a.work_hours, a.late_minutes,
                       COALESCE(s.name, 'Unknown') AS employee_name,
                       COALESCE(c.name, '') AS company_name
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                LEFT JOIN companies c ON c.id = s.company_id OR (s.business_id IS NOT NULL AND c.mongo_id = s.business_id)
                WHERE a.date = %s AND (s.company_id = %s OR c.id = %s)
                ORDER BY a.punch_in DESC NULLS LAST
                """,
                (today, company_id, company_id),
            )
        else:
            cur.execute(
                """
                SELECT a.id, a.punch_in, a.punch_out, a.status, a.work_hours, a.late_minutes,
                       COALESCE(s.name, 'Unknown') AS employee_name,
                       COALESCE(c.name, '') AS company_name
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                LEFT JOIN companies c ON c.id = s.company_id OR (s.business_id IS NOT NULL AND c.mongo_id = s.business_id)
                WHERE a.date = %s
                ORDER BY a.punch_in DESC NULLS LAST
                """,
                (today,),
            )
        rows = cur.fetchall()

    return {"attendance": [_attendance_row(r) for r in rows]}


@router.get("")
def list_attendance(
    target_date: str | None = None,
    current_user: dict = Depends(require_permission("attendance.view")),
):
    """List attendance. Super Admin: all. Company Admin: own company only."""
    d = date.today()
    if target_date:
        try:
            d = date.fromisoformat(target_date)
        except ValueError:
            pass
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                """
                SELECT a.id, a.date, a.punch_in, a.punch_out, a.status, a.work_hours, a.late_minutes,
                       COALESCE(s.name, 'Unknown') AS employee_name,
                       COALESCE(c.name, '') AS company_name
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                LEFT JOIN companies c ON c.id = s.company_id OR (s.business_id IS NOT NULL AND c.mongo_id = s.business_id)
                WHERE a.date = %s AND (s.company_id = %s OR c.id = %s)
                ORDER BY a.punch_in DESC NULLS LAST
                """,
                (d, company_id, company_id),
            )
        else:
            cur.execute(
                """
                SELECT a.id, a.date, a.punch_in, a.punch_out, a.status, a.work_hours, a.late_minutes,
                       COALESCE(s.name, 'Unknown') AS employee_name,
                       COALESCE(c.name, '') AS company_name
                FROM attendances a
                LEFT JOIN staff s ON (s.id::text = a.employee_id OR s.mongo_id = a.employee_id OR a.employee_id::text = s.employee_id)
                LEFT JOIN companies c ON c.id = s.company_id OR (s.business_id IS NOT NULL AND c.mongo_id = s.business_id)
                WHERE a.date = %s
                ORDER BY a.punch_in DESC NULLS LAST
                """,
                (d,),
            )
        rows = cur.fetchall()

    return {"attendance": [_attendance_row(r) for r in rows], "date": str(d)}
