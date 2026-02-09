"""Office Holidays API. Company-scoped list of office holiday dates."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/office-holidays", tags=["office-holidays"])


class CreateOfficeHolidayBody(BaseModel):
    name: str
    date: str  # YYYY-MM-DD


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


def _row_to_dict(row) -> dict:
    d = row.get("date")
    date_str = d.strftime("%Y-%m-%d") if hasattr(d, "strftime") else str(d or "")
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "date": date_str,
    }


@router.get("")
def list_office_holidays(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List office holidays. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"holidays": []}
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, date
            FROM office_holidays
            {where}
            ORDER BY date
            """,
            params,
        )
        rows = cur.fetchall()
    return {"holidays": [_row_to_dict(r) for r in rows]}


@router.post("")
def create_office_holiday(
    body: CreateOfficeHolidayBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create office holiday. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    date_str = body.date.strip()
    if not date_str:
        raise HTTPException(status_code=400, detail="Date is required")

    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO office_holidays (company_id, name, date)
            VALUES (%s, %s, %s::date)
            RETURNING id, name, date
            """,
            (company_id, name, date_str),
        )
        row = cur.fetchone()
    return _row_to_dict(row)


@router.delete("/{holiday_id}")
def delete_office_holiday(
    holiday_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete office holiday. Company Admin: must own the holiday."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM office_holidays WHERE id = %s AND company_id = %s RETURNING id",
                (holiday_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM office_holidays WHERE id = %s RETURNING id",
                (holiday_id,),
            )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Office holiday not found")
    return {"ok": True}
