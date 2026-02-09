"""Holiday Modals API. Company-scoped CRUD for weekly off / holiday modals."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from config.database import get_cursor
from api.auth import require_permission

router = APIRouter(prefix="/holiday-modals", tags=["holiday-modals"])


class CreateHolidayModalBody(BaseModel):
    name: str
    patternType: str  # sundays | odd_saturday | even_saturday | all_saturday | custom
    customDays: list[int] | None = None  # 0=Sun..6=Sat, for custom only


class UpdateHolidayModalBody(BaseModel):
    name: str | None = None
    patternType: str | None = None
    customDays: list[int] | None = None
    isActive: bool | None = None


def _row_to_dict(row) -> dict:
    custom = row.get("custom_days")
    if custom is not None and not isinstance(custom, list):
        import json
        try:
            custom = json.loads(custom) if isinstance(custom, str) else list(custom)
        except Exception:
            custom = []
    return {
        "id": row["id"],
        "name": row.get("name") or "",
        "patternType": row.get("pattern_type") or "sundays",
        "customDays": custom or [],
        "isActive": bool(row.get("is_active", True)),
    }


def _company_filter(company_id) -> tuple[str, list]:
    if company_id:
        return " WHERE company_id = %s", [company_id]
    return "", []


@router.get("")
def list_holiday_modals(
    current_user: dict = Depends(require_permission("settings.view")),
):
    """List holiday modals. Company Admin: own company only."""
    company_id = current_user.get("company_id")
    if not company_id:
        return {"modals": []}
    where, params = _company_filter(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            SELECT id, name, pattern_type, custom_days, is_active
            FROM holiday_modals
            {where}
            ORDER BY name
            """,
            params,
        )
        rows = cur.fetchall()
    return {"modals": [_row_to_dict(r) for r in rows]}


@router.post("")
def create_holiday_modal(
    body: CreateHolidayModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Create holiday modal. Company Admin only."""
    company_id = current_user.get("company_id")
    if not company_id:
        raise HTTPException(status_code=400, detail="Company Admin must have company_id")

    name = body.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    pattern = (body.patternType or "sundays").strip().lower()
    if pattern not in ("sundays", "odd_saturday", "even_saturday", "all_saturday", "custom"):
        pattern = "sundays"
    custom_days = body.customDays if pattern == "custom" else None
    if custom_days is None:
        custom_days = []

    import json
    now = datetime.utcnow()
    custom_json = json.dumps(custom_days)
    with get_cursor() as cur:
        cur.execute(
            """
            INSERT INTO holiday_modals (company_id, name, pattern_type, custom_days, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, pattern_type, custom_days, is_active
            """,
            (company_id, name, pattern, custom_json, True, now, now),
        )
        row = cur.fetchone()
    return _row_to_dict(row)


@router.patch("/{modal_id}")
def update_holiday_modal(
    modal_id: int,
    body: UpdateHolidayModalBody,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Update holiday modal."""
    company_id = current_user.get("company_id")
    updates = []
    params = []
    if body.name is not None:
        updates.append("name = %s")
        params.append(body.name.strip())
    if body.patternType is not None:
        p = body.patternType.strip().lower()
        if p not in ("sundays", "odd_saturday", "even_saturday", "all_saturday", "custom"):
            p = "sundays"
        updates.append("pattern_type = %s")
        params.append(p)
    if body.customDays is not None:
        import json
        updates.append("custom_days = %s")
        params.append(json.dumps(body.customDays))
    if body.isActive is not None:
        updates.append("is_active = %s")
        params.append(body.isActive)
    if not updates:
        with get_cursor() as cur:
            cur.execute(
                "SELECT id, name, pattern_type, custom_days, is_active FROM holiday_modals WHERE id = %s"
                + (" AND company_id = %s" if company_id else ""),
                (modal_id,) + ((company_id,) if company_id else ()),
            )
            row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Holiday modal not found")
        return _row_to_dict(row)
    updates.append("updated_at = %s")
    params.append(datetime.utcnow())
    params.append(modal_id)
    if company_id:
        params.append(company_id)
    with get_cursor() as cur:
        cur.execute(
            f"""
            UPDATE holiday_modals SET {", ".join(updates)}
            WHERE id = %s """ + ("AND company_id = %s" if company_id else "") + """
            RETURNING id, name, pattern_type, custom_days, is_active
            """,
            tuple(params),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Holiday modal not found")
    return _row_to_dict(row)


@router.delete("/{modal_id}")
def delete_holiday_modal(
    modal_id: int,
    current_user: dict = Depends(require_permission("settings.view")),
):
    """Delete holiday modal."""
    company_id = current_user.get("company_id")
    with get_cursor() as cur:
        if company_id:
            cur.execute(
                "DELETE FROM holiday_modals WHERE id = %s AND company_id = %s RETURNING id",
                (modal_id, company_id),
            )
        else:
            cur.execute(
                "DELETE FROM holiday_modals WHERE id = %s RETURNING id",
                (modal_id,),
            )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Holiday modal not found")
    return {"ok": True}
